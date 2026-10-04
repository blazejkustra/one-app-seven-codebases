# Markdown Notes — Android build (Kotlin Multiplatform + Compose Multiplatform)

Application id `com.mdnotes.kmp`, app name `Markdown Notes`, minSdk 26, target/compile SDK 37.
Same `shared` module as iOS; `androidApp/` is a thin host (one `MainActivity`).

## Build the release APK from a clean checkout

Requirements: JDK 17, Android SDK with **platform `android-37.0`** (compose 1.12 requires
compileSdk 37) and build-tools 36+. Everything else (Gradle 9.8.0, AGP 9.1.1, Maven deps) is
downloaded by the wrapper and pinned by the `gradle.lockfile` files.

All commands are run from the `kmp/` directory.

```sh
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
export ANDROID_HOME="$HOME/Library/Android/sdk"

# one-time: SDK platform 37 (skip if already installed)
yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" "platforms;android-37.0" "build-tools;36.0.0"

./gradlew --no-daemon :androidApp:assembleRelease
echo "$PWD/androidApp/build/outputs/apk/release/androidApp-release.apk"
```

Install and run (release build, Kotlin compiled into the APK, no dev server):

```sh
"$ANDROID_HOME/platform-tools/adb" -s emulator-5554 install -r androidApp/build/outputs/apk/release/androidApp-release.apk
"$ANDROID_HOME/platform-tools/adb" -s emulator-5554 shell am start -n com.mdnotes.kmp/com.mdnotes.kmp.android.MainActivity
```

The release build type is signed with the local **debug keystore** (`~/.android/debug.keystore`,
created by AGP automatically) so the APK installs; swap in a real `signingConfig` for store builds.
R8/minify is off.

The iOS build (`BUILD.md`) is unchanged and does **not** need the Android SDK: Xcode's
`embedAndSignAppleFrameworkForXcode` phase still works without `ANDROID_HOME` (verified with
`env -u ANDROID_HOME ./gradlew --no-daemon :shared:linkReleaseFrameworkIosSimulatorArm64`).
After changing dependency versions, refresh locks with
`./gradlew resolveAndLockAll --write-locks --no-configuration-cache` (needs `ANDROID_HOME`).

## Report

**Out of the box:** there was no Android target at all — `shared` only declared `iosArm64` /
`iosSimulatorArm64`, and three `expect` declarations (`applyInterfaceStyle`, `shareText`,
`MonoFontFamily`) only had iOS actuals. So: did not build, nothing to run. The common code
itself (UI, SQLDelight schema/repository, markdown via `org.jetbrains:markdown`,
kotlinx-datetime) compiled for Android unchanged, and once wired up every feature worked on the
first run except system Back (see below).

**What was added / changed**

| File | Why |
|---|---|
| `gradle/libs.versions.toml` | AGP 9.1.1 plugins (`com.android.application`, `com.android.kotlin.multiplatform.library`), `sqldelight android-driver`, `androidx.activity:activity-compose` |
| `build.gradle.kts`, `settings.gradle.kts`, `gradle.properties` | register the Android plugins, include `:androidApp`, `android.useAndroidX=true` |
| `shared/build.gradle.kts` | `android { namespace, compileSdk = 37, minSdk = 26 }` target (AGP 9's KMP library plugin) + androidMain deps |
| `*gradle.lockfile` (new `androidApp/gradle.lockfile`, updated `shared/`, root ones) | dependency locking is on for all configurations |
| `shared/src/androidMain/.../MainActivityContent.kt` | Android counterpart of `MainViewController()`: edge-to-edge, `AndroidSqliteDriver("notes.db")`, `setContent { App(repo) }`; sets `testTagsAsResourceId` so the spec's identifiers (`note-card`, `tab-notes`…) appear as Android resource-ids |
| `shared/src/androidMain/.../ui/{AndroidHost,Share.android,InterfaceStyle.android,MonoFont.android,BackHandler.android}.kt` | actuals: share = `ACTION_SEND` text/plain chooser (Android share sheet); appearance = light/dark status- and nav-bar icons; mono font = `FontFamily.Monospace`; system Back |
| `shared/src/commonMain/.../ui/Theme.kt` + `iosMain/.../ui/BackHandler.ios.kt` | new `expect fun PlatformBackHandler` (no-op on iOS) |
| `shared/src/commonMain/.../ui/EditorScreen.kt` | Android Back in the editor behaves like `‹ Notes` (saves, deletes a blank note, returns to the tab). Without it Back closed the activity |
| `shared/src/commonMain/.../ui/App.kt` | `applyInterfaceStyle` re-runs when the resolved theme changes (keyed on `dark` too), so status-bar icons follow a live system dark-mode switch in `System` mode |
| `androidApp/` (new) | `build.gradle.kts`, `AndroidManifest.xml` (label, portrait, `adjustResize`, `configChanges` incl. `uiMode` so a theme flip doesn't recreate the activity and lose navigation state), `MainActivity.kt`, NoActionBar theme with `bg` window colour (light/night), launcher icon resized from the iOS icon |

**Verified on emulator-5554 (Pixel 5, Android 15), release APK:** seed notes and Notes screen match
`reference-final/01-notes.png` (layout, colours, chips, cards, tab bar above the gesture bar);
search (live, case-insensitive); tag filter; Preview rendering of the welcome note (headings,
bold/italic, inline code, lists, quote, code block, tags) matches `02-editor-preview.png`;
Edit mode without keyboard, tapping focuses; edit + killing the app immediately → change kept
after relaunch; `+` opens a new note in Edit with the cursor focused and the editor card shrinking
above the soft keyboard; checklist toggle (card shows `3/4 done`, date updated); star toggle;
Delete → toast above the tab bar → Undo restores the note in place; sort Updated/Title; snippets
switch; Appearance System/Light/Dark (Dark matches the dark tokens, status-bar icons switch, System
follows `cmd uimode night yes/no` live); settings persisted across relaunch; Reset sample notes;
Starred tab; Share opens Android's share sheet with the raw markdown and Back returns to the
unchanged editor; Back from the editor returns to the list.

iOS: `xcodebuild … -configuration Release -sdk iphonesimulator` from `BUILD.md` → **BUILD SUCCEEDED**
after all changes (not re-run on a simulator; the only common-code changes are the no-op back
handler on iOS and an extra `LaunchedEffect` key).

**Still different / not done on Android**

* Fonts: Roboto instead of SF Pro, and the platform monospace (Droid Sans Mono) instead of Menlo —
  neither ships on Android; not bundled, so text metrics differ slightly from the PNGs.
* Safe areas are the device's (24 dp status bar, gesture-nav inset), not the iPhone's 62/34 pt.
* The soft-keyboard theme can't be forced by the app on Android; it follows the system theme, so
  in app-forced Dark with a light system the keyboard stays light.
* Task accessibility value: the `checked`/`unchecked` state is exposed as `stateDescription`, which
  Android tooling shows less prominently than iOS `accessibilityValue`.
* While testing with argent, the accessibility tree reported by its on-device helper sometimes went
  stale (kept showing a previous screen) until the helper was restarted. Not isolated whether that
  is the tooling or Compose not emitting content-change events to UiAutomation clients; worth
  checking if automated tests drive the Android build through the identifiers.
* Hardware Back on the tab screens exits the app (standard Android behaviour); no release signing
  key / R8 configuration.
