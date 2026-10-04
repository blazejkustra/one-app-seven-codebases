import React from 'react';
import { Pressable, Text, View } from 'react-native';
import { makeStyles } from '../theme';

export type Segment<T extends string> = { key: T; label: string; testID: string };

export function Segmented<T extends string>({
  segments,
  value,
  onChange,
}: {
  segments: Segment<T>[];
  value: T;
  onChange: (v: T) => void;
}) {
  const styles = useStyles();
  return (
    <View style={styles.track}>
      {segments.map((s) => {
        const selected = s.key === value;
        return (
          <Pressable
            key={s.key}
            testID={s.testID}
            accessibilityRole="button"
            accessibilityLabel={s.label}
            accessibilityState={{ selected }}
            onPress={() => onChange(s.key)}
            style={[styles.segment, selected && styles.selected]}
          >
            <Text style={[styles.label, selected ? styles.labelOn : styles.labelOff]}>{s.label}</Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const useStyles = makeStyles((colors) => ({
  track: {
    height: 36,
    marginHorizontal: 16,
    borderRadius: 9,
    backgroundColor: colors.fill,
    flexDirection: 'row',
    padding: 2,
  },
  segment: { flex: 1, borderRadius: 7, alignItems: 'center', justifyContent: 'center' },
  selected: { backgroundColor: colors.surface },
  label: { fontSize: 15 },
  labelOn: { color: colors.text, fontWeight: '600' },
  labelOff: { color: colors.textSecondary, fontWeight: '500' },
}));
