# Markdown Notes (Flutter) - Android

Same codebase as iOS (`lib/` is shared 100%); Android adds only the `android/` host project.

## Build the release APK from a clean checkout

Requirements: Flutter 3.47 (stable) on PATH, Android SDK with platform 36 (the NDK
version Flutter pins is downloaded automatically on first build), JDK 17.

```sh
cd flutter
export ANDROID_HOME="$HOME/Library/Android/sdk"
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
flutter pub get --enforce-lockfile
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk  (com.mdnotes.flutter, "Markdown Notes")
```

`android/local.properties`, `gradlew` and `gradle-wrapper.jar` are git-ignored; `flutter build`
regenerates them. Install on a device/emulator:

```sh
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk
adb -s emulator-5554 shell am start -n com.mdnotes.flutter/.MainActivity
```

This is a real Release build (Dart AOT-compiled into `libapp.so`, assets embedded, no dev server).
It is signed with the debug keystore (Flutter template default) so it installs anywhere; a store
upload needs a real `signingConfig` in `android/app/build.gradle.kts`.

## Report

Verified on `emulator-5554` (Pixel 5, Android 15 / API 35) with the release APK.

### Worked out of the box (only the scaffolding was missing)

Once `android/` existed, the app built and ran on the first try with no Dart changes. Everything
below worked unchanged:

- Layout matches the reference PNGs. Android 15 forces edge-to-edge, and the app already lays out
  from `MediaQuery.viewPadding`, so the status bar and gesture-nav insets were handled with no changes.
- Seed notes, search (live; `No notes found` empty state), tag filter (falls back to `All` when
  the tag disappears), Preview rendering, Edit mode (no keyboard until tapped), autosave, and
  persistence across force-stop/relaunch and across an APK upgrade (`sqflite` on Android).
- New note (Edit mode, keyboard up), the editor resizing above the keyboard (`adjustResize`),
  the checklist toggle (rewrites `[ ]`/`[x]`, updates date and `n/m done`), star toggle, Starred tab.
- Delete, then the toast, then Undo (original id, date and position restored); the toast auto-hides after 4 s.
- Settings: sort toggle, snippets switch, Notes count, Reset sample notes.
- Dark mode: `Light`/`Dark` plus `System`, which follows Android's dark theme live (`uiMode`
  is in `configChanges`, so Flutter gets `didChangePlatformBrightness`). Status-bar icons flip.
- Share: `share_plus` opens the Android share sheet (`Intent.ACTION_SEND`, "Sharing text" preview
  with the raw markdown). Back dismisses it and returns to the editor unchanged.
- Android system Back: first press hides the keyboard, second pops the editor and saves through `PopScope`.
- Semantics identifiers show up as Android resource-ids (`search-input`, `note-card`, `task-0`, ...).

### Added / changed

| File | Why |
|---|---|
| `android/` (new, from `flutter create --platforms=android --org com.mdnotes`) | Gradle host project; the Flutter project had iOS only. |
| `android/app/build.gradle.kts` | `applicationId` / `namespace` set to `com.mdnotes.flutter`. |
| `android/app/src/main/AndroidManifest.xml` | `android:label="Markdown Notes"`. |
| `android/app/src/main/kotlin/com/mdnotes/flutter/MainActivity.kt` | Moved to match the namespace. |
| `lib/ui/tokens.dart` | `mono()` gets `fontFamilyFallback: ['monospace']`. Menlo doesn't exist on Android, so code blocks, inline code and the editor were rendering in proportional Roboto. iOS still resolves Menlo first, so iOS is unaffected. |
| `.metadata`, `analysis_options.yaml` | Updated by `flutter create` (android platform entry, `android/**` analyzer exclude). |

`flutter create` also added a template `test/widget_test.dart` referencing a non-existent `MyApp`;
it was deleted so `flutter test` / `flutter analyze` stay green.

iOS re-checked afterwards: `flutter build ios --simulator --debug` and
`flutter build ios --release --no-codesign` both succeed. `flutter analyze` is clean and `flutter test` passes.

### Still different / not working on Android

- **Fonts**: the SF Pro and Menlo fonts aren't bundled (Apple licensing), so Android renders Roboto and Droid Sans Mono.
  Metrics are close and nothing truncates differently in the seed data, but it is not pixel-identical.
- **Keyboard appearance**: `keyboardAppearance` is iOS-only. Gboard follows the system theme,
  so with Appearance = `Dark` on a light system the keyboard stays light.
- **System Back on a tab screen** exits the app (standard Android behaviour). The spec doesn't define it.
- Release APK is debug-signed (see above). The app isn't minified or split per ABI (47.5 MB universal APK).
