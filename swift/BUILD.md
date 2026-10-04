# Markdown Notes — Swift (SwiftUI)

Native SwiftUI app, bundle id `com.mdnotes.swift`, display name **Markdown Notes**.

* Project: `MarkdownNotes.xcodeproj` (generated from `project.yml` with XcodeGen and committed,
  so XcodeGen is **not** required to build). Regenerate with `xcodegen generate` after editing `project.yml`.
* Dependencies (Swift Package Manager, locked in
  `MarkdownNotes.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`):
  * [GRDB.swift](https://github.com/groue/GRDB.swift) 7.11.1 — SQLite storage (notes + settings tables)
  * [swift-markdown](https://github.com/swiftlang/swift-markdown) 0.9.0 — Markdown (cmark-gfm) parser
* Source layout: `MarkdownNotes/App` (entry, theme), `MarkdownNotes/Data` (model, SQLite, store, seeds),
  `MarkdownNotes/Markdown` (parse → view model, preview renderer), `MarkdownNotes/UI` (screens, controls).

Requirements: macOS with Xcode 26.x (tested with Xcode 26.6, iOS 26.5 simulator SDK).
All commands run from this `swift/` directory.

## (a) Install dependencies

Resolves the Swift packages exactly as pinned in `Package.resolved`:

```sh
xcodebuild -resolvePackageDependencies \
  -project MarkdownNotes.xcodeproj -scheme MarkdownNotes \
  -derivedDataPath build/DerivedData -disableAutomaticPackageResolution
```

## (b) Release build for the iOS Simulator (prints the .app path)

```sh
xcodebuild -project MarkdownNotes.xcodeproj -scheme MarkdownNotes \
  -configuration Release -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData -disableAutomaticPackageResolution -quiet build \
&& echo "$PWD/build/DerivedData/Build/Products/Release-iphonesimulator/MarkdownNotes.app"
```

Install / run on a simulator (optional):

```sh
xcrun simctl install <UDID> build/DerivedData/Build/Products/Release-iphonesimulator/MarkdownNotes.app
xcrun simctl launch <UDID> com.mdnotes.swift
```

## (c) Release build for a generic iOS device, without code signing (prints the .app path)

```sh
xcodebuild -project MarkdownNotes.xcodeproj -scheme MarkdownNotes \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build/DerivedData -disableAutomaticPackageResolution -quiet \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" build \
&& echo "$PWD/build/DerivedData/Build/Products/Release-iphoneos/MarkdownNotes.app"
```

The Release build is fully self-contained (no dev server needed).
