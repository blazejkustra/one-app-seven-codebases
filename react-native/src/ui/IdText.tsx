import React from 'react';
import { Text, View, type StyleProp, type TextStyle, type ViewStyle } from 'react-native';

/**
 * Static text exposed to accessibility as a single element carrying `testID`
 * (on iOS Fabric, a bare <Text testID> does not surface its accessibilityIdentifier).
 */
export function IdText({
  testID,
  children,
  style,
  containerStyle,
}: {
  testID: string;
  children: string | number;
  style?: StyleProp<TextStyle>;
  containerStyle?: StyleProp<ViewStyle>;
}) {
  return (
    <View
      testID={testID}
      accessible
      accessibilityRole="text"
      accessibilityLabel={String(children)}
      style={containerStyle}
    >
      <Text style={style}>{children}</Text>
    </View>
  );
}
