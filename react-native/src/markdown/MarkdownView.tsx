import React from 'react';
import { Platform, Pressable, Text, View, type TextStyle } from 'react-native';
import { makeStyles, mono } from '../theme';
import { splitTags } from '../data/tags';
import { parseMarkdown, type Token, type Tokens } from './parse';

type Spacing = { top: number; bottom: number };

const SPACING: Record<string, Spacing> = {
  h1: { top: 0, bottom: 12 },
  h2: { top: 16, bottom: 8 },
  h3: { top: 12, bottom: 6 },
  paragraph: { top: 0, bottom: 12 },
  list: { top: 0, bottom: 12 },
  blockquote: { top: 0, bottom: 12 },
  code: { top: 0, bottom: 12 },
};

function blockKind(t: Token): string | null {
  switch (t.type) {
    case 'heading':
      return (t as Tokens.Heading).depth === 1 ? 'h1' : (t as Tokens.Heading).depth === 2 ? 'h2' : 'h3';
    case 'paragraph':
    case 'text':
    case 'list':
    case 'blockquote':
    case 'code':
      return t.type === 'text' ? 'paragraph' : t.type;
    default:
      return null;
  }
}

function renderInline(styles: Styles, tokens: Token[] | undefined, key = 'i'): React.ReactNode[] {
  if (!tokens) return [];
  return tokens.map((t, i) => {
    const k = `${key}-${i}`;
    switch (t.type) {
      case 'strong':
        return (
          <Text key={k} style={styles.bold}>
            {renderInline(styles, (t as Tokens.Strong).tokens, k)}
          </Text>
        );
      case 'em':
        return (
          <Text key={k} style={styles.italic}>
            {renderInline(styles, (t as Tokens.Em).tokens, k)}
          </Text>
        );
      case 'del':
        return (
          <Text key={k} style={styles.strike}>
            {renderInline(styles, (t as Tokens.Del).tokens, k)}
          </Text>
        );
      case 'codespan':
        return (
          <Text key={k} style={styles.inlineCode}>
            <Text style={styles.codePad}>{'\u2009'}</Text>
            {(t as Tokens.Codespan).text}
            <Text style={styles.codePad}>{'\u2009'}</Text>
          </Text>
        );
      case 'link':
        return (
          <Text key={k} style={styles.link}>
            {renderInline(styles, (t as Tokens.Link).tokens, k)}
          </Text>
        );
      case 'br':
        return '\n';
      case 'text': {
        const tt = t as Tokens.Text;
        if (tt.tokens && tt.tokens.length) return <Text key={k}>{renderInline(styles, tt.tokens, k)}</Text>;
        return renderTextWithTags(styles, tt.text.replace(/\n/g, ' '), k);
      }
      case 'escape':
        return (t as Tokens.Escape).text;
      default:
        return 'text' in t && typeof t.text === 'string' ? t.text.replace(/\n/g, ' ') : t.raw;
    }
  });
}

function renderTextWithTags(styles: Styles, text: string, key: string): React.ReactNode {
  const parts = splitTags(text);
  if (parts.length === 1 && !parts[0].tag) return text;
  return (
    <Text key={key}>
      {parts.map((p, i) =>
        p.tag ? (
          <Text key={i} style={styles.tag}>
            {p.text}
          </Text>
        ) : (
          p.text
        ),
      )}
    </Text>
  );
}

function Blocks({ tokens, textStyle }: { tokens: Token[]; textStyle?: TextStyle }) {
  const styles = useStyles();
  const out: React.ReactNode[] = [];
  let prevBottom = -1; // -1 => first block, no top margin
  tokens.forEach((t, i) => {
    const kind = blockKind(t);
    if (!kind) return;
    const sp = SPACING[kind];
    // Collapse adjacent margins like CSS: the gap is the larger of the two.
    const marginTop = prevBottom < 0 ? 0 : Math.max(prevBottom, sp.top);
    out.push(
      <View key={i} style={{ marginTop }}>
        {renderBlock(styles, t, kind, textStyle)}
      </View>,
    );
    prevBottom = sp.bottom;
  });
  return <>{out}</>;
}

function renderBlock(styles: Styles, t: Token, kind: string, textStyle?: TextStyle): React.ReactNode {
  switch (kind) {
    case 'h1':
    case 'h2':
    case 'h3':
      return <Text style={styles[kind]}>{renderInline(styles, (t as Tokens.Heading).tokens)}</Text>;
    case 'paragraph':
      return <Text style={[styles.body, textStyle]}>{renderInline(styles, (t as Tokens.Paragraph).tokens)}</Text>;
    case 'list': {
      const list = t as Tokens.List;
      const start = typeof list.start === 'number' ? list.start : 1;
      return (
        <View>
          {list.items.map((item, idx) => {
            const taskIndex = (item as TaskItem).taskIndex;
            const gap = idx === 0 ? 0 : item.task && list.items[idx - 1].task ? 8 : 4;
            if (taskIndex !== undefined) {
              return <TaskRow key={idx} item={item} index={taskIndex} marginTop={gap} />;
            }
            return (
              <View key={idx} style={[styles.listItem, { marginTop: gap }]}>
                <Text style={[styles.body, textStyle, styles.marker]}>{list.ordered ? `${start + idx}.` : '•'}</Text>
                <View style={styles.listContent}>
                  <Blocks tokens={item.tokens.filter((x) => x.type !== 'checkbox')} textStyle={textStyle} />
                </View>
              </View>
            );
          })}
        </View>
      );
    }
    case 'blockquote':
      return (
        <View style={styles.quote}>
          <View style={styles.quoteBar} />
          <View style={styles.quoteContent}>
            <Blocks tokens={(t as Tokens.Blockquote).tokens} textStyle={styles.quoteText} />
          </View>
        </View>
      );
    case 'code':
      return (
        <View style={styles.codeBox}>
          <Text style={styles.codeText}>{(t as Tokens.Code).text.replace(/\n$/, '')}</Text>
        </View>
      );
    default:
      return null;
  }
}

