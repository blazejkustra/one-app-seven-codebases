import type { ReactNode } from '@lynx-js/react';
/**
 * Renders Markdown (parsed with `marked`'s lexer) into Lynx elements
 * following the typography rules in spec §4.
 */
import { marked } from 'marked';
import type { Token, Tokens } from 'marked';

import { splitTags } from '../data/tags.js';
import { a11y, colors, MONO } from '../theme.js';

const BASE_STYLE = { fontSize: '17px', lineHeight: '24px' } as const;
/** Base text style; a getter so it always uses the active theme. */
const BASE = {
  ...BASE_STYLE,
  get color() {
    return colors.text;
  },
};

interface BlockSpacing {
  top: number;
  bottom: number;
}

function spacingFor(token: Token): BlockSpacing {
  if (token.type === 'heading') {
    const depth = (token as Tokens.Heading).depth;
    if (depth === 1) return { top: 0, bottom: 12 };
    if (depth === 2) return { top: 16, bottom: 8 };
    return { top: 12, bottom: 6 };
  }
  return { top: 0, bottom: 12 };
}

/* ---------- inline ---------- */

let tagsEnabled = true;

/** Plain text with tags highlighted (accent, medium). */
function textWithTags(text: string, key: string, atStart: boolean): ReactNode {
  if (!tagsEnabled) return <text key={key}>{text}</text>;
  const segs = splitTags(text, atStart);
  if (segs.length === 1 && !segs[0]!.tag) return <text key={key}>{text}</text>;
  return (
    <text key={key}>
      {segs.map((sg, j) =>
        sg.tag ? (
          <text key={`${key}-t${j}`} style={{ color: colors.accent, fontWeight: '500' }}>
            {sg.text}
          </text>
        ) : (
          <text key={`${key}-t${j}`}>{sg.text}</text>
        ),
      )}
    </text>
  );
}

function renderInline(tokens: Token[] | undefined, key: string, atStart = true): ReactNode[] {
  if (!tokens) return [];
  const out: ReactNode[] = [];
  tokens.forEach((t, i) => {
    const k = `${key}-${i}`;
    const prev = i > 0 ? tokens[i - 1] : undefined;
    const boundary = prev ? /\s$/.test(prev.raw) : atStart;
    switch (t.type) {
      case 'strong':
        out.push(
          <text key={k} style={{ fontWeight: 'bold' }}>
            {renderInline((t as Tokens.Strong).tokens, k)}
          </text>,
        );
        break;
      case 'em':
        out.push(
          <text key={k} style={{ fontStyle: 'italic' }}>
            {renderInline((t as Tokens.Em).tokens, k)}
          </text>,
        );
        break;
      case 'del':
        out.push(
          <text key={k} style={{ textDecoration: 'line-through' }}>
            {renderInline((t as Tokens.Del).tokens, k)}
          </text>,
        );
        break;
      case 'codespan':
        out.push(
          <text
            key={k}
            style={{
              fontFamily: MONO,
              fontSize: '15px',
              color: colors.accent,
              backgroundColor: colors.accentSoft,
            }}
          >
            {` ${decode((t as Tokens.Codespan).text)} `}
          </text>,
        );
        break;
      case 'br':
        out.push(<text key={k}>{'\n'}</text>);
        break;
      case 'link':
      case 'image':
        out.push(<text key={k}>{renderInline((t as Tokens.Link).tokens, k)}</text>);
        break;
      case 'text': {
        const tt = t as Tokens.Text;
        if (tt.tokens && tt.tokens.length > 0) {
          out.push(<text key={k}>{renderInline(tt.tokens, k, boundary)}</text>);
        } else {
          out.push(textWithTags(softBreaks(decode(tt.text)), k, boundary));
        }
        break;
      }
      case 'escape':
        out.push(<text key={k}>{decode((t as Tokens.Escape).text)}</text>);
        break;
      default:
        out.push(<text key={k}>{softBreaks(decode((t as { text?: string }).text ?? t.raw))}</text>);
    }
  });
  return out;
}

