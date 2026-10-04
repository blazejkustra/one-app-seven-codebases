import React from 'react';
import { Pressable, View } from 'react-native';
import { makeStyles, useColors } from '../theme';

/** Custom drawn switch (no native UISwitch). */
export function Toggle({
  value,
  onChange,
  testID,
  label,
}: {
  value: boolean;
  onChange: (v: boolean) => void;
  testID?: string;
  label?: string;
}) {
  const styles = useStyles();
  const colors = useColors();
  return (
    <Pressable
      testID={testID}
      accessibilityRole="switch"
      accessibilityLabel={label}
      accessibilityState={{ checked: value }}
      accessibilityValue={{ text: value ? '1' : '0' }}
      onPress={() => onChange(!value)}
      hitSlop={8}
      style={[styles.track, { backgroundColor: value ? colors.accent : colors.fill }]}
    >
      <View style={[styles.knob, value ? styles.on : styles.off]} />
    </Pressable>
  );
}

const useStyles = makeStyles((colors) => ({
  track: { width: 51, height: 31, borderRadius: 15.5 },
  knob: { position: 'absolute', top: 2, width: 27, height: 27, borderRadius: 13.5, backgroundColor: '#FFFFFF' },
  on: { left: 22 },
  off: { left: 2 },
}));
