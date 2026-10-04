# Real-device results: iPhone 16

Measured on 2026-10-03 on an **iPhone 16 (iPhone17,3), iOS 26.6.2 (23G90)**, 128 GB. The same "Markdown Notes" app in six stacks, all built **Release**, signed for the device and installed from an App Store-style thinned `.ipa`.

## Results

| App | First frame, XCT median (min–max) | Responsive, XCT median (min–max) | Time to content, median (window)† | iOS download, thinned | iOS installed, thinned | Android release APK (arm64-only est.) |
|---|---|---|---|---|---|---|
| Swift (SwiftUI) | **176 ms** (168–196) | 184 ms (171–190) | ≤ 552 ms (424–552) | **1.6 MB** | **4.0 MB** | n/a (native Android is `kotlin/`: **1.41 MB** (1.38)) |
| React Native (Expo) | 122 ms* (117–130) | 168 ms* (163–172) | ≤ 550 ms (424–550) | 8.6 MB | 29.0 MB | 28.47 MB (arm64 only, as built) |
| Flutter | 139 ms (129–145) | 167 ms (164–177) | ≤ 592 ms (420–592) | 7.2 MB | 17.2 MB | 47.48 MB (16.95) |
| KMP / Compose MP | 190 ms (178–206) | 206 ms (197–297) | ≤ 552 ms (425–552) | 10.8 MB | 30.0 MB | 7.07 MB (7.04) |
| Angular Native | 122 ms* (116–127) | 140 ms* (116–181) | ≤ 550 ms (424–550) | 9.4 MB | 31.0 MB | 78.36 MB (30.34) |
| Lynx | 131 ms* (123–149) | 164 ms* (157–171) | ≤ 554 ms (420–554) | 4.6 MB | 11.2 MB | 69.40 MB (25.36) |

\* For React Native, Angular Native and Lynx the "first frame" is the native launch screen, and "responsive" fires once the native main thread goes idle, before JS has rendered the list. Neither number is time to content for these stacks.
† The "time to content" column here is a screen-based upper bound that cannot separate the stacks. It is superseded by [time-to-content.md](time-to-content.md), which measures each app from kernel process start with an in-app probe and checks it against on-device screenshots.

**What it means:** five stacks (Swift, React Native, Compose MP, Angular Native, Lynx) have the Notes list on screen about 0.1 s after the process starts. Flutter is the exception: its list appears about 0.45–0.7 s after start, behind its launch screen ([details](time-to-content.md)). App size differs a lot too: Swift downloads at 1.6 MB, Lynx at 4.6 MB, and the other four at 7–11 MB.

## Methods

### Build and install (same for all six)
- `xcodebuild archive -configuration Release -destination generic/platform=iOS`, using each app's own project or workspace from its `BUILD.md`. Signing is passed only on the command line (`DEVELOPMENT_TEAM=$TEAM_ID CODE_SIGN_STYLE=Automatic CODE_SIGN_IDENTITY="Apple Development" -allowProvisioningUpdates`). No project file or source file was edited. Flutter first ran `flutter build ios --release --no-codesign`, which AOT-compiles the Dart code. Lynx first ran `npm run build`. Scripts are in `method/archive.sh` and `method/export.plist`.
- `xcodebuild -exportArchive` with `method=debugging, thinning=iPhone17,3, stripSwiftSymbols=true` gives a `.ipa` thinned for the iPhone 16 and an **App Thinning Size Report**.
- Each app was uninstalled (none were installed beforehand), then the thinned `.ipa` was installed fresh with `xcrun devicectl device install app` immediately before its measurements (`method/measure.sh`).