/** Consecutive non-blank lines join into one paragraph (soft breaks become spaces). */
function softBreaks(s: string): string {
  return s.replace(/\n/g, ' ');
}

function decode(s: string): string {
  return s
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&amp;/g, '&');
}

/* ---------- blocks ---------- */

/** Per-render context for interactive tasks (rendering is synchronous). */
let taskCounter = 0;
let onTaskToggle: ((index: number) => void) | undefined;

function renderTask(item: Tokens.ListItem, key: string, marginTop: number): ReactNode {
  const index = taskCounter++;
  const checked = !!item.checked;
  const toggle = onTaskToggle;
  return (
    <view
      key={key}
      {...a11y(`task-${index}`, item.text, {
        'accessibility-value': checked ? 'checked' : 'unchecked',
        'accessibility-traits': checked ? 'button,selected' : 'button',
      })}
      style={{ display: 'flex', flexDirection: 'row', alignItems: 'center', marginTop: `${marginTop}px` }}
      bindtap={() => toggle?.(index)}
    >
      <view
        style={{
          width: '22px',
          height: '22px',
          borderRadius: '6px',
          marginRight: '10px',
          flexShrink: 0,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          ...(checked
            ? { backgroundColor: colors.accent }
            : { borderWidth: '2px', borderStyle: 'solid', borderColor: colors.textTertiary }),
        }}
      >
        {checked ? <text style={{ fontSize: '14px', fontWeight: 'bold', color: '#FFFFFF' }}>{'\u2713'}</text> : null}
      </view>
      <text
        style={{
          ...BASE,
          flexGrow: 1,
          flexShrink: 1,
          flexBasis: '0px',
          ...(checked ? { color: colors.textTertiary, textDecoration: 'line-through' } : {}),
        }}
      >
        {renderInline(listItemInline(item), key)}
      </text>
    </view>
  );
}

function listItemInline(item: Tokens.ListItem): Token[] {
  // Tight list items contain `text` tokens; loose ones contain paragraphs.
  const inline: Token[] = [];
  item.tokens.forEach((t) => {
    if (t.type === 'text' || t.type === 'paragraph') {
      const tt = t as Tokens.Text | Tokens.Paragraph;
      if (inline.length > 0) inline.push({ type: 'text', raw: ' ', text: ' ' } as Tokens.Text);
      inline.push(...(tt.tokens ?? [{ type: 'text', raw: tt.text, text: tt.text } as Tokens.Text]));
    }
  });
  return inline;
}

