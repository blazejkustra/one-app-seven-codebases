import { Component, computed, inject } from '@angular/core';
import { Pressable, ScrollView, Text, View } from '@ng-native/components';
import { NotesStore } from '../data/notes-store.ts';
import { ScreenHeader } from '../ui/screen-header.ts';
import { ToggleSwitch } from '../ui/toggle-switch.ts';

@Component({
  selector: 'app-settings-screen',
  imports: [Pressable, ScreenHeader, ScrollView, Text, ToggleSwitch, View],
  host: { style: 'flex: 1' },
  template: `
    <app-screen-header title="Settings" />
    <scroll-view class="scroll" [contentContainerStyle]="{ paddingTop: 12, paddingHorizontal: 16, paddingBottom: 16 }">
      <view class="group">
        <pressable testID="sort-row" accessibilityRole="button" class="row" (press)="store.toggleSortOrder()">
          <text class="label">Sort by</text>
          <text class="value">{{ store.sortOrder() === 'title' ? 'Title' : 'Updated' }}</text>
        </pressable>
        <view class="separator"></view>
        <view class="row">
          <text class="label">Show snippets</text>
          <app-toggle-switch
            testID="snippets-switch"
            label="Show snippets"
            [checked]="store.showSnippets()"
            (toggle)="store.toggleSnippets()"
          />
        </view>
        <view class="separator"></view>
        <pressable testID="appearance-row" accessibilityRole="button" class="row" (press)="store.cycleAppearance()">
          <text class="label">Appearance</text>
          <text class="value">{{ appearanceLabel() }}</text>
        </pressable>
        <view class="separator"></view>
        <view class="row">
          <text class="label">Notes</text>
          <text testID="notes-count" class="count">{{ store.count() }}</text>
        </view>
      </view>

      <view class="group second">
        <pressable testID="reset-button" accessibilityRole="button" class="row center" (press)="store.resetSamples()">
          <text class="danger">Reset sample notes</text>
        </pressable>
      </view>

      <text class="footer">Markdown Notes · v1.0</text>
    </scroll-view>
  `,
  styles: `
    .scroll {
      flex: 1;
    }
    .group {
      background-color: var(--surface);
      border-radius: 14px;
      overflow: hidden;
    }
    .second {
      margin-top: 24px;
    }
    .row {
      height: 52px;
      padding-left: 16px;
      padding-right: 16px;
      flex-direction: row;
      align-items: center;
      justify-content: space-between;
    }
    .center {
      justify-content: center;
    }
    .separator {
      height: 1px;
      margin-left: 16px;
      background-color: var(--separator);
    }
    .label {
      font-size: 17px;
      color: var(--text);
    }
    .value {
      font-size: 17px;
      color: var(--accent);
    }
    .count {
      font-size: 17px;
      color: var(--text-tertiary);
    }
    .danger {
      font-size: 17px;
      color: var(--danger);
    }
    .footer {
      margin-top: 16px;
      font-size: 13px;
      color: var(--text-tertiary);
      text-align: center;
    }
  `,
})
export class SettingsScreen {
  protected readonly store = inject(NotesStore);
  protected readonly appearanceLabel = computed(() => {
    const a = this.store.appearance();
    return a === 'light' ? 'Light' : a === 'dark' ? 'Dark' : 'System';
  });
}
