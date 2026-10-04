import { a11y, colors } from '../theme.js';

/** Horizontally scrolling tag filter chips: `All` + every tag A→Z. */
export function TagFilterRow({ tags, selected, onSelect }: {
  tags: string[];
  selected: string | null;
  onSelect: (tag: string | null) => void;
}) {
  const chips: { key: string; label: string; value: string | null }[] = [
    { key: 'all', label: 'All', value: null },
    ...tags.map((t) => ({ key: t, label: `#${t}`, value: t })),
  ];
  return (
    <scroll-view scroll-orientation='horizontal' style={{ marginTop: '12px', height: '32px', width: '100%' }}>
      <view style={{ display: 'flex', flexDirection: 'row', paddingLeft: '16px', paddingRight: '16px', height: '32px' }}>
        {chips.map((c, i) => {
          const on = c.value === selected;
          return (
            <view
              key={c.key}
              {...a11y(`tag-filter-${c.key}`, c.label, {
                'accessibility-traits': on ? 'button,selected' : 'button',
                'accessibility-value': on ? 'selected' : '',
              })}
              style={{
                flexShrink: 0,
                height: '32px',
                marginLeft: i === 0 ? '0px' : '8px',
                paddingLeft: '12px',
                paddingRight: '12px',
                borderRadius: '16px',
                backgroundColor: on ? colors.accent : colors.surface,
                display: 'flex',
                alignItems: 'center',
              }}
              bindtap={() => onSelect(c.value)}
            >
              <text style={{ fontSize: '15px', fontWeight: on ? '600' : '500', color: on ? '#FFFFFF' : colors.text }}>
                {c.label}
              </text>
            </view>
          );
        })}
      </view>
    </scroll-view>
  );
}
