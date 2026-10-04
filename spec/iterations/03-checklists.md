# Iteration 3 — Interactive checklists

References: `ref/03-notes.png`, `ref/03-checklist-preview.png`.

**Markdown.** Lines `- [ ] text` / `- [x] text` (also with `*`) are tasks.

**Seed notes change.** The groceries body becomes:

```markdown
# Grocery list

- [x] Oat milk
- [ ] Sourdough bread
- [ ] Blueberries
- [x] Dark chocolate

#home #shopping
```

**Preview.** Consecutive tasks form a group (12 pt below the group). Each task row:
22×22 checkbox, radius 6, 10 pt gap to the 17 pt text, 8 pt between rows.
Unchecked box: 2 pt `textTertiary` border, no fill. Checked: `accent` fill, white `✓`
(14 pt bold); the text becomes `textTertiary` with strikethrough. Tapping the checkbox
or the text toggles the task: the body's `[ ]` ↔ `[x]` is rewritten, saved, and the
note's `updatedAt` becomes now. Identifiers: `task-0`, `task-1`, … in document order;
each task element's accessibility value is `checked` or `unchecked`.

**Snippet.** A leading `[ ] ` / `[x] ` after the list marker is removed.

**Note card.** When the note has tasks, a `<done>/<total> done` label (13 pt
`textSecondary`) follows the date in the footer, 12 pt after it.
