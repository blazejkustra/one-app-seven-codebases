# Building Markdown Notes (Angular Native)

Requirements: macOS with Xcode 26+, CocoaPods, Node.js 22 (22.22.3+ recommended by Angular 22; 22.22.1 also works with an engine warning).
All commands run from this directory (`angular-native/`) and are non-interactive.
The `ios/` folder is generated (Expo prebuild) and not checked in; step (b) creates it.

## (a) Install dependencies

```sh
npm ci
```

## (b) Release build for the iOS simulator

```sh
CI=1 npx expo prebuild --platform ios --clean --no-install
(cd ios && pod install)
xcodebuild -workspace ios/MarkdownNotes.xcworkspace -scheme MarkdownNotes \
  -configuration Release -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/sim build -quiet
echo "$PWD/build/sim/Build/Products/Release-iphonesimulator/MarkdownNotes.app"
```

The JS bundle is embedded (`MarkdownNotes.app/main.jsbundle`); no Metro/dev server is needed.
Install and run, e.g.: `xcrun simctl install <UDID> build/sim/Build/Products/Release-iphonesimulator/MarkdownNotes.app && xcrun simctl launch <UDID> com.mdnotes.angularnative`.

## (c) Release build for a generic iOS device (no code signing)

```sh
CI=1 npx expo prebuild --platform ios --clean --no-install
(cd ios && pod install)
xcodebuild -workspace ios/MarkdownNotes.xcworkspace -scheme MarkdownNotes \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build/device CODE_SIGNING_ALLOWED=NO build -quiet
echo "$PWD/build/device/Build/Products/Release-iphoneos/MarkdownNotes.app"
```

## Checks

```sh
npm test          # unit tests (title/snippet/date/sort, markdown model)
npm run typecheck # Angular AOT type check
```
