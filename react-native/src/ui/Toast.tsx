import React from 'react';
import { Pressable, Text, View } from 'react-native';
import { makeStyles } from '../theme';

export function Toast({ message, bottom, onUndo }: { message: string; bottom: number; onUndo: () => void }) {
  const styles = useStyles();
  return (
    <View testID="toast" style={[styles.toast, { bottom }]}>
      <Text style={styles.message}>{message}</Text>
      <Pressable testID="undo-button" accessibilityRole="button" accessibilityLabel="Undo" onPress={onUndo} hitSlop={10}>
        <Text style={styles.undo}>Undo</Text>
      </Pressable>
    </View>
  );
}

const useStyles = makeStyles((colors) => ({
  toast: {
    position: 'absolute',
    left: 16,
    right: 16,
    height: 48,
    borderRadius: 12,
    backgroundColor: colors.toastBg,
    paddingHorizontal: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  message: { fontSize: 15, color: '#FFFFFF' },
  undo: { fontSize: 15, fontWeight: '600', color: '#A79FFF' },
}));
