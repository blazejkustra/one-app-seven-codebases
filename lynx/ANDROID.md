# Markdown Notes on Android (Lynx)

The same ReactLynx bundle (`src/` → `dist/main.lynx.bundle`) runs on Android inside a
native host app in `android/` (Kotlin, Lynx SDK 4.1.0 / PrimJS 4.1.1 from Maven Central,
XElement for `<input>`/`<textarea>`, SQLite via `androidx.sqlite`).
Application id `com.mdnotes.lynx`, app name `Markdown Notes`, minSdk 24, target/compile SDK 35.

## Build the release APK from a clean checkout

Prerequisites: Node.js >= 22.12 (or 20.19+), npm, JDK 17, Android SDK with platform 35
(the Gradle wrapper downloads Gradle 9.3.1; AGP 9.1.1 and all Maven deps are fetched on first build).

```sh
cd lynx
export ANDROID_HOME=~/Library/Android/sdk
export JAVA_HOME=$(/usr/libexec/java_home -v 17)

npm ci
npm run build                      # -> dist/main.lynx.bundle (production, no dev server)
(cd android && ./gradlew :app:assembleRelease)
# APK: android/app/build/outputs/apk/release/app-release.apk
```

The Gradle `preBuild` step copies `../dist/main.lynx.bundle` into the APK assets and fails with
a clear message if `npm run build` was not run first.

Install and launch:

```sh
$ANDROID_HOME/platform-tools/adb -s emulator-5554 install -r android/app/build/outputs/apk/release/app-release.apk
$ANDROID_HOME/platform-tools/adb -s emulator-5554 shell am start -n com.mdnotes.lynx/.MainActivity
```

The release build is signed with the local debug keystore (there is no release keystore in the
repo) and R8 minification is off. For a store build, add a real `signingConfig` and, if you enable
minification, the Lynx ProGuard rules from the Lynx integration guide.

## Report

Verified on the `emulator-5554` Pixel 5 emulator (Android 15, API 35) with argent, release APK only.
The iOS Release simulator build from `BUILD.md` was re-run afterwards. It still builds, and the
resulting app was launched on an iOS 26.5 simulator: the list, the preview and the editor work as before.

### What worked out of the box

There was **no Android project**: the repo only had the iOS host (`ios/`), so nothing could be
built or run until a host app existed. Once a minimal host was written (a LynxView plus Kotlin ports
of the three native modules), the unchanged JS bundle rendered on the first launch: the Notes list,
tag chips, cards, tab bar, Settings and Starred matched the reference layout. These also worked
without JS changes: SQLite persistence through synchronous native-module return values (settings,
edits, stars and checklist state survive `am force-stop`), search, the empty state, the tag filter,
sort, the snippets switch, Appearance System/Light/Dark (including following the OS theme live),
keyboard avoidance in the editor (Lynx emits `keyboardstatuschanged` on Android too), new note with
the keyboard up, delete + toast + undo, and the Share sheet.

Out of the box, these were **broken**:

1. **Opening any note did nothing.** PrimJS on Android lacks `Array.prototype.at` (and
   `Object.hasOwn`), which `marked` uses. The lexer threw, so the editor never rendered.
2. **Menlo doesn't exist on Android**, so code blocks and the editor fell back to the proportional
   system font.
3. **The editor line height was wrong.** Android XElement's `<textarea>` ignores CSS `line-height`
   (its setter is a no-op), so lines were about 17.6dp apart instead of 22.
4. **System Back from the editor left the app** instead of going back to the list.

### What I added or changed

Android host (new, `android/`):
- `settings.gradle.kts`, `build.gradle.kts`, `app/build.gradle.kts`, `gradle.properties`, Gradle
  wrapper, `.gitignore`. These set up the dependencies, the bundle-copy task and debug-key release
  signing. They also pin `androidx.vectordrawable` 1.2.0: Lynx pulls 1.0.0, which AGP 9 rejects for
  duplicate namespaces.
- `AndroidManifest.xml` plus light/night `themes.xml`/`colors.xml`: NoActionBar theme, portrait,
  `adjustNothing` (the JS does its own keyboard avoidance), and `configChanges` so a dark-mode flip
  doesn't recreate the activity.
- `MainApplication.kt`: Lynx init. It also registers `Menlo` as an alias for Android's monospace
  typeface (`TypefaceCache.cacheTypeface`), so the shared `font-family: Menlo` works unchanged (fix 2).
- `MainActivity.kt`: hosts the LynxView edge-to-edge. It passes the real system-bar insets in dp as
  `safeAreaTop`/`safeAreaBottom` global props (about 49dp top / 24dp bottom on this Pixel 5, instead of iOS's 62/34),
  delaying the first render until insets are known. It also sends `systemColorSchemeChanged`, sets
  the status/nav-bar icon colour for the active theme, and forwards Back to JS while the editor is
  open (fix 4).
- `AssetTemplateProvider.kt`: loads the bundle from APK assets.
- `NotesDatabase.kt` + `NotesStoreModule.kt`: same SQLite schema and the same synchronous JS API
  as iOS.
- `AppearanceModule.kt`, `ShareModule.kt` (`ACTION_SEND` chooser), `BackHandlerModule.kt`.

Shared JS (small; iOS behaviour unchanged):
- `src/polyfills.ts` (new), imported first in `src/index.tsx`: guarded `Array/String.prototype.at`
  and `Object.hasOwn`. On iOS they are no-ops (fix 1).
- `src/App.tsx`, `src/typing.d.ts`: report editor open/closed to the optional
  `NativeModules.BackHandler` (absent on iOS) and close the editor on `androidBackPressed` (fix 4).
- `src/theme.ts` (`IS_ANDROID`) and `src/screens/EditorScreen.tsx`: on Android only, pass
  `line-spacing: 4.4px` to the textarea so lines are ~22dp apart. iOS also honours `line-spacing`,
  so it is not passed there (fix 3).

### Still not working / differences on Android

- **No `resource-id` for the spec's test identifiers.** Lynx Android has no equivalent of
  `ios-platform-accessibility-id` that reaches uiautomator. Elements are exposed by their
  `accessibility-label` (content-desc) only, so Android UI tests must select by label or text.
- **The keyboard follows the OS theme, not the in-app setting.** With Appearance set to Dark while
  the OS is light, the keyboard stays light. Android has no per-app IME theme API.
- **The settings row labels can be stale for accessibility.** After toggling Sort, the content-desc
  sometimes keeps the old value (e.g. "Sort by, Updated") although the screen shows "Title".
- **Visual differences that come from the platform:** Roboto instead of SF Pro, Android
  monospace instead of Menlo, the real Android status/navigation-bar insets, and the system accent
  colour on the text-selection handles.
- **Editor line height is approximate:** the `4.4px` offset is tuned for the default monospace
  font at 15px.
