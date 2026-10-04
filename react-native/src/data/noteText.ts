import { stripTags } from './tags';
import type { Note, SortOrder } from './types';

export function noteTitle(body: string): string {
  const first = body.split('\n')[0] ?? '';
  const title = first.replace(/^[#\s]+/, '').trim();
  return title.length > 0 ? title : 'Untitled';
}

export function noteSnippet(body: string): string {
  let inFence = false;
  const out: string[] = [];
  for (const raw of body.split('\n').slice(1)) {
    const line = raw.trim();
    if (line.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    let l = line.replace(/^(#+\s+|[-*] \[[ xX]\] |- |\* |> |\d+\. )/, '');
    if (!inFence) {
      // Strip tags outside inline code spans only.
      l = l
        .split(/(`[^`]*`)/)
        .map((part) => (part.startsWith('`') ? part : stripTags(part)))
        .join('');
    }
    l = l.replace(/\*\*/g, '').replace(/[*`]/g, '').replace(/\s+/g, ' ').trim();
    if (l.length > 0) out.push(l);
  }
  return out.join(' ');
}

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

export function dateLabel(ms: number): string {
  const d = new Date(ms);
  return `${MONTHS[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`;
}

export function sortNotes(notes: Note[], order: SortOrder): Note[] {
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

export function matchesSearch(note: Note, query: string): boolean {
  if (!query) return true;
  return note.body.toLowerCase().includes(query.toLowerCase());
}
