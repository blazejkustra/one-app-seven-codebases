import { a11y, colors } from '../theme.js';

export function Switch({ id, label, value, onChange }: {
  id: string;
  label: string;
  value: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <view
      {...a11y(id, label, { 'accessibility-value': value ? '1' : '0', 'accessibility-traits': 'button' })}
      style={{
        width: '51px',
        height: '31px',
        borderRadius: '15.5px',
        backgroundColor: value ? colors.accent : colors.fill,
        position: 'relative',
      }}
      bindtap={() => onChange(!value)}
    >
      <view
        style={{
          position: 'absolute',
          top: '2px',
          left: value ? '22px' : '2px',
          width: '27px',
          height: '27px',
          borderRadius: '13.5px',
          backgroundColor: '#FFFFFF',
        }}
      />
    </view>
  );
}
