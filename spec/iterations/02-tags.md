# Iteration 2 — Tags

References: `ref/02-notes.png`, `ref/02-editor-preview.png`.

**Parsing.** A tag is `#` directly followed by a letter, then letters, digits, `-` or `_`,
at the start of a line or after whitespace (`#work`, `#q4-plans`). `# Heading` (hash +
space) is a heading, not a tag. Text inside inline code or code fences never contains tags.
Tags are lower-cased and de-duplicated per note. The title line never contributes tags.

**Seed notes change** (Reset restores these too). Append to the bodies:
* `welcome`: `\n\n#welcome`
* `groceries`: `\n\n#home #shopping`
* `meeting`: `\n\n#work`
* `ideas`: ` #ideas` (same line, after `no sync.`)

**Snippet.** Tags are removed from the snippet. The leading heading marker that the
snippet strips is now only a `#`-run followed by whitespace.

**Note card.** When the note has tags, a row of chips sits 8 pt below the snippet (or
below the title when there is no snippet): `#tag`, 12 pt medium `accent` text on
`accentSoft`, height 22, 8 pt horizontal padding, radius 11, 6 pt gaps, single line
(overflow clipped). The footer row stays 8 pt below.

**Filter row (Notes tab).** 12 pt below the search field, a horizontally scrolling row with
16 pt side insets and 8 pt gaps: `All` followed by every tag across all notes, A→Z, as `#tag`.
Chips: height 32, 12 pt horizontal padding, radius 16, 15 pt. Unselected: `surface` with
`text` medium. Selected: `accent` with white semibold. `All` is selected by default.
Selecting a tag shows only notes with that tag; it combines with search. If the selected
tag no longer exists on any note, the selection returns to `All`. The list starts 12 pt
below this row. The selection is not persisted.
Identifiers: `tag-filter-all`, `tag-filter-<tag>` (e.g. `tag-filter-work`).

**Preview.** Tags render inline in `accent`, medium weight (not tappable).
