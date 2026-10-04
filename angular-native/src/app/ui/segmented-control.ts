import { Component, input, output } from '@angular/core';
import { Pressable, Text, View } from '@ng-native/components';

export type EditorMode = 'edit' | 'preview';

/** Custom-drawn two-segment control (no UISegmentedControl, per spec). */
@Component({
  selector: 'app-segmented-control',
  imports: [Pressable, Text, View],
  template: `
    <view class="track">
      <pressable
        testID="mode-edit"
        accessibilityRole="button"
        [accessibilityState]="{ selected: mode() === 'edit' }"
        class="segment"
        [class.selected]="mode() === 'edit'"
        (press)="change.emit('edit')"
      >
        <text class="label" [class.label-selected]="mode() === 'edit'">Edit</text>
      </pressable>
      <pressable
        testID="mode-preview"
        accessibilityRole="button"
        [accessibilityState]="{ selected: mode() === 'preview' }"
        class="segment"
        [class.selected]="mode() === 'preview'"
        (press)="change.emit('preview')"
      >
        <text class="label" [class.label-selected]="mode() === 'preview'">Preview</text>
      </pressable>
    </view>
  `,
  styles: `
    .track {
      height: 36px;
      border-radius: 9px;
      background-color: var(--fill);
      padding: 2px;
      flex-direction: row;
    }
    .segment {
      flex: 1;
      border-radius: 7px;
      align-items: center;
      justify-content: center;
    }
    .selected {
      background-color: var(--surface);
    }
    .label {
      font-size: 15px;
      font-weight: 500;
      color: var(--text-secondary);
    }
    .label-selected {
      font-weight: 600;
      color: var(--text);
    }
  `,
})
export class SegmentedControl {
  readonly mode = input.required<EditorMode>();
  readonly change = output<EditorMode>();
}
