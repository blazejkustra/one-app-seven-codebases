import { NoteList } from '../components/NoteList.js';
import { ScreenHeader } from '../components/ScreenHeader.js';
import { TagFilterRow } from '../components/TagFilterRow.js';
import { matchesSearch } from '../data/notes.js';
import { allTags, noteTags } from '../data/tags.js';
import type { Note } from '../data/types.js';
import { a11y, colors } from '../theme.js';

export function NotesScreen({ notes, query, tag, showSnippets, onQuery, onTag, onAdd, onOpen }: {
  notes: Note[];
  query: string;
  tag: string | null;
  onTag: (tag: string | null) => void;
  showSnippets: boolean;
  onQuery: (q: string) => void;
  onAdd: () => void;
  onOpen: (id: string) => void;
}) {
  const tags = allTags(notes.map((n) => noteTags(n.body)));
  const activeTag = tag !== null && tags.includes(tag) ? tag : null;
  const visible = notes.filter(
    (n) => matchesSearch(n, query) && (activeTag === null || noteTags(n.body).includes(activeTag)),
  );
  const emptyText = notes.length === 0 ? 'No notes yet' : 'No notes found';
  return (
    <view style={{ flexGrow: 1, flexShrink: 1, flexBasis: '0px', display: 'flex', flexDirection: 'column' }}>
      <ScreenHeader title='Notes' onAdd={onAdd} />
      <view
        style={{
          marginTop: '4px',
          marginLeft: '16px',
          marginRight: '16px',
          height: '40px',
          borderRadius: '10px',
          backgroundColor: colors.fill,
          paddingLeft: '12px',
          paddingRight: '12px',
          display: 'flex',
          flexDirection: 'row',
          alignItems: 'center',
        }}
      >
        <input
          {...a11y('search-input', 'Search notes', {
            'default-value': query,
            'confirm-type': 'search',
            'ios-auto-correct': false,
            'ios-spell-check': false,
          })}
          className='search-input'
          placeholder='Search notes'
          style={{ flexGrow: 1, flexShrink: 1, flexBasis: '0px', height: '40px', fontSize: '17px', color: colors.text, caretColor: colors.accent }}
          bindinput={(e: { detail: { value: string } }) => onQuery(e.detail.value)}
        />
      </view>
      <TagFilterRow tags={tags} selected={activeTag} onSelect={onTag} />
      <NoteList notes={visible} showSnippets={showSnippets} emptyText={emptyText} onOpen={onOpen} />
    </view>
  );
}
