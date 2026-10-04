import React from 'react';
import { Pressable, Text, View } from 'react-native';
import { dateLabel, noteSnippet, noteTitle } from '../data/noteText';
import { extractTags } from '../data/tags';
import { taskProgress } from '../data/tasks';
import type { Note } from '../data/types';
import { makeStyles } from '../theme';

export const NoteCard = React.memo(function NoteCard({
  note,
  showSnippet,
  onPress,
}: {
  note: Note;
  showSnippet: boolean;
  onPress: (id: string) => void;
}) {
  const styles = useStyles();
  const title = noteTitle(note.body);
  const snippet = showSnippet ? noteSnippet(note.body) : '';
  const tags = extractTags(note.body);
  const progress = taskProgress(note.body);
  return (
    <Pressable
      testID="note-card"
      accessibilityRole="button"
      accessibilityLabel={title}
      onPress={() => onPress(note.id)}
      style={styles.card}
    >
      <Text style={styles.title} numberOfLines={1}>
        {title}
      </Text>
      {snippet.length > 0 && (
        <Text style={styles.snippet} numberOfLines={2}>
          {snippet}
        </Text>
      )}
      {tags.length > 0 && (
        <View style={styles.tags}>
          {tags.map((t) => (
            <View key={t} style={styles.tag}>
              <Text style={styles.tagText} numberOfLines={1}>
                #{t}
              </Text>
            </View>
          ))}
        </View>
      )}
      <View style={styles.footer}>
        <View style={styles.footerLeft}>
          <Text style={styles.date}>{dateLabel(note.updatedAt)}</Text>
          {progress.total > 0 && (
            <Text style={styles.progress}>
              {progress.done}/{progress.total} done
            </Text>
          )}
        </View>
        {note.starred && <Text style={styles.star}>★</Text>}
      </View>
    </Pressable>
  );
});

const useStyles = makeStyles((colors) => ({
  card: { backgroundColor: colors.surface, borderRadius: 14, padding: 16 },
  title: { fontSize: 17, lineHeight: 22, fontWeight: '600', color: colors.text },
  snippet: { marginTop: 4, fontSize: 15, lineHeight: 20, color: colors.textSecondary },
  tags: { marginTop: 8, flexDirection: 'row', flexWrap: 'nowrap', overflow: 'hidden', gap: 6 },
  tag: {
    height: 22,
    paddingHorizontal: 8,
    borderRadius: 11,
    backgroundColor: colors.accentSoft,
    justifyContent: 'center',
    flexShrink: 0,
  },
  tagText: { fontSize: 12, fontWeight: '500', color: colors.accent },
  footer: { marginTop: 8, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', minHeight: 18 },
  footerLeft: { flexDirection: 'row', alignItems: 'center' },
  progress: { marginLeft: 12, fontSize: 13, lineHeight: 18, color: colors.textSecondary },
  date: { fontSize: 13, lineHeight: 18, color: colors.textTertiary },
  star: { fontSize: 16, lineHeight: 18, color: colors.star },
}));
