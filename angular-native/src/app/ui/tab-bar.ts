import { Component, inject, input, output } from '@angular/core';
import { Pressable, Text, View } from '@ng-native/components';
import { SafeArea } from '@ng-native/device';

export type Tab = 'notes' | 'starred' | 'settings';

const TABS: readonly { id: Tab; label: string }[] = [
  { id: 'notes', label: 'Notes' },
  { id: 'starred', label: 'Starred' },
  { id: 'settings', label: 'Settings' },
];

/** Custom-drawn bottom tab bar: three text-only, equal-width columns. */
@Component({
  selector: 'app-tab-bar',
  imports: [Pressable, Text, View],
  template: `
    <view class="bar" [style.paddingBottom]="safeArea.insets().bottom">
      <view class="line"></view>
      <view class="row">
        @for (tab of tabs; track tab.id) {
          <pressable
            class="tab"
            [testID]="'tab-' + tab.id"
            accessibilityRole="button"
            [accessibilityState]="{ selected: active() === tab.id }"
            [accessibilityLabel]="tab.label"
            (press)="select.emit(tab.id)"
          >
            <text class="label" [class.active]="active() === tab.id">{{ tab.label }}</text>
          </pressable>
        }
      </view>
    </view>
  `,
  styles: `
    .bar {
      background-color: var(--surface);
    }
    .line {
      height: 1px;
      background-color: var(--separator);
    }
    .row {
      height: 56px;
      flex-direction: row;
    }
    .tab {
      flex: 1;
      align-items: center;
      justify-content: center;
    }
    .label {
      font-size: 15px;
      font-weight: 500;
      color: var(--text-tertiary);
    }
    .active {
      font-weight: 600;
      color: var(--accent);
    }
  `,
})
export class TabBar {
  protected readonly safeArea = inject(SafeArea);
  protected readonly tabs = TABS;
  readonly active = input.required<Tab>();
  readonly select = output<Tab>();
}
