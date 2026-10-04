import React from 'react';
import { Pressable, ScrollView, Text } from 'react-native';
import { makeStyles } from '../theme';

/** Horizontally scrolling tag filter chips. `selected === null` means "All". */
export function TagFilter({
  tags,
  selected,
  onSelect,
}: {
  tags: string[];
  selected: string | null;
  onSelect: (tag: string | null) => void;
}) {
  const styles = useStyles();
  const chips: { key: string; label: string; tag: string | null }[] = [
    { key: 'all', label: 'All', tag: null },
    ...tags.map((t) => ({ key: t, label: `#${t}`, tag: t })),
  ];
  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      style={styles.row}
      contentContainerStyle={styles.content}
      keyboardShouldPersistTaps="handled"
    >
      {chips.map((c) => {
        const on = c.tag === selected;
        return (
          <Pressable
            key={c.key}
            testID={`tag-filter-${c.key}`}
            accessibilityRole="button"
            accessibilityLabel={c.label}
            accessibilityState={{ selected: on }}
            onPress={() => onSelect(c.tag)}
            style={[styles.chip, on ? styles.chipOn : styles.chipOff]}
          >
            <Text style={[styles.label, on ? styles.labelOn : styles.labelOff]}>{c.label}</Text>
          </Pressable>
        );
      })}
    </ScrollView>
  );
}

const useStyles = makeStyles((colors) => ({
  row: { marginTop: 12, flexGrow: 0, height: 32 },
  content: { paddingHorizontal: 16, gap: 8 },
  chip: { height: 32, paddingHorizontal: 12, borderRadius: 16, justifyContent: 'center' },
  chipOn: { backgroundColor: colors.accent },
  chipOff: { backgroundColor: colors.surface },
  label: { fontSize: 15 },
  labelOn: { color: '#FFFFFF', fontWeight: '600' },
  labelOff: { color: colors.text, fontWeight: '500' },
}));
