import React from 'react';
import { FlatList, View } from 'react-native';
import type { Note } from '../data/types';
import { makeStyles } from '../theme';
import { IdText } from './IdText';
import { NoteCard } from './NoteCard';

export function NoteList({
  notes,
  showSnippets,
  emptyText,
  onOpen,
}: {
  notes: Note[];
  showSnippets: boolean;
  emptyText: string;
  onOpen: (id: string) => void;
}) {
  const styles = useStyles();
  if (notes.length === 0) {
    return (
      <View style={styles.empty}>
        <IdText testID="empty-state" style={styles.emptyText}>
          {emptyText}
        </IdText>
      </View>
    );
  }
  return (
    <FlatList
      style={styles.list}
      contentContainerStyle={styles.content}
      data={notes}
      keyExtractor={(n) => n.id}
      renderItem={({ item }) => <NoteCard note={item} showSnippet={showSnippets} onPress={onOpen} />}
      ItemSeparatorComponent={Gap}
      keyboardShouldPersistTaps="handled"
      keyboardDismissMode="on-drag"
    />
  );
}

const Gap = () => <View style={{ height: 12 }} />;

const useStyles = makeStyles((colors) => ({
  list: { flex: 1 },
  content: { paddingTop: 12, paddingHorizontal: 16, paddingBottom: 16 },
  empty: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  emptyText: { fontSize: 17, color: colors.textTertiary },
}));
