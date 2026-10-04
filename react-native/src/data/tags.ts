/** `#` + letter, then letters/digits/`-`/`_`, at line start or after whitespace. */
const TAG_RE = /(^|\s)#([A-Za-z][A-Za-z0-9_-]*)/g;

/** Splits `text` into plain and tag segments (no code-awareness; callers pass non-code text). */
export function splitTags(text: string): { text: string; tag: boolean }[] {
  const out: { text: string; tag: boolean }[] = [];
  let last = 0;
  for (const m of text.matchAll(TAG_RE)) {
    const start = (m.index ?? 0) + m[1].length;
    if (start > last) out.push({ text: text.slice(last, start), tag: false });
    out.push({ text: `#${m[2]}`, tag: true });
    last = start + m[2].length + 1;
  }
  if (last < text.length) out.push({ text: text.slice(last), tag: false });
  return out;
}

/** Removes tags from a single line of text. */
export function stripTags(line: string): string {
  return line.replace(TAG_RE, '$1');
}

/** Lower-cased, de-duplicated tags of a note body (title line, code fences and inline code excluded). */
export function extractTags(body: string): string[] {
  const tags: string[] = [];
  let inFence = false;
  body
    .split('\n')
    .slice(1)
    .forEach((line) => {
      if (line.trim().startsWith('```')) {
        inFence = !inFence;
        return;
      }
      if (inFence) return;
      const noCode = line.replace(/`[^`]*`/g, ' ');
      for (const m of noCode.matchAll(TAG_RE)) {
        const t = m[2].toLowerCase();
        if (!tags.includes(t)) tags.push(t);
      }
    });
  return tags;
}

export function allTags(bodies: string[]): string[] {
  const set = new Set<string>();
  bodies.forEach((b) => extractTags(b).forEach((t) => set.add(t)));
  return [...set].sort();
}
