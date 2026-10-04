# Time to content on an iPhone 16: in-app probe

Measured 2026-10-04 on the same **iPhone 16 (iPhone17,3), iOS 26.6.2** as `README.md`. The six apps are the committed Release apps plus a small measurement probe (described below). Each was built Release, signed for the device, exported as an `.ipa` thinned for iPhone17,3 and freshly installed. Raw per-launch values are in `time-to-content.tsv`.

## Results

1 warm-up + 20 cold launches per app; the warm-up is discarded. Values are ms from kernel process start.

| App | Probe: median | IQR (p25–p75) | Range (min–max) | Screenshot check: when the list is first on screen (under screenshot load) |
|---|---|---|---|---|
| Swift (SwiftUI) | **103** | 102–104 | 100–111 | not before probe + 5 ms; the probe agrees |
| React Native (Expo) | **90** | 89–92 | 87–99 | not before probe + **48 ms** |
| Flutter | **99** ‡ | 97–101 | 96–105 | not before probe + **≈ 320 ms**. The list appears ≈ 440–640 ms after start |
| KMP / Compose MP | **116** | 113–122 | 93–146 | no contradiction, but no useful lower bound either |
| Angular Native | **128** | 127–130 | 98–137 | not before probe + 3 ms; the probe agrees |
| Lynx | **109** | 106–114 | 96–120 | not before probe + 14 ms |

‡ **Flutter: do not use 99 ms as time to content.** `addPostFrameCallback` fires when Dart has *built* the first frame with the list. On screen, the white iOS launch screen stays up and the list fades in hundreds of ms later. Both independent checks agree:
- **Screenshots:** in every one of 19 launches the list was not yet on screen ≥ 320 ms after the probe fired.
- **Engine callback:** Flutter's own native first-render callback (`FlutterViewController.setFlutterViewDidRenderCallback`), logged in the same launches without screenshot load, gives a median of **698 ms** (IQR 692–702, range 687–711, n = 10). The Dart hook gave 98 ms in those launches.

So Flutter's real time to content is roughly **0.45–0.7 s**. That is several times the other stacks, not the fastest of them. The callback may fire a little after the pixels appear (it came later than the ≈ 525 ms fade seen in screenshots), so treat 698 ms as an upper estimate.

**How to read the column.** The probe is the framework's own "this frame is done" hook. On screen the list appears later by:
- a few ms for Swift, Angular Native and Lynx (≥ 3–14 ms);
- at least 48 ms for React Native;
- about 0.3–0.6 s for Flutter.

So the probe ranks stacks by when the framework *says* the frame is done, not strictly by pixels. React Native's 90 ms vs Swift's 103 ms does **not** mean React Native shows the list first: in at least one launch, React Native's list was still not on screen 48 ms after its probe fired.

The upper bounds of the screenshot check are loose (list on screen within ≈ 135–180 ms after the probe for the five non-Flutter stacks), so finer differences between those five cannot be resolved this way.

Warm-up launches (the first launch after install) were much slower: Swift 134, React Native 355, Flutter 368, KMP 431, Angular Native 315, Lynx 221 ms. They are in the TSV with `warmup=1`.

## Method

### Probe (identical start, framework-specific end)
- **Start:** kernel process start time, read in native code in each app's iOS host. That is `sysctl({CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()})` → `kp_proc.p_starttime`, which is wall clock.
- **End:** wall-clock epoch ms, read *by the UI framework inside its "list rendered" hook* and passed to native code:
  - JS stacks use `Date.now()`, which reads the same clock as `p_starttime`.
  - Dart uses `DateTime.now()`.
  - Kotlin uses `kotlin.time.Clock.System`.
  - Swift uses `Date()`.
- Native code computes `end − start` and logs `TTC_MS=<ms> start=… end=… hook=…` (NSLog). It also appends the line to `Documents/ttc.log` in the app container, which is pulled with `devicectl device copy from`.
- The hook fires once per process. It only fires on the populated list: every app renders its list component only when there is at least one note, and the empty state is a different component.
- Swift and ObjC versions of the native part are the same 30 lines. They were appended to an existing host file (Swift, Flutter, KMP, Lynx) or added as one `.m` file (React Native, Angular Native). Only throwaway copies were changed; the committed apps are untouched.

### Launches
- Phone unlocked, Auto-Lock off, on the home screen, idle.
- Apps run one after another in the order Swift, React Native, Flutter, KMP, Angular Native, Lynx.
- For each app:
  1. Uninstall, install the thinned `.ipa`, wait 10 s.
  2. Repeat 21 times: `devicectl device process launch` (cold process, OS file caches warm), wait 6 s, `devicectl device process terminate`, wait 3 s on the home screen.
  3. Pull `ttc.log`.
