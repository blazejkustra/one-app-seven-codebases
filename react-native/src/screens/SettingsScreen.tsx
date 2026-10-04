import React from 'react';
import { Pressable, ScrollView, Text, View } from 'react-native';
import { useNotes } from '../data/NotesStore';
import type { Appearance } from '../data/types';
import { makeStyles } from '../theme';
import { IdText } from '../ui/IdText';
import { ScreenHeader } from '../ui/ScreenHeader';
import { Toggle } from '../ui/Toggle';

const APPEARANCE_LABEL: Record<Appearance, string> = { system: 'System', light: 'Light', dark: 'Dark' };
const NEXT_APPEARANCE: Record<Appearance, Appearance> = { system: 'light', light: 'dark', dark: 'system' };

export function SettingsScreen() {
  const styles = useStyles();
  const { notes, settings, updateSettings, resetSamples } = useNotes();
  const appearanceLabel = APPEARANCE_LABEL[settings.appearance];
  const sortLabel = settings.sortBy === 'updated' ? 'Updated' : 'Title';
  return (
    <View style={{ flex: 1 }}>
      <ScreenHeader title="Settings" />
      <ScrollView contentContainerStyle={styles.content}>
        <View style={styles.group}>
          <Pressable
            testID="sort-row"
            accessibilityRole="button"
            accessibilityLabel={`Sort by, ${sortLabel}`}
            accessibilityValue={{ text: sortLabel }}
            style={styles.row}
            onPress={() => updateSettings({ sortBy: settings.sortBy === 'updated' ? 'title' : 'updated' })}
          >
            <Text style={styles.label}>Sort by</Text>
            <Text style={styles.value}>{sortLabel}</Text>
          </Pressable>
          <View style={styles.separator} />
          <View style={styles.row}>
            <Text style={styles.label}>Show snippets</Text>
            <Toggle
              testID="snippets-switch"
              label="Show snippets"
              value={settings.showSnippets}
              onChange={(v) => updateSettings({ showSnippets: v })}
            />
          </View>
          <View style={styles.separator} />
          <Pressable
            testID="appearance-row"
            accessibilityRole="button"
            accessibilityLabel={`Appearance, ${appearanceLabel}`}
            accessibilityValue={{ text: appearanceLabel }}
            style={styles.row}
            onPress={() => updateSettings({ appearance: NEXT_APPEARANCE[settings.appearance] })}
          >
            <Text style={styles.label}>Appearance</Text>
            <Text style={styles.value}>{appearanceLabel}</Text>
          </Pressable>
          <View style={styles.separator} />
          <View style={styles.row}>
            <Text style={styles.label}>Notes</Text>
            <IdText testID="notes-count" style={styles.count}>
              {notes.length}
            </IdText>
          </View>
        </View>
        <View style={[styles.group, styles.group2]}>
          <Pressable
            testID="reset-button"
            accessibilityRole="button"
            accessibilityLabel="Reset sample notes"
            style={[styles.row, styles.centerRow]}
            onPress={resetSamples}
          >
            <Text style={styles.danger}>Reset sample notes</Text>
          </Pressable>
        </View>
        <Text style={styles.footer}>Markdown Notes · v1.0</Text>
      </ScrollView>
    </View>
  );
}

const useStyles = makeStyles((colors) => ({
  content: { paddingTop: 12, paddingBottom: 16 },
  group: { marginHorizontal: 16, backgroundColor: colors.surface, borderRadius: 14, overflow: 'hidden' },
  group2: { marginTop: 24 },
  row: {
    height: 52,
    paddingHorizontal: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  centerRow: { justifyContent: 'center' },
  separator: { height: 1, marginLeft: 16, backgroundColor: colors.separator },
  label: { fontSize: 17, color: colors.text },
  value: { fontSize: 17, color: colors.accent },
  count: { fontSize: 17, color: colors.textTertiary },
  danger: { fontSize: 17, color: colors.danger },
  footer: { marginTop: 16, textAlign: 'center', fontSize: 13, color: colors.textTertiary },
}));
