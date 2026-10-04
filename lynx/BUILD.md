# Building Markdown Notes (Lynx)

The app is a ReactLynx bundle (`src/`, built with Rspeedy) embedded in a native
iOS host app (`ios/`, Lynx SDK 4.1.0 via CocoaPods). `npm run build` produces
`dist/main.lynx.bundle` and the Xcode build copies it into the `.app`, so the Release app runs without any dev server.

Prerequisites: Node.js >= 22.12 (or 20.19+), npm, CocoaPods >= 1.16, Xcode 26.
All commands are run from the `lynx/` directory.

## (a) Install dependencies

```sh
npm ci
(cd ios && pod install)
```

## (b) Release build for the iOS Simulator

```sh
npm run build \
&& xcodebuild -workspace ios/MarkdownNotes.xcworkspace -scheme MarkdownNotes \
  -configuration Release -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath ios/build build -quiet \
&& echo "$PWD/ios/build/Build/Products/Release-iphonesimulator/MarkdownNotes.app"
```

Install/run (optional): `xcrun simctl install <UDID> <printed path> && xcrun simctl launch <UDID> com.mdnotes.lynx`

## (c) Release build for a generic iOS device (no code signing)

```sh
npm run build \
&& xcodebuild -workspace ios/MarkdownNotes.xcworkspace -scheme MarkdownNotes \
  -configuration Release -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath ios/build build -quiet \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
&& echo "$PWD/ios/build/Build/Products/Release-iphoneos/MarkdownNotes.app"
```

## Other

- `npm test` runs unit tests for the note helpers (Rstest).
- `ios/project.yml` is the XcodeGen spec the checked-in `MarkdownNotes.xcodeproj` was generated from
  (`cd ios && xcodegen generate && pod install` regenerates it; not needed for a normal build).
- Dev server (optional, not used by Release builds): `npm run dev` (port 3005).
