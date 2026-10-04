import type { Note } from '../data/types.js';
import { a11y, colors } from '../theme.js';
import { NoteCard } from './NoteCard.js';

export function NoteList({ notes, showSnippets, emptyText, onOpen }: {
  notes: Note[];
  showSnippets: boolean;
  emptyText: string;
  onOpen: (id: string) => void;
}) {
  if (notes.length === 0) {
    return (
      <view style={{ flexGrow: 1, flexShrink: 1, flexBasis: '0px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <text {...a11y('empty-state', emptyText)} style={{ fontSize: '17px', color: colors.textTertiary }}>
          {emptyText}
        </text>
      </view>
    );
  }
  return (
    <scroll-view scroll-orientation='vertical' style={{ flexGrow: 1, flexShrink: 1, flexBasis: '0px' }}>
      <view style={{ display: 'flex', flexDirection: 'column', paddingTop: '12px', paddingBottom: '16px' }}>
        {notes.map((n, i) => (
          <NoteCard key={n.id} note={n} showSnippet={showSnippets} first={i === 0} onOpen={onOpen} />
        ))}
      </view>
    </scroll-view>
  );
}
