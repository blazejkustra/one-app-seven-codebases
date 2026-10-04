import { Component, input, output } from '@angular/core';
import { Pressable, View } from '@ng-native/components';

/** A custom-drawn 51x31 switch (no UISwitch, per spec). */
@Component({
  selector: 'app-toggle-switch',
  imports: [Pressable, View],
  template: `
    <pressable
      [testID]="testID()"
      accessibilityRole="switch"
      [accessibilityLabel]="label()"
      [accessibilityState]="{ checked: checked() }"
      [accessibilityValue]="{ text: checked() ? '1' : '0' }"
      class="track"
      [class.on]="checked()"
      [hitSlop]="8"
      (press)="toggle.emit()"
    >
      <view class="knob"></view>
    </pressable>
  `,
  styles: `
    .track {
      width: 51px;
      height: 31px;
      border-radius: 15.5px;
      background-color: var(--fill);
      padding: 2px;
      flex-direction: row;
      justify-content: flex-start;
    }
    .on {
      background-color: var(--accent);
      justify-content: flex-end;
    }
    .knob {
      width: 27px;
      height: 27px;
      border-radius: 13.5px;
      background-color: #ffffff;
    }
  `,
})
export class ToggleSwitch {
  readonly checked = input.required<boolean>();
  readonly testID = input<string>();
  readonly label = input<string>();
  readonly toggle = output<void>();
}
