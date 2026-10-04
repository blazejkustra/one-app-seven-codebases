# Markdown Notes on Android (Angular Native)

Same codebase as iOS (`src/` is shared); only `app.json` and three small source edits were needed.

## Build the release APK from a clean checkout

Requirements: Node.js 22, JDK 17, Android SDK with the platform, build tools and NDK versions the generated Gradle project asks for (Gradle/sdkmanager can install them).
All commands run from `angular-native/` and are non-interactive.

```sh
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export ANDROID_HOME=~/Library/Android/sdk

npm ci
CI=1 npx expo prebuild --platform android --clean --no-install   # generates android/ (git-ignored)
(cd android && ./gradlew :app:assembleRelease)
echo "$PWD/android/app/build/outputs/apk/release/app-release.apk"
```

* Release variant: Hermes bytecode bundle embedded in the APK (`assets/index.android.bundle`), no
  Metro / dev server. It is signed with the template's debug keystore, which is fine for an emulator
  or sideloading; a Play upload needs a real keystore in `android/app/build.gradle`.
* Faster local build (one ABI, e.g. an Apple-silicon emulator):
  `(cd android && ./gradlew :app:assembleRelease -PreactNativeArchitectures=arm64-v8a)`.
* Install and run:
  `adb -s emulator-5554 install -r android/app/build/outputs/apk/release/app-release.apk && adb -s emulator-5554 shell am start -n com.mdnotes.angularnative/.MainActivity`

Application id `com.mdnotes.angularnative`, label `Markdown Notes`.

## Report

Verified on `emulator-5554` (Pixel 5, Android 15 / API 35) with the release APK, driven through
argent; iOS Release simulator build re-run afterwards per `BUILD.md`.

### Worked out of the box

After only adding `android` to `app.json` (`platforms` + `android.package`), prebuild and
`assembleRelease` succeeded first try and the app ran. Working with the unmodified `src/`:
seed notes on first launch, Notes / Starred / Settings tabs, search (live), tag filter row (and
combined with search, `No notes found`), note cards (snippets, chips, `2/4 done`, star),
preview rendering, Edit/Preview switch (no keyboard on Edit for existing notes), editing with
auto-save and `updatedAt` bump, persistence after force-stop + relaunch (expo-sqlite), new note
(Edit mode, input focused, keyboard up), checklist toggle (rewrites body, saved), star toggle,
Delete + toast + Undo (restored in original position), sort toggle, snippets switch, Appearance
System/Light/Dark incl. following the Android system dark mode live, status-bar icon colour per
theme, Reset sample notes, Android share sheet with the raw markdown (dismiss returns unchanged).
System-bar insets were already right: the app is edge-to-edge on Android 15 and the existing
`<safe-area-view>` / `SafeArea` insets put the header below the status bar and the tab bar /
toast above the gesture bar. All `testID`s surface as Android `resource-id`s.

### What had to change

| File | Change | Why |
|---|---|---|
| `app.json` | `platforms: ["ios","android"]`, `android.package: com.mdnotes.angularnative` | Android was not enabled; prebuild needs the package name. |
| `src/main.ts` | Android-only `--mono: monospace` token; provides `KEYBOARD_EXCLUDES_BOTTOM_INSET` (true on Android) | Menlo does not exist on Android, so code blocks, inline code and the editor fell back to the proportional system font. |
| `src/app/markdown/markdown-view.ts`, `src/app/screens/editor-screen.ts` | `font-family: var(--mono, Menlo)` | iOS keeps Menlo via the fallback; Android picks up `monospace`. |
| `src/app/platform.ts` (new), `src/app/screens/editor-screen.ts` | Editor card bottom = keyboard height + bottom inset + 16 on Android | React Native's Android keyboard event reports the IME height *minus* the navigation bar, but the edge-to-edge app draws behind that bar, so the edit card ran ~24 pt under the keyboard with no 16 pt gap. |
| `src/app/app.ts` | `HardwareBack` handler: closes the editor (same path as `‹ Notes`, incl. empty-note deletion); otherwise not consumed | Out of the box the Android back button/gesture did nothing at all (nothing loaded RN's `BackHandler`, so the native back event was never answered). Now back leaves the editor, and on a tab it backgrounds the app as usual. |

`npm test` and `npm run typecheck` pass. iOS behaviour is unchanged (token undefined -> Menlo;
injection token defaults to false).

### Still different / not done on Android

* Fonts: Roboto instead of SF Pro (the spec's "system font"), so line breaks and widths differ
  slightly from the iOS reference PNGs; monospace is Droid Sans Mono rather than Menlo.
* Keyboard appearance: the on-screen keyboard (Gboard) follows the *system* theme, not the
  app's Appearance override (iOS `keyboardAppearance` has no Android equivalent). With
  Appearance = Dark on a light system, the keyboard stays light.
* Keyboard avoidance happens when the IME has finished animating (Android only emits
  `keyboardDidShow`), so the edit card resizes after, not with, the keyboard.
* Text cursor / selection handles use the Android default accent colour, not `accent`.
* The toast container's `toast` testID is not exposed as its own node by uiautomator (its
  children `Note deleted` and `undo-button` are).
* Release APK is signed with the debug keystore (see above).