- No XCTest session was running during these launches, so accessibility automation was not enabled in the apps.

### Probe code per framework (only what was added)

Shared native part (Swift; the ObjC module for React Native and Angular Native is the same logic):
```swift
enum TTCProbe {
    static func processStartEpochMs() -> Double {
        var info = kinfo_proc(); var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&mib, u_int(mib.count), &info, &size, nil, 0) == 0 else { return .nan }
        let tv = info.kp_proc.p_un.__p_starttime
        return Double(tv.tv_sec) * 1000 + Double(tv.tv_usec) / 1000
    }
    static func nowEpochMs() -> Double { Date().timeIntervalSince1970 * 1000 }
    static func mark(endEpochMs: Double, hook: String) {
        // once per process: line = "TTC_MS=\(endEpochMs - processStartEpochMs()) …"
        // NSLog(line) and append to Documents/ttc.log
    }
}
```
```objc
// React Native / Angular Native: TTCProbe.m (RCT_EXPORT_MODULE(TTCProbe))
RCT_EXPORT_METHOD(mark:(double)endEpochMs hook:(NSString *)hook) { /* same as TTCProbe.mark */ }
```

**SwiftUI.** The list's `ScrollView`, which exists only when there are notes. The hook runs on the next CADisplayLink tick:
```swift
.onAppear { TTCNextFrame.run { TTCProbe.mark(endEpochMs: TTCProbe.nowEpochMs(), hook: "swiftui-onAppear+displayLink") } }
// TTCNextFrame: one-shot CADisplayLink on the main run loop; runs the closure on its first tick.
```

**React Native.** `src/ui/NoteList.tsx`; the FlatList renders only when `notes.length > 0`:
```tsx
let ttcFired = false;
const onListLayout = () => {
  if (ttcFired) return;
  ttcFired = true;
  requestAnimationFrame(() => NativeModules.TTCProbe?.mark(Date.now(), 'rn-onLayout+rAF'));
};
<FlatList style={styles.list} onLayout={onListLayout} … />
```

**Angular Native.** `src/app/ui/note-list.ts`; the `<scroll-view>` sits in the `@else` branch of `notes().length === 0`:
```ts
<scroll-view class="list" (layout)="onListLayout()" …>
onListLayout(): void {
  if (NoteList.ttcFired) return;
  NoteList.ttcFired = true;
  requestAnimationFrame(() => NativeModules.TTCProbe?.mark(Date.now(), 'angular-native-layout+rAF'));
}
```

**Flutter.** `lib/ui/widgets.dart` `NoteList.build`, after the `notes.isEmpty` early return. A method channel `ttc_probe` in `AppDelegate` calls `TTCProbe.mark`:
```dart
if (!_ttcFired) {
  _ttcFired = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    const MethodChannel('ttc_probe').invokeMethod('mark', {
      'endEpochMs': DateTime.now().microsecondsSinceEpoch / 1000.0,
      'hook': 'flutter-build+addPostFrameCallback',
    });
  });
}
```
Extra Flutter-only check (separate build, 1 + 10 launches) in `SceneDelegate`:
```swift
(window?.rootViewController as? FlutterViewController)?.setFlutterViewDidRenderCallback {
  /* log TTC_RASTER_MS = now − processStart */
}
```

**KMP / Compose Multiplatform.** `TabScreens.kt` `NoteList`, in the non-empty branch after the `LazyColumn`. The Swift host sets `TtcHook.shared.mark = { ms in TTCProbe.mark(endEpochMs: ms.doubleValue, hook: …) }`:
```kotlin
LaunchedEffect(Unit) {
    if (!TtcHook.fired) {
        TtcHook.fired = true
        withFrameNanos { }                       // next frame after the populated list composed
        TtcHook.mark?.invoke(TtcHook.nowEpochMs()) // kotlin.time.Clock.System, epoch ms
    }
}
```

**Lynx.** `src/components/NoteList.tsx`; the `<scroll-view>` renders only when `notes.length > 0`. A Lynx native module `TTCProbe` is registered in `LynxHostViewController`:
```tsx
<scroll-view scroll-orientation='vertical' bindlayoutchange={onListLayout} …>
function onListLayout() {
  if (ttcFired) return;
  ttcFired = true;
  requestAnimationFrame(() => NativeModules.TTCProbe?.mark(Date.now(), 'lynx-bindlayoutchange+rAF'));
}
```

## Cross-check: on-device screenshots

