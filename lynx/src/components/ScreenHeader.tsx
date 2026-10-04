import { a11y, colors } from '../theme.js';

export function ScreenHeader({ title, onAdd }: { title: string; onAdd?: () => void }) {
  return (
    <view
      style={{
        height: '52px',
        paddingLeft: '20px',
        paddingRight: '20px',
        display: 'flex',
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
      }}
    >
      <text style={{ fontSize: '34px', fontWeight: 'bold', color: colors.text }}>{title}</text>
      {onAdd ? (
        <view
          {...a11y('add-note-button', 'New note', { 'accessibility-traits': 'button' })}
          style={{
            width: '36px',
            height: '36px',
            borderRadius: '18px',
            backgroundColor: colors.accent,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
          bindtap={onAdd}
        >
          <text style={{ fontSize: '24px', lineHeight: '28px', fontWeight: '400', color: '#FFFFFF', textAlign: 'center' }}>
            +
          </text>
        </view>
      ) : null}
    </view>
  );
}
