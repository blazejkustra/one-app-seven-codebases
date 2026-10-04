/** A single note. `body` is raw markdown; `updatedAt` is epoch milliseconds. */
export interface Note {
  readonly id: string;
  readonly body: string;
  readonly starred: boolean;
  readonly updatedAt: number;
}

export type SortOrder = 'updated' | 'title';
export type Appearance = 'system' | 'light' | 'dark';

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/** First line of the body without its leading `#` run and spaces; `Untitled` when empty. */
export function noteTitle(body: string): string {
  const first = body.split('\n', 1)[0] ?? '';
  const title = first.replace(/^[#\s]+/, '').trim();
  return title.length > 0 ? title : 'Untitled';
}

const FENCE = '`'.repeat(3);
const TICK = '`';

/** `#tag` at the start of a line or after whitespace: a letter, then letters, digits, `-`, `_`. */
const TAG_RE = /(^|\s)#([A-Za-z][A-Za-z0-9_-]*)/g;

/** Splits a line into alternating [text, code, text, ...] around inline code spans. */
function splitInlineCode(line: string): string[] {
  return line.split(new RegExp('(' + TICK + '[^' + TICK + ']*' + TICK + ')'));
}

/** Lines after the title, each flagged with whether it is inside (or is) a code fence. */
function bodyLines(body: string): { text: string; fenced: boolean; fence: boolean }[] {
  let inFence = false;
  return body
    .split('\n')
    .slice(1)
    .map((raw) => {
      const text = raw.trim();
      if (text.startsWith(FENCE)) {
        inFence = !inFence;
        return { text, fenced: true, fence: true };
      }
      return { text, fenced: inFence, fence: false };
    });
}

/** Tags in a note (lower-cased, de-duplicated, in order of appearance); the title never counts. */
export function noteTags(body: string): string[] {
  const tags: string[] = [];
  for (const line of bodyLines(body)) {
    if (line.fenced) continue;
    splitInlineCode(line.text).forEach((part, i) => {
      if (i % 2 === 1) return;
      for (const match of part.matchAll(TAG_RE)) {
        const tag = match[2].toLowerCase();
        if (!tags.includes(tag)) tags.push(tag);
      }
    });
  }
  return tags;
}

/** Removes tags from a line, leaving inline code spans untouched. */
function stripTags(line: string): string {
  return splitInlineCode(line)
    .map((part, i) => (i % 2 === 1 ? part : part.replace(TAG_RE, '$1')))
    .join('')
    .replace(/\s+/g, ' ')
    .trim();
}

/** Every line after the first, stripped of markdown markers and tags, joined with single spaces. */
export function noteSnippet(body: string): string {
  return bodyLines(body)
    .filter((line) => !line.fence)
    .map((line) => (line.fenced ? line.text : stripTags(line.text)))
    .map((line) =>
      line
        .replace(/^(#+\s+|[-*>]\s|\d+\.\s)/, '')
        .replace(/^\[[ xX]\]\s/, '')
        .replace(/\*\*/g, '')
        .replace(/[*`]/g, '')
        .trim(),
    )
    .filter((line) => line.length > 0)
    .join(' ');
}

/** `MMM d, yyyy` in en-US, e.g. `Oct 1, 2026`. */
export function formatDate(timestamp: number): string {
  const d = new Date(timestamp);
  return `${MONTHS[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`;
}

export function sortNotes(notes: readonly Note[], order: SortOrder): Note[] {
  const copy = [...notes];
  if (order === 'title') {
    copy.sort((a, b) => {
      const ta = noteTitle(a.body).toLowerCase();
      const tb = noteTitle(b.body).toLowerCase();
      return ta < tb ? -1 : ta > tb ? 1 : b.updatedAt - a.updatedAt;
    });
  } else {
    copy.sort((a, b) => b.updatedAt - a.updatedAt);
  }
  return copy;
}

export function matchesQuery(note: Note, query: string): boolean {
  const q = query.toLowerCase();
  return q.length === 0 || note.body.toLowerCase().includes(q);
}

export function hasTag(note: Note, tag: string | null): boolean {
  return tag === null || noteTags(note.body).includes(tag);
}

const TASK_RE = /^(\s*[-*]\s+\[)([ xX])(\])(\s|$)/;

/** Body line numbers of task items (`- [ ]` / `* [x]`) outside code fences, in document order. */
function taskLines(lines: string[]): number[] {
  const found: number[] = [];
  let inFence = false;
  lines.forEach((line, i) => {
    if (line.trim().startsWith(FENCE)) inFence = !inFence;
    else if (!inFence && TASK_RE.test(line)) found.push(i);
  });
  return found;
}

/** Counts of completed and total tasks. */
export function taskProgress(body: string): { done: number; total: number } {
  const lines = body.split('\n');
  const indices = taskLines(lines);
  const done = indices.filter((i) => TASK_RE.exec(lines[i])![2] !== ' ').length;
  return { done, total: indices.length };
}

/** Returns the body with the n-th task's `[ ]` and `[x]` swapped. */
export function toggleTask(body: string, n: number): string {
  const lines = body.split('\n');
  const i = taskLines(lines)[n];
  if (i === undefined) return body;
  lines[i] = lines[i].replace(TASK_RE, (_m, a: string, mark: string, c: string, d: string) => a + (mark === ' ' ? 'x' : ' ') + c + d);
  return lines.join('\n');
}
