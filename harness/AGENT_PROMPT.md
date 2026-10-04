# Build-agent prompt (identical for every framework; only the `{…}` slots change)

You are building an iOS app with **{FRAMEWORK}**.

Repository root: `<repo root>`
Your directory: `{DIR}/` — create and modify files **only** inside it.

1. Read `spec/SPEC.md` and look at every PNG in `spec/reference/`. They describe
   the app completely. Do **not** read anything else in the repository (other
   implementations, `harness/`, `results/`). Section 7 (real-world requirements) is
   mandatory.
2. {SCAFFOLD}
   Use current stable versions of everything.
3. Bundle identifier `com.mdnotes.{ID}`, display name `Markdown Notes`.
4. Use **only** the simulator with UDID `{UDID}` (an iPhone 17 Pro on iOS 26.5).
   Boot it if needed. Never touch other simulators. Run, inspect and verify the
   app with the argent MCP tools (screenshots, taps, describe).
5. Make the screens match the reference PNGs as closely as you can and verify the
   behaviours in the spec (persistence, search, sort, star, new/empty note,
   reset, accessibility identifiers).
6. The finished app must run from a **Release** build with everything embedded
   (no dev server / Metro / hot-reload host needed).
7. Write `{DIR}/BUILD.md` with exact, non-interactive commands that work from a
   clean checkout: (a) install dependencies, (b) build a Release `.app` for the
   iOS **simulator** and print its path, (c) build Release for a generic iOS
   **device** without code signing (`CODE_SIGNING_ALLOWED=NO` or the framework's
   `--no-codesign` equivalent) and print the `.app` path. Run them to confirm.
8. Stop any dev servers you started. Don't commit to git. Don't ask questions —
   make reasonable decisions and keep going until it is done.

Reply with a short summary: what you built, known gaps or deviations, and the
BUILD.md commands.

## The filled-in slots

Common to all: `{DIR}` = the framework folder, `{ID}` = `swift`, `reactnative`, `flutter`, `kmp`,
`angularnative`, `lynx`, `{UDID}` = that framework's own simulator (`results/simulators.txt`).
The JS-based stacks were also given a dev-server port so their dev servers would never collide
(React Native 8082, Angular Native 8083, Lynx 3005).

| Framework | `{SCAFFOLD}` line (summarised) |
|---|---|
| Swift | Use SwiftUI in a native Xcode project. You may generate the project with `xcodegen` (installed) or write it by hand. |
| React Native | Use React Native via Expo: `npx create-expo-app@latest` (then build the native iOS project with `npx expo prebuild` / `npx expo run:ios`). |
| Flutter | Use Flutter: start with `flutter create` (Flutter 3.47 is installed via Homebrew). |
| Compose Multiplatform | Use Kotlin Multiplatform with a shared Compose Multiplatform UI. Start from the official JetBrains template (the KMP wizard at kmp.jetbrains.com or JetBrains' official Compose Multiplatform template on GitHub). The iOS app is the Xcode project that embeds the shared Kotlin framework. JDK 17 is installed. |
| Angular Native | Use Angular Native: start with `npx create-expo-app@latest <name> --template @ng-native/template` (docs: https://angular-native.com/guide/getting-started). |
| Kotlin (native Android, added later) | Use Kotlin with Jetpack Compose in a native Android Gradle project (create it yourself). Same prompt otherwise, with the Android emulator instead of a simulator, `BUILD.md` asking for a release APK, and "adapt only what Android requires, such as system-bar insets and fonts". |
| Lynx | Use Lynx: create the Lynx app with `npm create rspeedy@latest`, and ship it as a standalone iOS app by embedding the built bundle in a native iOS host app that integrates the Lynx SDK via CocoaPods (see lynxjs.org "Integrate with Existing Apps" for iOS; check the Lynx Specs repo for the latest released SDK versions rather than copying versions from the docs). |

Lynx has no official standalone-app template for iOS (its quick start runs bundles inside the
LynxExplorer sandbox app), so its agent also had to create the native host app.
