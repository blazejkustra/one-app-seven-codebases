# Markdown Notes (Flutter) - build

Requirements: Flutter 3.47 (stable) on PATH, Xcode 26 with the iOS 26.5 simulator runtime.
Dependencies are resolved by pub and locked in `pubspec.lock`; the native plugins
(`sqflite_darwin`, `share_plus`) are pulled in through Flutter's Swift Package Manager integration, so
there is no CocoaPods step. All commands run from this `flutter/` directory and are
non-interactive.

## (a) Install dependencies

```sh
flutter pub get --enforce-lockfile
```

## (b) Simulator `.app`

```sh
flutter build ios --simulator --debug
echo "$(pwd)/build/ios/iphonesimulator/Runner.app"
```

Flutter cannot build Release (or Profile) for the iOS simulator: there is no AOT
runtime for simulator targets, and both `flutter build ios --simulator --release` and an
`xcodebuild -configuration Release -sdk iphonesimulator` build fail with
"release/profile builds are only supported for physical devices". The `--debug`
simulator build is still self-contained: the Dart kernel snapshot and all assets are
embedded in `Runner.app/Frameworks/App.framework`, so the app launches from the home
screen without `flutter run`, a dev server or a hot-reload host. Install and launch it
like this:

```sh
xcrun simctl install <UDID> build/ios/iphonesimulator/Runner.app
xcrun simctl launch <UDID> com.mdnotes.flutter
```

## (c) Release `.app` for a generic iOS device (no code signing)

```sh
flutter build ios --release --no-codesign
echo "$(pwd)/build/ios/iphoneos/Runner.app"
```

This is a real Release build: Dart is AOT-compiled into `App.framework`.