Instruments and 60 fps video were not possible. The phone was reachable only over the network (`devicectl` transport `localNetwork`; no Apple device on the Mac's USB bus), and in that mode:
- `xctrace` lists the phone as offline;
- `devicectl device capture screen-record` reports "Screen Recording not supported";
- AVFoundation/QuickTime capture needs a cable.

So the independent check uses the screen itself, through XCTest screenshots.

### Setup
- An XCUITest only takes screenshots (`XCUIScreen.main.screenshot()`), back to back for the whole session. It stores each frame as 1/4-scale grayscale, with the wall-clock time just before (`a`) and just after (`b`) the call.
- While that runs, the Mac launches and terminates the probed app 20 times with `devicectl`. The screenshot phase relative to process start is therefore random from launch to launch.
- The probe's `start=`/`end=` from the same launch give the origin. This is the same kernel start, but the end is completely independent of the probe.

### Classifier
Each frame is compared with the settled frame 1.3 s after start, scaled about the centre (scale 0.55–1.0), to allow for the launch zoom. It uses the maximum normalised cross-correlation outside the status bar.
- The home screen and launch screens score 0.05–0.2.
- Frames showing the list, including during the zoom or fade, score 0.5–1.0.
- Threshold 0.4. The first frame from which every later frame stays above it is "list visible".

### Bounds
Per launch, the list became visible after `a` of the last frame without the list (−3 ms clock tolerance), and no later than `b` of the first frame with it. A screenshot is taken somewhere inside its own call, so these bounds hold by construction. During a launch the calls stall to roughly 200–300 ms, so each bracket is wide.

The firm per-stack result is the lower bound. It comes from single launches in which a screenshot started at least X ms after the probe fired still showed no list:

| App | Probe median under screenshot load | Screen bracket, per-launch median | List not on screen until at least | Probe ≤ screen upper bound |
|---|---|---|---|---|
| Swift | 182 | 133–420 | probe + 5 ms | 20/20 |
| React Native | 151 | 88–425 | probe + 48 ms | 20/20 |
| Flutter | 152 | 441–637 | probe + 322 ms | 19/19 |
| KMP | 224 | 99–459 | (none; uninformative) | 20/20 |
| Angular Native | 216 | 115–469 | probe + 3 ms | 20/20 |
| Lynx | 197 | 85–480 | probe + 14 ms | 20/20 |

### Agreement
- **Swift:** the probe sits inside the screen bracket in 18/20 launches and at most 5 ms early in the other 2.
- **React Native:** the probe is inside the bracket in 14/20 launches. In the other 6 it fires before the last frame without the list, by up to 48 ms.
- **Flutter:** the probe misses the bracket in all 19 launches.

A first attempt launched the app with `XCUIApplication.launch()` inside the screenshot test. It failed as a cross-check: screenshots are serialised behind the launch, so every run had the same 250 ms gap at the same phase (≈ 185–430 ms) and the bracket could not narrow. A steady-state calibration against a time-code screen showed that, outside a launch, `XCUIScreen` samples the display about 7 ms after the call starts (p5–p95 −1 to 15 ms; calls ≈ 64 ms). That calibration does not hold during a launch, so it is not used.

## Caveats
- **Different conditions in the two tables.** Screenshot capture slows every launch: probe medians rise by 50–110 ms (for example Swift 103 → 182, KMP 116 → 224). The UI-test session also enables accessibility automation in the apps. The cross-check therefore compares the probe and the screen *within the same launch*. Its absolute values are not time to content without load; the main table is.
- **The hooks differ in what "rendered" means.** rAF after layout (React Native, Angular Native, Lynx), next display-link tick (Swift), next Compose frame (KMP) and Dart post-frame (Flutter) all fire before the compositor has the pixels on screen. Only Flutter's gap is large enough to change the picture.
- **Launch path.** Launched with `devicectl` (FrontBoard), so the zoom starts from the screen centre rather than an icon. Measured from kernel process start, so the time between tap/launch request and process spawn is not included. That is why these values are lower than the XCTest first-frame numbers in [README.md](README.md), which start at the launch request.
- **Launch screens.** Flutter's white launch screen is visible while its dark-themed list loads. Flutter and KMP bring the list in with a cross-fade, and a frame counts as "visible" once the classifier passes 0.4 during that fade.
- **Builds.** Release, thinned for iPhone17,3, export method `debugging` (not App Store/FairPlay). The probe adds one native function and one hook per app.
- **argent was not used.** It needs a cabled iPhone. Phone state was checked through `devicectl` launch results.

## State left on the phone
The six apps were reinstalled from **committed, unprobed** Release builds (same build and export settings, no probe). The harness UI-test runner and its host app (`com.mdnotes.harness.host`, `…HarnessUITests.xctrunner`) are installed from a scratch copy of `harness/xcui` with the screenshot tests added. The host app shows a time-code screen when launched with `-timecode`; otherwise it behaves as before.
