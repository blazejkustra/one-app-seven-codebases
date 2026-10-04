import { dateLabel, noteSnippet, noteTitle } from '../data/notes.js';
import { noteTags } from '../data/tags.js';
import { taskProgress } from '../data/tasks.js';
import type { Note } from '../data/types.js';
import { a11y, colors } from '../theme.js';

export function NoteCard({ note, showSnippet, first, onOpen }: {
  note: Note;
  showSnippet: boolean;
  first: boolean;
  onOpen: (id: string) => void;
}) {
  const title = noteTitle(note.body);
  const snippet = showSnippet ? noteSnippet(note.body) : '';
  const tags = noteTags(note.body);
  const progress = taskProgress(note.body);
  return (
    <view
      {...a11y('note-card', title, { 'accessibility-traits': 'button' })}
      style={{
        marginTop: first ? '0px' : '12px',
        marginLeft: '16px',
        marginRight: '16px',
        padding: '16px',
        borderRadius: '14px',
        backgroundColor: colors.surface,
        display: 'flex',
        flexDirection: 'column',
      }}
      bindtap={() => onOpen(note.id)}
    >
      <text
        text-maxline='1'
        style={{ fontSize: '17px', lineHeight: '22px', fontWeight: '600', color: colors.text, textOverflow: 'ellipsis', overflow: 'hidden' }}
      >
        {title}
      </text>
      {snippet !== '' ? (
        <text
          text-maxline='2'
          style={{
            marginTop: '4px',
            fontSize: '15px',
            lineHeight: '20px',
            color: colors.textSecondary,
            textOverflow: 'ellipsis',
            overflow: 'hidden',
          }}
        >
          {snippet}
        </text>
      ) : null}
      {tags.length > 0 ? (
        <view style={{ marginTop: '8px', height: '22px', display: 'flex', flexDirection: 'row', overflow: 'hidden' }}>
          {tags.map((t, i) => (
            <view
              key={t}
              style={{
                flexShrink: 0,
                height: '22px',
                marginLeft: i === 0 ? '0px' : '6px',
                paddingLeft: '8px',
                paddingRight: '8px',
                borderRadius: '11px',
                backgroundColor: colors.accentSoft,
                display: 'flex',
                alignItems: 'center',
              }}
            >
              <text style={{ fontSize: '12px', fontWeight: '500', color: colors.accent }}>{`#${t}`}</text>
            </view>
          ))}
        </view>
      ) : null}
      <view
        style={{ marginTop: '8px', display: 'flex', flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }}
      >
        <view style={{ display: 'flex', flexDirection: 'row', alignItems: 'center' }}>
          <text style={{ fontSize: '13px', lineHeight: '18px', color: colors.textTertiary }}>{dateLabel(note.updatedAt)}</text>
          {progress ? (
            <text style={{ marginLeft: '12px', fontSize: '13px', lineHeight: '18px', color: colors.textSecondary }}>
              {`${progress.done}/${progress.total} done`}
            </text>
          ) : null}
        </view>
        {note.starred ? <text style={{ fontSize: '16px', lineHeight: '18px', color: colors.star }}>{'★'}</text> : null}
      </view>
    </view>
  );
}
