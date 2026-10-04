# Iteration 4 — Delete with undo

References: `ref/04-editor-preview.png`, `ref/04-notes-toast.png`.

**Editor.** The navigation row's right side becomes `Delete` (17 pt `danger`,
identifier `delete-button`) followed by the star toggle, 12 pt apart; the star keeps its
44×44 hit area and 16 pt right padding.

**Deleting.** Tapping `Delete` removes the note immediately (no confirmation), returns
to the tab the editor was opened from, and shows a toast.

**Toast** (identifier `toast`): 16 pt side margins, 12 pt above the tab bar, height 48,
radius 12, background `#1C1C1E`, 16 pt horizontal padding. Left: `Note deleted`, 15 pt
white. Right: `Undo`, 15 pt semibold `#A79FFF` (identifier `undo-button`). It disappears
after 4 seconds or when Undo is tapped. Undo restores the note exactly as it was (id,
body, star, `updatedAt`), so it reappears in its original position. A second deletion
while a toast is showing replaces the toast; only the latest deletion can be undone.
Deletion survives a relaunch.
