# Markdown Notes — Kotlin Multiplatform + Compose Multiplatform (iOS)

Bundle id `com.mdnotes.kmp`, display name `Markdown Notes`.

Requirements: macOS with Xcode 26.x (iOS 26 SDK), JDK 17, network access for the first run.
Everything else (Gradle 9.8.0 via the wrapper, Kotlin/Native toolchain, Maven dependencies)
is downloaded automatically. Dependency versions live in `gradle/libs.versions.toml` and are
locked in `gradle.lockfile` files (`shared/gradle.lockfile`, `buildscript-gradle.lockfile`,
`settings-gradle.lockfile`).

All commands are run from the `kmp/` directory.

## (a) Install dependencies

```sh
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
./gradlew --no-daemon :shared:compileKotlinIosSimulatorArm64 :shared:compileKotlinIosArm64
```

This downloads Gradle, the Kotlin/Native toolchain and all locked libraries (Compose
Multiplatform, SQLDelight, org.jetbrains:markdown, kotlinx-datetime).
No CocoaPods / SPM step is needed: Xcode calls Gradle (`embedAndSignAppleFrameworkForXcode`)
to build and embed the `Shared` framework.

## (b) Release `.app` for the iOS Simulator

```sh
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
xcodebuild -project iosApp/iosApp.xcodeproj -scheme iosApp -configuration Release \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/ios build
echo "$PWD/build/ios/Build/Products/Release-iphonesimulator/Markdown Notes.app"
```

Install and run it on a booted simulator:

```sh
xcrun simctl install <UDID> "build/ios/Build/Products/Release-iphonesimulator/Markdown Notes.app"
xcrun simctl launch <UDID> com.mdnotes.kmp
```

## (c) Release `.app` for a generic iOS device (no code signing)

```sh
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
xcodebuild -project iosApp/iosApp.xcodeproj -scheme iosApp -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build/ios CODE_SIGNING_ALLOWED=NO build
echo "$PWD/build/ios/Build/Products/Release-iphoneos/Markdown Notes.app"
```

## Notes

* The app is fully self-contained: the Kotlin code is compiled ahead of time into the static
  `Shared` framework linked into the app binary. No dev server is involved.
* Simulator builds are arm64 only (`x86_64` is excluded), i.e. Apple Silicon Macs.
* Refresh the lockfiles after changing versions:
  `./gradlew resolveAndLockAll --write-locks --no-configuration-cache`.

## Project layout

```
shared/src/commonMain/kotlin/com/mdnotes/kmp/
  data/       Note model, NotesRepository (SQLite via SQLDelight), seed notes, title/snippet/date
  markdown/   MarkdownParser (org.jetbrains:markdown AST -> block/inline model)
  ui/         Compose UI: App (navigation), tab screens, editor, markdown renderer, components, theme
shared/src/commonMain/sqldelight/  Notes.sq (note + setting tables)
shared/src/iosMain/                MainViewController (SQLite driver), Menlo font lookup
iosApp/                            Xcode project (SwiftUI host embedding the Compose view controller)
```
