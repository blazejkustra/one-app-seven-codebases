# React Native: review of the 6 failed QA checks

All 6 failures were reproduced and traced by hand with argent on the final Release build. They come
from **1 accessibility defect**; the underlying features work.

| Root cause | Checks it fails | Manual verification of the feature |
|---|---|---|
| Each note card is one accessibility button labelled with the title only, so the snippet, date and "N/M done" are drawn but invisible to VoiceOver / UI automation | test02, test09, test12, test25, test26, test27 | A typed new note shows "Hello world" as its snippet with today's date; toggling a task shows "3/4 done", today's date and moves the note to the top; Undo restores Meeting notes at its slot with "Sep 28, 2026" |
