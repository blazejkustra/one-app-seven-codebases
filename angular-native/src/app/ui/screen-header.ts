import { Component, input } from '@angular/core';
import { Text, View } from '@ng-native/components';

/** Large left-aligned tab title; anything projected sits on the right. */
@Component({
  selector: 'app-screen-header',
  imports: [Text, View],
  template: `
    <view class="header">
      <text class="title" accessibilityRole="header">{{ title() }}</text>
      <ng-content />
    </view>
  `,
  styles: `
    .header {
      height: 52px;
      padding-left: 20px;
      padding-right: 20px;
      flex-direction: row;
      align-items: center;
      justify-content: space-between;
    }
    .title {
      font-size: 34px;
      line-height: 41px;
      font-weight: 700;
      color: var(--text);
    }
  `,
})
export class ScreenHeader {
  readonly title = input.required<string>();
}
