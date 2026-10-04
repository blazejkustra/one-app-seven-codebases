import React, { useMemo } from 'react';
import { View } from 'react-native';
import { useNotes } from '../data/NotesStore';
import { sortNotes } from '../data/noteText';
import { NoteList } from '../ui/NoteList';
import { ScreenHeader } from '../ui/ScreenHeader';

export function StarredScreen({ onOpen }: { onOpen: (id: string) => void }) {
  const { notes, settings } = useNotes();
  const starred = useMemo(
    () => sortNotes(notes.filter((n) => n.starred), settings.sortBy),
    [notes, settings.sortBy],
  );
  return (
    <View style={{ flex: 1 }}>
      <ScreenHeader title="Starred" />
      <NoteList notes={starred} showSnippets={settings.showSnippets} emptyText="No starred notes" onOpen={onOpen} />
    </View>
  );
}
