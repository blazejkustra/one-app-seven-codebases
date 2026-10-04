import { a11y, colors } from '../theme.js';

export type Tab = 'notes' | 'starred' | 'settings';

const TABS: { id: Tab; label: string }[] = [
  { id: 'notes', label: 'Notes' },
  { id: 'starred', label: 'Starred' },
  { id: 'settings', label: 'Settings' },
];

export function TabBar({ active, bottomInset, onSelect }: {
  active: Tab;
  bottomInset: number;
  onSelect: (tab: Tab) => void;
}) {
  return (
    <view
      style={{
        display: 'flex',
        flexDirection: 'row',
        height: `${56 + bottomInset}px`,
        paddingBottom: `${bottomInset}px`,
        backgroundColor: colors.surface,
        borderTopWidth: '1px',
        borderTopStyle: 'solid',
        borderTopColor: colors.separator,
      }}
    >
      {TABS.map((t) => {
        const on = t.id === active;
        return (
          <view
            key={t.id}
            {...a11y(`tab-${t.id}`, t.label, { 'accessibility-traits': on ? 'button,selected' : 'button' })}
            style={{ flexGrow: 1, flexShrink: 1, flexBasis: '0px', height: '56px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
            bindtap={() => onSelect(t.id)}
          >
            <text
              style={{
                fontSize: '15px',
                fontWeight: on ? '600' : '500',
                color: on ? colors.accent : colors.textTertiary,
              }}
            >
              {t.label}
            </text>
          </view>
        );
      })}
    </view>
  );
}
