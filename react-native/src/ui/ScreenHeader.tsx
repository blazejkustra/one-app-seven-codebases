import React from 'react';
import { Pressable, Text, View } from 'react-native';
import { makeStyles } from '../theme';

export function ScreenHeader({ title, onAdd }: { title: string; onAdd?: () => void }) {
  const styles = useStyles();
  return (
    <View style={styles.header}>
      <Text style={styles.title} accessibilityRole="header">
        {title}
      </Text>
      {onAdd && (
        <Pressable
          testID="add-note-button"
          accessibilityRole="button"
          accessibilityLabel="New note"
          onPress={onAdd}
          style={styles.add}
          hitSlop={4}
        >
          <Text style={styles.plus}>+</Text>
        </Pressable>
      )}
    </View>
  );
}

const useStyles = makeStyles((colors) => ({
  header: {
    height: 52,
    paddingHorizontal: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  title: { fontSize: 34, fontWeight: '700', color: colors.text },
  add: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: colors.accent,
    alignItems: 'center',
    justifyContent: 'center',
  },
  plus: { color: '#FFFFFF', fontSize: 24, lineHeight: 28, fontWeight: '400', marginTop: -2 },
}));
