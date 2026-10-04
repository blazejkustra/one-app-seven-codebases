import { NoteList } from '../components/NoteList.js';
import { ScreenHeader } from '../components/ScreenHeader.js';
import type { Note } from '../data/types.js';

export function StarredScreen({ notes, showSnippets, onOpen }: {
  notes: Note[];
  showSnippets: boolean;
  onOpen: (id: string) => void;
}) {
  return (
    <view style={{ flexGrow: 1, flexShrink: 1, flexBasis: '0px', display: 'flex', flexDirection: 'column' }}>
      <ScreenHeader title='Starred' />
      <NoteList
        notes={notes.filter((n) => n.starred)}
        showSnippets={showSnippets}
        emptyText='No starred notes'
        onOpen={onOpen}
      />
    </view>
  );
}
