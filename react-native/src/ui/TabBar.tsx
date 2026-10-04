import React from 'react';
import { Pressable, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { makeStyles } from '../theme';

export type TabKey = 'notes' | 'starred' | 'settings';

const TABS: { key: TabKey; label: string }[] = [
  { key: 'notes', label: 'Notes' },
  { key: 'starred', label: 'Starred' },
  { key: 'settings', label: 'Settings' },
];

export function TabBar({ active, onChange }: { active: TabKey; onChange: (t: TabKey) => void }) {
  const styles = useStyles();
  const insets = useSafeAreaInsets();
  return (
    <View style={[styles.bar, { paddingBottom: insets.bottom }]}>
      {TABS.map((t) => {
        const selected = t.key === active;
        return (
          <Pressable
            key={t.key}
            testID={`tab-${t.key}`}
            accessibilityRole="button"
            accessibilityState={{ selected }}
            accessibilityLabel={t.label}
            style={styles.tab}
            onPress={() => onChange(t.key)}
          >
            <Text style={[styles.label, selected ? styles.active : styles.inactive]}>{t.label}</Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const useStyles = makeStyles((colors) => ({
  bar: {
    flexDirection: 'row',
    backgroundColor: colors.surface,
    borderTopWidth: 1,
    borderTopColor: colors.separator,
  },
  tab: { flex: 1, height: 55, alignItems: 'center', justifyContent: 'center' },
  label: { fontSize: 15 },
  active: { color: colors.accent, fontWeight: '600' },
  inactive: { color: colors.textTertiary, fontWeight: '500' },
}));
