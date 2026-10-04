import { marked, type Token, type Tokens } from 'marked';

/** A run of inline text with uniform styling. */
export interface InlineRun {
  readonly text: string;
  readonly bold: boolean;
  readonly italic: boolean;
  readonly code: boolean;
  readonly tag: boolean;
}

export type Block =
  | { readonly kind: 'heading'; readonly level: 1 | 2 | 3; readonly runs: InlineRun[] }
  | { readonly kind: 'paragraph'; readonly runs: InlineRun[] }
  | { readonly kind: 'list'; readonly ordered: boolean; readonly items: { marker: string; runs: InlineRun[] }[] }
  | { readonly kind: 'tasks'; readonly items: { index: number; checked: boolean; label: string; runs: InlineRun[] }[] }
  | { readonly kind: 'quote'; readonly runs: InlineRun[] }
  | { readonly kind: 'code'; readonly text: string };

interface Style {
  bold: boolean;
  italic: boolean;
}

const TAG_RE = /(^|\s)(#[A-Za-z][A-Za-z0-9_-]*)/g;

/** Plain text, split so `#tags` become their own runs. */
function textRuns(text: string, style: Style, out: InlineRun[]): void {
  let last = 0;
  for (const match of text.matchAll(TAG_RE)) {
    const start = (match.index ?? 0) + match[1].length;
    if (start > last) out.push({ text: text.slice(last, start), ...style, code: false, tag: false });
    out.push({ text: match[2], ...style, code: false, tag: true });
    last = start + match[2].length;
  }
  if (last < text.length) out.push({ text: text.slice(last), ...style, code: false, tag: false });
}

/** Flattens marked's nested inline tokens into styled runs that can be nested `<text>`s. */
function inline(tokens: readonly Token[] | undefined, style: Style, out: InlineRun[] = []): InlineRun[] {
  for (const token of tokens ?? []) {
    switch (token.type) {
      case 'strong':
        inline((token as Tokens.Strong).tokens, { ...style, bold: true }, out);
        break;
      case 'em':
        inline((token as Tokens.Em).tokens, { ...style, italic: true }, out);
        break;
      case 'del':
      case 'link':
        inline((token as Tokens.Link).tokens, style, out);
        break;
      case 'codespan':
        out.push({ text: (token as Tokens.Codespan).text, ...style, code: true, tag: false });
        break;
      case 'br':
        out.push({ text: '\n', ...style, code: false, tag: false });
        break;
      case 'text': {
        const t = token as Tokens.Text;
        if (t.tokens && t.tokens.length > 0) inline(t.tokens, style, out);
        else textRuns(t.text.replace(/\n/g, ' '), style, out);
        break;
      }
      case 'paragraph':
        if (out.length > 0) out.push({ text: '\n', ...style, code: false, tag: false });
        inline((token as Tokens.Paragraph).tokens, style, out);
        break;
      default:
        if ('text' in token && typeof token.text === 'string') textRuns(token.text, style, out);
    }
  }
  return out;
}

const PLAIN: Style = { bold: false, italic: false };

/** Parses markdown with `marked` and maps the supported subset to renderable blocks. */
export function parseMarkdown(source: string): Block[] {
  const blocks: Block[] = [];
  let taskIndex = 0;
  for (const token of marked.lexer(source)) {
    switch (token.type) {
      case 'heading': {
        const h = token as Tokens.Heading;
        const level = (h.depth <= 1 ? 1 : h.depth === 2 ? 2 : 3) as 1 | 2 | 3;
        blocks.push({ kind: 'heading', level, runs: inline(h.tokens, PLAIN) });
        break;
      }
      case 'paragraph':
        blocks.push({ kind: 'paragraph', runs: inline((token as Tokens.Paragraph).tokens, PLAIN) });
        break;
      case 'list': {
        const list = token as Tokens.List;
        const start = typeof list.start === 'number' ? list.start : 1;
        // Unordered task items (- [ ] / * [x]) become checklist groups; runs of plain items stay a list.
        let plain: { marker: string; runs: InlineRun[] }[] = [];
        let tasks: { index: number; checked: boolean; label: string; runs: InlineRun[] }[] = [];
        const flush = () => {
          if (plain.length > 0) blocks.push({ kind: 'list', ordered: list.ordered, items: plain });
          if (tasks.length > 0) blocks.push({ kind: 'tasks', items: tasks });
          plain = [];
          tasks = [];
        };
        list.items.forEach((item, i) => {
          if (!list.ordered && item.task) {
            if (plain.length > 0) flush();
            const runs = inline(item.tokens, PLAIN);
            tasks.push({ index: taskIndex++, checked: !!item.checked, label: runs.map((r) => r.text).join(''), runs });
          } else {
            if (tasks.length > 0) flush();
            plain.push({ marker: list.ordered ? `${start + i}.` : '•', runs: inline(item.tokens, PLAIN) });
          }
        });
        flush();
        break;
      }
      case 'blockquote':
        blocks.push({ kind: 'quote', runs: inline((token as Tokens.Blockquote).tokens, PLAIN) });
        break;
      case 'code':
        blocks.push({ kind: 'code', text: (token as Tokens.Code).text });
        break;
      case 'space':
      case 'hr':
      case 'html':
      case 'def':
        break;
      default:
        if ('text' in token && typeof token.text === 'string') {
          blocks.push({ kind: 'paragraph', runs: [{ text: token.text, ...PLAIN, code: false, tag: false }] });
        }
    }
  }
  return blocks;
}
