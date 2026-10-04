import { Component, output } from '@angular/core';
import { Pressable, Text, View } from '@ng-native/components';

/** Dark "Note deleted · Undo" snackbar. Positioning is left to the parent. */
@Component({
  selector: 'app-toast',
  imports: [Pressable, Text, View],
  template: `
    <view testID="toast" class="toast">
      <text class="message">Note deleted</text>
      <pressable testID="undo-button" accessibilityRole="button" class="undo" [hitSlop]="10" (press)="undo.emit()">
        <text class="undo-text">Undo</text>
      </pressable>
    </view>
  `,
  styles: `
    .toast {
      height: 48px;
      border-radius: 12px;
      background-color: var(--toast-bg);
      padding-left: 16px;
      padding-right: 16px;
      flex-direction: row;
      align-items: center;
      justify-content: space-between;
    }
    .message {
      font-size: 15px;
      color: #ffffff;
    }
    .undo {
      height: 48px;
      justify-content: center;
    }
    .undo-text {
      font-size: 15px;
      font-weight: 600;
      color: #a79fff;
    }
  `,
})
export class Toast {
  readonly undo = output<void>();
}
