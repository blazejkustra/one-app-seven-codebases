# Android port prompt (identical for every cross-platform stack; only `{…}` slots change)

The app in `{DIR}/` was built for iOS with **{FRAMEWORK}** from `spec/SPEC.md` and the change requests in
`spec/iterations/` (all six versions are implemented). Your job: ship the **same codebase on Android**
and report honestly how much work that took.

Repository root: `<repo root>`

1. Read `spec/SPEC.md`, `spec/iterations/*.md`, the reference PNGs, and the code in `{DIR}/`. Do **not**
   read other implementations, `harness/` or `results/`. Change files only inside `{DIR}/`.
2. Build a **release** (production, everything embedded, no dev server) Android build of the app and
   install it on the emulator **`emulator-5554`** (Pixel 5, Android 15). Use only that device. Run and
   inspect it with the argent MCP tools. Android SDK: `~/Library/Android/sdk` (`ANDROID_HOME`);
   JDK 17: `/usr/libexec/java_home -v 17`.
3. Verify on Android that the screens look like the reference PNGs (adapt only what Android requires,
   such as system-bar insets) and that the features work: seed notes, search, tag filter, preview/edit,
   editing and persistence after a relaunch, new note, checklist toggle, delete + undo, sort, snippets
   switch, dark mode, and Share (Android's share sheet).
4. Fix whatever is missing or broken with the smallest reasonable changes, keeping shared code shared.
   **iOS must keep working**: re-run the iOS Release simulator build from `{DIR}/BUILD.md` at the end.
5. Application id `com.mdnotes.{ID}`, app name `Markdown Notes`.
6. Write `{DIR}/ANDROID.md`: exact commands to build the release APK from a clean checkout, then a short
   report — what worked out of the box, what you had to add or change (files and why), and anything
   still not working on Android.
7. Don't commit to git. Don't ask questions.

Reply with a short summary: out-of-the-box status (did it build? run? which features worked?), what you
changed, and remaining gaps.