### Launch time
All tests run from the harness XCUITest runner (`harness/xcui`, built Release and signed for the device). The runner launched the apps one after another under the same conditions: phone idle, 10 s pause before each test, the app terminated before every launch (cold process, OS file caches warm), and 10 measured launches per metric.
- **(a) First frame:** `LaunchPerf/testLaunchMetric`, which is `XCTApplicationLaunchMetric()` measuring process start to first frame. The test does one extra warm-up iteration first, and Xcode discards it.
- **Responsive:** `LaunchPerf/testLaunchToResponsive`, which is `XCTApplicationLaunchMetric(waitUntilResponsive: true)`. Reported for completeness only, because it is not a content metric for the JS stacks.
- **(b) Time to content:** `DeviceLaunch/testTimeToContent` (`method/DeviceLaunch.swift`, added to a scratch copy of the harness; the repo's harness is unchanged).
  - A background thread takes on-device screenshots (`XCUIScreen.main.screenshot()`) as fast as the phone allows. That is about 8 fps, one frame every ≈ 123 ms. Each screenshot is downscaled to 118×256 grayscale.
  - At the same time, the main thread calls `app.launch()`. Capture runs for 4 s.
  - Time to content is the first frame from which the screen stays equal to the settled frame, measured from the moment `launch()` was called. The settled frame is the last one captured, and the test checks it shows `note-card`. Status bar and home-indicator rows are ignored, and frames count as equal when the mean absolute difference is ≤ 1 gray level. This is the same rule as `harness/coldstart_analyze.py`, but computed on the device.
  - One warm-up launch after install is discarded, then 10 launches are measured.
  - The content appeared between the previous capture and the matched one. Both bounds are reported: the "window" in the table is the median lower bound to the median upper bound.
  - Every run of every app ended on the Notes list with the seed notes (`cards=yes`).

### App size
- **iOS:** the "App size" line of the App Thinning Size Report for iPhone17,3. *Compressed* is the download size, and *uncompressed* is the installed size of the app bundle. As a cross-check, the unzipped thinned `.app` bundles were measured with `du`: 3.9 / 28.5 / 16.9 / 29.3 / 30.4 / 11.0 MiB, which matches the report.
- **Android:** file sizes of the release APKs that already existed (1 MB = 10⁶ bytes):
  - `react-native/android/app/build/outputs/apk/release/app-release.apk`: 28,473,887 B, **arm64-v8a only**.
  - `flutter/build/app/outputs/flutter-apk/app-release.apk`: 47,481,855 B, arm64-v8a, armeabi-v7a and x86_64.
  - `kmp/androidApp/build/outputs/apk/release/androidApp-release.apk`: 7,066,245 B, 4 ABIs. Its native libraries are only about 27 KB.
  - `angular-native/android/app/build/outputs/apk/release/app-release.apk`: 78,356,679 B, 4 ABIs.
  - `lynx/android/app/build/outputs/apk/release/app-release.apk`: 69,396,808 B, 4 ABIs.
  - `kotlin/app/build/outputs/apk/release/app-release.apk`: 1,411,477 B, 4 ABIs.

  These are not Play-split APKs. The "arm64-only est." column is the APK size minus the compressed bytes of the other ABIs' `lib/` folders. It is a rough estimate of what an arm64 phone would get from an App Bundle.

## Caveats
- **Time to content hits a floor.** The screen keeps changing until iOS's app-launch zoom animation ends, ≈ 545 ms after `launch()` on this phone. Swift shows this: its content is in its first frame (176 ms), yet its time to content is still ≈ 550 ms. Every stack had its content drawn before that point, so all six are at the floor and the frame method cannot rank them. The sampling resolution is ±60 ms (about 8 fps of on-device screenshots, because no USB video capture was available).
- **Screenshot load.** Screenshot capture during the time-to-content test adds load equally to all six apps. The XCT first-frame and responsive metrics were taken in separate runs without it.
- **Connection.** Builds, installs and tests ran over Xcode's CoreDevice connection to the phone.
- **Not an App Store build.** Export method `debugging` has no FairPlay encryption, so the real App Store download can be slightly larger. Thinning for iPhone17,3 produced a single variant for every app, because none of them has device-specific assets.
