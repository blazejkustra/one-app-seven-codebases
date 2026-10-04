import React, { useEffect, useMemo } from 'react';
import { TextInput, View } from 'react-native';
import { useNotes } from '../data/NotesStore';
import { matchesSearch, sortNotes } from '../data/noteText';
import { allTags, extractTags } from '../data/tags';
import { makeStyles, useColors, useTheme } from '../theme';
import { NoteList } from '../ui/NoteList';
import { ScreenHeader } from '../ui/ScreenHeader';
import { TagFilter } from '../ui/TagFilter';

export function NotesScreen({
  query,
  onQueryChange,
  tag,
  onTagChange,
  onOpen,
  onCreate,
}: {
  query: string;
  onQueryChange: (q: string) => void;
  tag: string | null;
  onTagChange: (t: string | null) => void;
  onOpen: (id: string) => void;
  onCreate: () => void;
}) {
  const styles = useStyles();
  const colors = useColors();
  const { dark } = useTheme();
  const { notes, settings } = useNotes();
  const tags = useMemo(() => allTags(notes.map((n) => n.body)), [notes]);
  // A selected tag that no longer exists on any note falls back to "All".
  const activeTag = tag !== null && tags.includes(tag) ? tag : null;
  useEffect(() => {
    if (tag !== null && activeTag === null) onTagChange(null);
  }, [tag, activeTag, onTagChange]);
  const visible = useMemo(
    () =>
      sortNotes(
        notes.filter((n) => matchesSearch(n, query) && (activeTag === null || extractTags(n.body).includes(activeTag))),
        settings.sortBy,
      ),
    [notes, query, activeTag, settings.sortBy],
  );
  return (
    <View style={styles.flex}>
      <ScreenHeader title="Notes" onAdd={onCreate} />
      <TextInput
        testID="search-input"
        accessibilityLabel="Search notes"
        style={styles.search}
        placeholder="Search notes"
        placeholderTextColor={colors.textTertiary}
        value={query}
        onChangeText={onQueryChange}
        autoCorrect={false}
        autoCapitalize="none"
        clearButtonMode="never"
        returnKeyType="search"
        keyboardAppearance={dark ? 'dark' : 'light'}
        selectionColor={colors.accent}
      />
      <TagFilter tags={tags} selected={activeTag} onSelect={onTagChange} />
      <NoteList
        notes={visible}
        showSnippets={settings.showSnippets}
        emptyText={notes.length === 0 ? 'No notes yet' : 'No notes found'}
        onOpen={onOpen}
      />
    </View>
  );
}

const useStyles = makeStyles((colors) => ({
  flex: { flex: 1 },
  search: {
    marginTop: 4,
    marginHorizontal: 16,
    height: 40,
    borderRadius: 10,
    backgroundColor: colors.fill,
    paddingLeft: 12,
    paddingRight: 12,
    fontSize: 17,
    color: colors.text,
  },
}));
