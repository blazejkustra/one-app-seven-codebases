# Iteration 6 — Share

Reference: `ref/06-editor-preview.png`.

**Editor.** A `Share` button (17 pt `accent`, identifier `share-button`) is added before
`Delete` in the navigation row, 12 pt apart.

Tapping it opens the **native iOS share sheet** (`UIActivityViewController`) with the
note's raw markdown body as plain text. Dismissing the sheet returns to the editor
unchanged.