function renderBlock(token: Token, key: string, marginTop: number, marginBottom: number): ReactNode | null {
  const box = { marginTop: `${marginTop}px`, marginBottom: `${marginBottom}px` };
  switch (token.type) {
    case 'heading': {
      const h = token as Tokens.Heading;
      const style =
        h.depth === 1
          ? ({ fontSize: '28px', lineHeight: '34px', fontWeight: 'bold' } as const)
          : h.depth === 2
            ? ({ fontSize: '22px', lineHeight: '28px', fontWeight: 'bold' } as const)
            : ({ fontSize: '18px', lineHeight: '24px', fontWeight: '600' } as const);
      return (
        <text key={key} style={{ ...BASE, ...style, ...box }}>
          {renderInline(h.tokens, key)}
        </text>
      );
    }
    case 'paragraph':
      return (
        <text key={key} style={{ ...BASE, ...box }}>
          {renderInline((token as Tokens.Paragraph).tokens, key)}
        </text>
      );
    case 'text':
      return (
        <text key={key} style={{ ...BASE, ...box }}>
          {renderInline((token as Tokens.Text).tokens ?? [token], key)}
        </text>
      );
    case 'list': {
      const list = token as Tokens.List;
      const start = typeof list.start === 'number' ? list.start : 1;
      return (
        <view key={key} style={{ display: 'flex', flexDirection: 'column', ...box }}>
          {list.items.map((item, i) => {
            const isTask = item.task && !list.ordered && /^\s*[-*]/.test(item.raw);
            if (isTask) {
              const prevTask = i > 0 && list.items[i - 1]!.task;
              return renderTask(item, `${key}-${i}`, i === 0 ? 0 : prevTask ? 8 : 4);
            }
            return (
              <view
                key={`${key}-${i}`}
                style={{ display: 'flex', flexDirection: 'row', marginTop: i === 0 ? '0px' : list.items[i - 1]!.task ? '8px' : '4px' }}
              >
                <text style={{ ...BASE, marginRight: '8px' }}>{list.ordered ? `${start + i}.` : '\u2022'}</text>
                <text style={{ ...BASE, flexGrow: 1, flexShrink: 1, flexBasis: '0px' }}>{renderInline(listItemInline(item), `${key}-${i}`)}</text>
              </view>
            );
          })}
        </view>
      );
    }
    case 'blockquote': {
      const q = token as Tokens.Blockquote;
      const inner: Token[] = [];
      q.tokens.forEach((t) => {
        if (t.type === 'paragraph' || t.type === 'text') {
          if (inner.length > 0) inner.push({ type: 'br', raw: '\n' } as Tokens.Br);
          inner.push(...((t as Tokens.Paragraph).tokens ?? []));
        }
      });
      return (
        <view key={key} style={{ display: 'flex', flexDirection: 'row', ...box }}>
          <view style={{ width: '3px', backgroundColor: colors.accent, marginRight: '12px' }} />
          <text style={{ ...BASE, flexGrow: 1, flexShrink: 1, flexBasis: '0px', fontStyle: 'italic', color: colors.textSecondary }}>
            {renderInline(inner, key)}
          </text>
        </view>
      );
    }
    case 'code': {
      const c = token as Tokens.Code;
      return (
        <view key={key} style={{ backgroundColor: colors.codeBg, borderRadius: '10px', padding: '12px', ...box }}>
          <text style={{ fontFamily: MONO, fontSize: '14px', lineHeight: '20px', color: colors.codeText }}>
            {c.text}
          </text>
        </view>
      );
    }
    case 'hr':
      return <view key={key} style={{ height: '1px', backgroundColor: colors.separator, ...box }} />;
    case 'space':
    case 'def':
      return null;
    default: {
      const raw = (token as { text?: string }).text ?? token.raw;
      return (
        <text key={key} style={{ ...BASE, ...box }}>
          {raw.trim()}
        </text>
      );
    }
  }
}

/**
 * Tokenise with marked. Runs on the background thread only: the editor is never
 * part of the first (main-thread) render, and keeping marked out of the
 * main-thread bundle avoids its regexes in the main-thread engine.
 */
function lex(source: string): Token[] {
  'background only';
  return marked.lexer(source, { gfm: true });
}

export function Markdown({ source, onToggleTask }: { source: string; onToggleTask?: (index: number) => void }) {
  taskCounter = 0;
  onTaskToggle = onToggleTask;
  const tokens = lex(source) ?? [];
  const blocks: ReactNode[] = [];
  let prevBottom = 0;
  tokens.forEach((token, i) => {
    if (token.type === 'space' || token.type === 'def') return;
    // The title line never contributes tags.
    tagsEnabled = !(i === 0 && token.type === 'heading');
    const { top, bottom } = spacingFor(token);
    // Emulate CSS margin collapsing between adjacent blocks.
    const marginTop = blocks.length === 0 ? 0 : Math.max(0, top - prevBottom);
    const el = renderBlock(token, `b${i}`, marginTop, bottom);
    if (el) {
      blocks.push(el);
      prevBottom = bottom;
    }
  });
  tagsEnabled = true;
  return <view style={{ display: 'flex', flexDirection: 'column' }}>{blocks}</view>;
}
