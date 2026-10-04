import { ScreenHeader } from '../components/ScreenHeader.js';
import { Switch } from '../components/Switch.js';
import type { Appearance, Settings } from '../data/types.js';

const APPEARANCE_LABEL: Record<Appearance, string> = { system: 'System', light: 'Light', dark: 'Dark' };
const NEXT_APPEARANCE: Record<Appearance, Appearance> = { system: 'light', light: 'dark', dark: 'system' };
import { a11y, colors } from '../theme.js';

const groupStyle = () => ({
  marginLeft: '16px',
  marginRight: '16px',
  borderRadius: '14px',
  backgroundColor: colors.surface,
  display: 'flex',
  flexDirection: 'column',
  overflow: 'hidden',
} as const);

const row = {
  height: '52px',
  paddingLeft: '16px',
  paddingRight: '16px',
  display: 'flex',
  flexDirection: 'row',
  alignItems: 'center',
  justifyContent: 'space-between',
} as const;

const labelStyle = () => ({ fontSize: '17px', color: colors.text } as const);

function Separator() {
  return <view style={{ height: '1px', marginLeft: '16px', backgroundColor: colors.separator }} />;
}

export function SettingsScreen({ settings, noteCount, onChange, onReset }: {
  settings: Settings;
  noteCount: number;
  onChange: (s: Settings) => void;
  onReset: () => void;
}) {
  const sortLabel = settings.sort === 'updated' ? 'Updated' : 'Title';
  const appearanceLabel = APPEARANCE_LABEL[settings.appearance];
  return (
    <view style={{ flexGrow: 1, flexShrink: 1, flexBasis: '0px', display: 'flex', flexDirection: 'column' }}>
      <ScreenHeader title='Settings' />
      <view style={{ ...groupStyle(), marginTop: '12px' }}>
        <view
          {...a11y('sort-row', `Sort by, ${sortLabel}`, { 'accessibility-value': sortLabel, 'accessibility-traits': 'button' })}
          style={row}
          bindtap={() => onChange({ ...settings, sort: settings.sort === 'updated' ? 'title' : 'updated' })}
        >
          <text style={labelStyle()}>Sort by</text>
          <text style={{ fontSize: '17px', color: colors.accent }}>{sortLabel}</text>
        </view>
        <Separator />
        <view style={{ ...row, height: '51px' }}>
          <text style={labelStyle()}>Show snippets</text>
          <Switch
            id='snippets-switch'
            label='Show snippets'
            value={settings.showSnippets}
            onChange={(v) => onChange({ ...settings, showSnippets: v })}
          />
        </view>
        <Separator />
        <view
          {...a11y('appearance-row', `Appearance, ${appearanceLabel}`, {
            'accessibility-value': appearanceLabel,
            'accessibility-traits': 'button',
          })}
          style={{ ...row, height: '51px' }}
          bindtap={() => onChange({ ...settings, appearance: NEXT_APPEARANCE[settings.appearance] })}
        >
          <text style={labelStyle()}>Appearance</text>
          <text style={{ fontSize: '17px', color: colors.accent }}>{appearanceLabel}</text>
        </view>
        <Separator />
        <view style={{ ...row, height: '51px' }}>
          <text style={labelStyle()}>Notes</text>
          <text {...a11y('notes-count', String(noteCount))} style={{ fontSize: '17px', color: colors.textTertiary }}>
            {String(noteCount)}
          </text>
        </view>
      </view>
      <view style={{ ...groupStyle(), marginTop: '24px' }}>
        <view
          {...a11y('reset-button', 'Reset sample notes', { 'accessibility-traits': 'button' })}
          style={{ ...row, justifyContent: 'center' }}
          bindtap={onReset}
        >
          <text style={{ fontSize: '17px', color: colors.danger }}>Reset sample notes</text>
        </view>
      </view>
      <text style={{ marginTop: '16px', fontSize: '13px', color: colors.textTertiary, textAlign: 'center' }}>
        {'Markdown Notes · v1.0'}
      </text>
    </view>
  );
}
