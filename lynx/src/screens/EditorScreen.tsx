import { useEffect, useRef } from '@lynx-js/react';

import { SegmentedControl } from '../components/SegmentedControl.js';
import type { Note } from '../data/types.js';
import { Markdown } from '../markdown/Markdown.js';
import { a11y, colors, IS_ANDROID, MONO } from '../theme.js';

export type EditorMode = 'edit' | 'preview';

export function EditorScreen({ note, mode, autoFocus, keyboardHeight, bottomInset, onMode, onBody, onToggleTask, onToggleStar, onBack, onDelete }: {
  note: Note;
  mode: EditorMode;
  autoFocus: boolean;
  keyboardHeight: number;
  bottomInset: number;
  onMode: (m: EditorMode) => void;
  onBody: (body: string) => void;
  onToggleTask: (index: number) => void;
  onToggleStar: () => void;
  onBack: () => void;
  onDelete: () => void;
}) {
  const focused = useRef(false);

  useEffect(() => {
    if (mode !== 'edit' || !autoFocus || focused.current) return;
    focused.current = true;
    const focus = (attempt: number) => {
      lynx
        .createSelectorQuery()
        .select('#editor-input')
        .invoke({
          method: 'focus',
          fail: () => {
            if (attempt < 10) setTimeout(() => focus(attempt + 1), 50);
          },
        })
        .exec();
    };
    setTimeout(() => focus(0), 0);
  }, [mode, autoFocus]);

  const blurEditor = () => {
    lynx.createSelectorQuery().select('#editor-input').invoke({ method: 'blur' }).exec();
  };

  const cardBottom = keyboardHeight > 0 ? keyboardHeight + 16 : bottomInset + 16;

  return (
    <view style={{ flexGrow: 1, flexShrink: 1, flexBasis: '0px', display: 'flex', flexDirection: 'column' }}>
      {/* Navigation row */}
      <view style={{ height: '44px', display: 'flex', flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }}>
        <view
          {...a11y('back-button', 'Notes', { 'accessibility-traits': 'button' })}
          style={{ height: '44px', paddingLeft: '16px', paddingRight: '12px', display: 'flex', flexDirection: 'row', alignItems: 'center' }}
          bindtap={() => {
            blurEditor();
            onBack();
          }}
        >
          <text style={{ fontSize: '17px', color: colors.accent }}>{'‹ Notes'}</text>
        </view>
        <view style={{ paddingRight: '16px', display: 'flex', flexDirection: 'row', alignItems: 'center' }}>
          <view
            {...a11y('share-button', 'Share', { 'accessibility-traits': 'button' })}
            style={{ height: '44px', marginRight: '12px', display: 'flex', flexDirection: 'row', alignItems: 'center' }}
            bindtap={() => {
              blurEditor();
              NativeModules.Share.shareText(note.body);
            }}
          >
            <text style={{ fontSize: '17px', color: colors.accent }}>Share</text>
          </view>
          <view
            {...a11y('delete-button', 'Delete', { 'accessibility-traits': 'button' })}
            style={{ height: '44px', marginRight: '12px', display: 'flex', flexDirection: 'row', alignItems: 'center' }}
            bindtap={() => {
              blurEditor();
              onDelete();
            }}
          >
            <text style={{ fontSize: '17px', color: colors.danger }}>Delete</text>
          </view>
          <view
            {...a11y('star-button', note.starred ? '★' : '☆', {
              'accessibility-value': note.starred ? 'starred' : 'not starred',
              'accessibility-traits': note.starred ? 'button,selected' : 'button',
            })}
            style={{ width: '44px', height: '44px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
            bindtap={onToggleStar}
          >
            <text style={{ fontSize: '22px', color: note.starred ? colors.star : colors.textTertiary }}>
              {note.starred ? '★' : '☆'}
            </text>
          </view>
        </view>
      </view>

      <SegmentedControl
        segments={[
          { value: 'edit', label: 'Edit', id: 'mode-edit' },
          { value: 'preview', label: 'Preview', id: 'mode-preview' },
        ]}
        selected={mode}
        onChange={(m) => {
          if (m === 'preview') blurEditor();
          onMode(m);
        }}
      />

      {mode === 'edit' ? (
        <view
          style={{
            flexGrow: 1, flexShrink: 1, flexBasis: '0px',
            marginTop: '12px',
            marginLeft: '16px',
            marginRight: '16px',
            marginBottom: `${cardBottom}px`,
            padding: '16px',
            borderRadius: '14px',
            backgroundColor: colors.surface,
            display: 'flex',
            flexDirection: 'column',
          }}
        >
          <textarea
            id='editor-input'
            {...a11y('editor-input', 'Note body', {
              'default-value': note.body,
              'ios-auto-correct': false,
              'ios-spell-check': false,
              'enable-scroll-bar': true,
              // Android's XElement textarea ignores CSS line-height (line = font height +
              // line-spacing); 15px monospace is ~17.6px tall, so add 4.4px to reach 22px.
              ...(IS_ANDROID ? { 'line-spacing': '4.4px' } : {}),
            })}
            style={{ flexGrow: 1, flexShrink: 1, flexBasis: '0px', width: '100%', fontFamily: MONO, fontSize: '15px', lineHeight: '22px', color: colors.text, caretColor: colors.accent }}
            bindinput={(e: { detail: { value: string } }) => onBody(e.detail.value)}
          />
        </view>
      ) : (
        <scroll-view
          {...a11y('preview-view', 'Preview', { 'accessibility-element': false })}
          scroll-orientation='vertical'
          style={{ flexGrow: 1, flexShrink: 1, flexBasis: '0px', marginTop: '12px' }}
        >
          <view style={{ paddingLeft: '20px', paddingRight: '20px', paddingBottom: `${bottomInset + 16}px` }}>
            <Markdown source={note.body} onToggleTask={onToggleTask} />
          </view>
        </scroll-view>
      )}
    </view>
  );
}
