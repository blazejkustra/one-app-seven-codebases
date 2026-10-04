/**
 * Tag parsing (iteration 2). A tag is `#` + letter + [letters, digits, `-`, `_`]*
 * at the start of a line or after whitespace. Inline code and code fences never
 * contain tags; the title line never contributes tags.
 */

/** Matches a tag together with its leading boundary (start or whitespace). */
const TAG_RE = /(^|\s)#([A-Za-z][A-Za-z0-9_-]*)/g;

export interface Segment {
  text: string;
  tag: boolean;
}

/**
 * Split a run of plain text (no code) into text/tag segments.
 * `atLineStart` says whether the run begins at a boundary (line start / after whitespace).
 */
export function splitTags(text: string, atLineStart = true): Segment[] {
  const out: Segment[] = [];
  let last = 0;
  TAG_RE.lastIndex = 0;
  let m: RegExpExecArray | null;
  while ((m = TAG_RE.exec(text)) !== null) {
    const lead = m[1] ?? '';
    const start = m.index + lead.length;
    if (m.index === 0 && lead === '' && !atLineStart) continue;
    if (start > last) out.push({ text: text.slice(last, start), tag: false });
    out.push({ text: `#${m[2]}`, tag: true });
    last = start + 1 + (m[2]?.length ?? 0);
    TAG_RE.lastIndex = last;
  }
  if (last < text.length) out.push({ text: text.slice(last), tag: false });
  return out;
}

/** Split a line into code / non-code parts by inline backtick spans. */
function nonCodeParts(line: string): { text: string; code: boolean }[] {
  const parts: { text: string; code: boolean }[] = [];
  const re = /(`+)([\s\S]*?)\1/g;
  let last = 0;
  let m: RegExpExecArray | null;
  while ((m = re.exec(line)) !== null) {
    if (m.index > last) parts.push({ text: line.slice(last, m.index), code: false });
    parts.push({ text: m[0], code: true });
    last = m.index + m[0].length;
  }
  if (last < line.length) parts.push({ text: line.slice(last), code: false });
  return parts;
}

function isFence(line: string): boolean {
  return line.trim().startsWith('```');
}

/** Lower-cased, de-duplicated tags of a note, in order of appearance. */
export function noteTags(body: string): string[] {
  const lines = body.split('\n').slice(1);
  const seen: string[] = [];
  let inFence = false;
  for (const line of lines) {
    if (isFence(line)) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    nonCodeParts(line).forEach((part, i) => {
      if (part.code) return;
      // A part that follows inline code does not start at a line boundary.
      for (const seg of splitTags(part.text, i === 0)) {
        if (!seg.tag) continue;
        const tag = seg.text.slice(1).toLowerCase();
        if (!seen.includes(tag)) seen.push(tag);
      }
    });
  }
  return seen;
}

/** Remove tags from a (non-fence) line, leaving inline code untouched. */
export function stripTags(line: string): string {
  return nonCodeParts(line)
    .map((p, i) =>
      p.code
        ? p.text
        : splitTags(p.text, i === 0)
            .filter((s) => !s.tag)
            .map((s) => s.text)
            .join(''),
    )
    .join('');
}

/** All tags across notes, A→Z. */
export function allTags(tagLists: string[][]): string[] {
  const set: string[] = [];
  for (const list of tagLists) for (const t of list) if (!set.includes(t)) set.push(t);
  return set.sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
}