type TaskItem = Tokens.ListItem & { taskIndex?: number };

/** Numbers unordered-list task items in document order (matches `toggleTask` in data/tasks). */
function indexTasks(tokens: Token[], counter = { n: 0 }): Token[] {
  for (const t of tokens) {
    if (t.type === 'list') {
      const list = t as Tokens.List;
      for (const item of list.items) {
        if (item.task && !list.ordered) (item as TaskItem).taskIndex = counter.n++;
        indexTasks(item.tokens, counter);
      }
    } else if (t.type === 'blockquote') {
      indexTasks((t as Tokens.Blockquote).tokens, counter);
    }
  }
  return tokens;
}

const ToggleCtx = React.createContext<((index: number) => void) | undefined>(undefined);

function TaskRow({ item, index, marginTop }: { item: Tokens.ListItem; index: number; marginTop: number }) {
  const styles = useStyles();
  const onToggle = React.useContext(ToggleCtx);
  const checked = !!item.checked;
  const content = item.tokens.filter((x) => x.type !== 'checkbox');
  return (
    <Pressable
      testID={`task-${index}`}
      accessibilityRole="button"
      accessibilityLabel={item.text}
      accessibilityValue={{ text: checked ? 'checked' : 'unchecked' }}
      onPress={() => onToggle?.(index)}
      style={[styles.taskRow, { marginTop }]}
    >
      <View style={[styles.box, checked ? styles.boxOn : styles.boxOff]}>
        {checked && <Text style={styles.check}>✓</Text>}
      </View>
      <View style={styles.listContent}>
        <Blocks tokens={content} textStyle={checked ? styles.taskDone : undefined} />
      </View>
    </Pressable>
  );
}

export function MarkdownView({ source, onToggleTask }: { source: string; onToggleTask?: (index: number) => void }) {
  const styles = useStyles();
  const tokens = React.useMemo(() => indexTasks(parseMarkdown(source)), [source]);
  return (
    <ToggleCtx.Provider value={onToggleTask}>
      <Blocks tokens={tokens} />
    </ToggleCtx.Provider>
  );
}

const useStyles = makeStyles((colors) => ({
  body: { fontSize: 17, lineHeight: 24, color: colors.text },
  h1: { fontSize: 28, lineHeight: 34, fontWeight: '700', color: colors.text },
  h2: { fontSize: 22, lineHeight: 28, fontWeight: '700', color: colors.text },
  h3: { fontSize: 18, lineHeight: 24, fontWeight: '600', color: colors.text },
  bold: { fontWeight: '700' },
  italic: { fontStyle: 'italic' },
  strike: { textDecorationLine: 'line-through' },
  link: { color: colors.accent },
  tag: { color: colors.accent, fontWeight: '500' },
  inlineCode: { fontFamily: mono, fontSize: 15, color: colors.accent, backgroundColor: colors.accentSoft },
  codePad: { fontFamily: Platform.OS === 'ios' ? 'System' : 'sans-serif', fontSize: 15 },
  listItem: { flexDirection: 'row' },
  marker: { marginRight: 8 },
  listContent: { flex: 1 },
  taskRow: { flexDirection: 'row', alignItems: 'flex-start' },
  box: { width: 22, height: 22, borderRadius: 6, marginTop: 1, marginRight: 10, alignItems: 'center', justifyContent: 'center' },
  boxOff: { borderWidth: 2, borderColor: colors.textTertiary },
  boxOn: { backgroundColor: colors.accent },
  check: { color: '#FFFFFF', fontSize: 14, lineHeight: 16, fontWeight: '700' },
  taskDone: { color: colors.textTertiary, textDecorationLine: 'line-through' },
  quote: { flexDirection: 'row' },
  quoteBar: { width: 3, backgroundColor: colors.accent, marginRight: 12 },
  quoteContent: { flex: 1 },
  quoteText: { fontStyle: 'italic', color: colors.textSecondary },
  codeBox: { backgroundColor: colors.codeBg, borderRadius: 10, padding: 12 },
  codeText: { fontFamily: mono, fontSize: 14, lineHeight: 20, color: colors.codeText },
}));

type Styles = ReturnType<typeof useStyles>;
