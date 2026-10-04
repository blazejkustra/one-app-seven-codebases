# Lynx: review of the 8 failed QA checks

Reproduced and traced by hand with argent on the final Release build. They come from **2
accessibility defects**; the underlying features work.

| Root cause | Checks it fails | Manual verification of the feature |
|---|---|---|
| Each note card is one accessibility button labelled with the title only; snippet, date and "N/M done" are drawn but invisible to VoiceOver / UI automation | test02, test25, test26, test27 | Toggling a task shows "3/4 done", today's date and moves the note to the top; Undo restores Meeting notes in place with "Sep 28, 2026" |
| `search-input` / `editor-input` are plain groups without keyboard focus, so assistive tech and XCUITest cannot type into them | test09, test10, test12, test24 | Typing with the keyboard works: a new note saves at the top with "Hello world" as its snippet and today's date |
