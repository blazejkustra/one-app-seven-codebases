import { a11y, colors } from '../theme.js';

export interface Segment<T extends string> {
  value: T;
  label: string;
  id: string;
}

export function SegmentedControl<T extends string>({ segments, selected, onChange }: {
  segments: Segment<T>[];
  selected: T;
  onChange: (v: T) => void;
}) {
  return (
    <view
      style={{
        marginTop: '4px',
        marginLeft: '16px',
        marginRight: '16px',
        height: '36px',
        borderRadius: '9px',
        backgroundColor: colors.fill,
        padding: '2px',
        display: 'flex',
        flexDirection: 'row',
      }}
    >
      {segments.map((s) => {
        const on = s.value === selected;
        return (
          <view
            key={s.value}
            {...a11y(s.id, s.label, {
              'accessibility-traits': on ? 'button,selected' : 'button',
              'accessibility-value': on ? 'selected' : '',
            })}
            style={{
              flexGrow: 1, flexShrink: 1, flexBasis: '0px',
              borderRadius: '7px',
              backgroundColor: on ? colors.surface : 'transparent',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
            bindtap={() => onChange(s.value)}
          >
            <text style={{ fontSize: '15px', fontWeight: on ? '600' : '500', color: on ? colors.text : colors.textSecondary }}>
              {s.label}
            </text>
          </view>
        );
      })}
    </view>
  );
}
