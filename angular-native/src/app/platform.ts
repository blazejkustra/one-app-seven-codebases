import { InjectionToken } from '@angular/core';

/**
 * Whether `Keyboard.height` leaves out the bottom system-bar inset. React Native's Android
 * keyboard event reports the IME height minus the navigation bar, while an edge-to-edge app is
 * drawn behind that bar, so the area the keyboard covers is `height + insets.bottom` there. On
 * iOS the height already reaches the bottom of the screen. Provided from `main.ts`; false in tests.
 */
export const KEYBOARD_EXCLUDES_BOTTOM_INSET = new InjectionToken<boolean>('keyboardExcludesBottomInset', {
  factory: () => false,
});
