import { a11y, colors } from '../theme.js';

/** "Note deleted · Undo" toast shown 12 pt above the tab bar. */
export function Toast({ bottom, onUndo }: { bottom: number; onUndo: () => void }) {
  return (
    <view
      {...a11y('toast', 'Note deleted', { 'accessibility-element': false })}
      style={{
        position: 'absolute',
        left: '16px',
        right: '16px',
        bottom: `${bottom}px`,
        height: '48px',
        borderRadius: '12px',
        backgroundColor: colors.toastBg,
        paddingLeft: '16px',
        paddingRight: '16px',
        display: 'flex',
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
      }}
    >
      <text style={{ fontSize: '15px', color: '#FFFFFF' }}>Note deleted</text>
      <view
        {...a11y('undo-button', 'Undo', { 'accessibility-traits': 'button' })}
        style={{ height: '48px', paddingLeft: '12px', display: 'flex', flexDirection: 'row', alignItems: 'center' }}
        bindtap={onUndo}
      >
        <text style={{ fontSize: '15px', fontWeight: '600', color: '#A79FFF' }}>Undo</text>
      </view>
    </view>
  );
}
