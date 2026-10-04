import { stripTags } from './tags.js';
import type { Note, SortMode } from './types.js';

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/** First line of the body with leading `#` characters and spaces removed. */
export function noteTitle(body: string): string {
  const first = body.split('\n')[0] ?? '';
  const title = first.replace(/^[#\s]+/, '').trim();
  return title === '' ? 'Untitled' : title;
}

/** Plain-text preview of every line after the first (spec §2). */
export function noteSnippet(body: string): string {
  const lines = body.split('\n').slice(1);
  const out: string[] = [];
  let inFence = false;
  for (const raw of lines) {
    let line = raw.trim();
    if (line.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    const isListItem = /^(- |\* |\d+\. )/.test(line);
    line = line.replace(/^(#+\s+|- |\* |> |\d+\. )/, '');
    if (isListItem) line = line.replace(/^\[[ xX]\] /, '');
    if (!inFence) line = stripTags(line);
    line = line.replace(/\*\*/g, '').replace(/\*/g, '').replace(/`/g, '');
    line = line.replace(/\s+/g, ' ').trim();
    if (line !== '') out.push(line);
  }
  return out.join(' ');
}

/** `MMM d, yyyy` in en-US (hand-rolled: the JS engine has no Intl). */
export function dateLabel(ms: number): string {
  const d = new Date(ms);
  return `${MONTHS[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`;
}

export function sortNotes(notes: Note[], mode: SortMode): Note[] {
  const copy = notes.slice();
  if (mode === 'title') {
    copy.sort((a, b) => {
      const ta = noteTitle(a.body).toLowerCase();
      const tb = noteTitle(b.body).toLowerCase();
      if (ta < tb) return -1;
      if (ta > tb) return 1;
      return b.updatedAt - a.updatedAt;
    });
  } else {
    copy.sort((a, b) => b.updatedAt - a.updatedAt);
  }
  return copy;
}

export function matchesSearch(note: Note, query: string): boolean {
  const q = query.toLowerCase();
  return q === '' || note.body.toLowerCase().includes(q);
}

export function newNoteId(): string {
  return `n${Date.now().toString(36)}${Math.floor(Math.random() * 1e6).toString(36)}`;
}
