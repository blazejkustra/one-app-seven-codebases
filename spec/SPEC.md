# Markdown Notes — product & design spec

Every implementation in this repo builds **the same app** from this document. It is
an iOS app (iPhone 17 Pro, iOS 26.5 simulator, portrait only, light mode only).

Pixel references live in `spec/reference/*.png` (1206×2622, i.e. 402×874 pt @3x),
rendered from `spec/mockups/*.html`. Where the prose and the PNGs disagree, the
prose wins. All sizes below are in **points (pt)**.

The app must **not** use platform-native chrome (no UINavigationBar, UITabBar,
UISegmentedControl, UISwitch, Material widgets…). Every control is drawn to
this spec so that all implementations look identical.

---

## 1. Design tokens

| Token | Value |
|---|---|
| `bg` (screen background) | `#F5F5F7` |
| `surface` (cards, tab bar, groups) | `#FFFFFF` |
| `text` | `#1C1C1E` |
| `textSecondary` | `#6E6E73` |
| `textTertiary` | `#8E8E93` |
| `fill` (search field, segmented track, switch off) | `#E9E9EE` |
| `separator` | `#E5E5EA` |
| `accent` | `#5B4FE9` |
| `accentSoft` (inline code background) | `#ECEBFF` |
| `star` | `#F5A623` |
| `danger` | `#E5484D` |
| `codeBg` / `codeText` | `#1C1C1E` / `#F5F5F7` |

* Font: the iOS **system font** (SF Pro) for everything, except monospace text,
  which uses **Menlo**.
* No shadows and no borders anywhere unless stated (cards have **no** border).
* Safe areas on iPhone 17 Pro: top 62, bottom 34. Content respects them.

---

## 2. Data model & behaviour

A note is `{ id: string, body: string (markdown), starred: boolean, updatedAt: date }`.

* **Title** = the first line of `body` with leading `#` characters and spaces
  removed. Empty → `Untitled`.
* **Snippet** = every line after the first, processed like this: trim each line;
  drop lines that are code fences (start with three backticks); remove a leading
  `#`-run, `- `, `* `, `> ` or `<number>. ` marker; remove all `**`, `*` and
  `` ` `` characters; drop empty lines; join what is left with single spaces.
* **Date label**: `MMM d, yyyy` in en-US, e.g. `Oct 1, 2026`.
* **Persistence**: notes, stars and settings survive killing and relaunching the app.
* **First launch** seeds the four notes in §6. "Reset sample notes" restores exactly them.
* **Sort**: by `updatedAt` descending (default) or by title A→Z (case-insensitive).
* **Search** (Notes tab only): case-insensitive substring match on the whole `body`.
  Updates as you type.
* **Editing** a note's body sets its `updatedAt` to now and saves automatically
  (no save button). Data must not be lost when going back or killing the app
  right after leaving the editor.
* **New note**: the `+` button creates `{ body: "# New note\n\n", starred: false,
  updatedAt: now }` and opens it in the editor in **Edit** mode with the text
  input focused (keyboard up).
* **Leaving the editor** with a body that is empty after trimming deletes that note.
* Opening an **existing** note shows it in **Preview** mode. Switching to **Edit**
  with the segmented control does not focus the input (no keyboard) until the
  user taps the text.

---

## 3. Screens

There are four screens: **Notes**, **Starred**, **Settings** (three tabs) and the
**Editor** (pushed over the tabs, tab bar hidden). Back navigation from the editor
returns to the tab it was opened from.

### 3.1 Tab bar (Notes, Starred, Settings screens)

* Pinned to the bottom. Height 56 + bottom safe area (34) = 90. Background `surface`,
  1 pt top line `separator`.
* Three equal-width columns with text-only labels `Notes`, `Starred`, `Settings`,
  centred in the 56 pt area. 15 pt. Active: `accent`, semibold. Inactive:
  `textTertiary`, medium.

### 3.2 Screen header (all three tabs)

* Directly under the top safe area, height 52, horizontal padding 20.
* Title: 34 pt bold `text`, left aligned, vertically centred (`Notes`, `Starred`,
  `Settings`).
* Notes tab only: a 36×36 circular `accent` button on the right with a white `+`
  (24 pt, regular weight), centred.

### 3.3 Notes screen  (`reference/01-notes.png`)

* **Search field** 4 pt below the header, 16 pt side margins, height 40, radius 10,
  background `fill`, 12 pt left padding, 17 pt text. Placeholder `Search notes` in
  `textTertiary`. No icon.
* **List** starts 12 pt below the search field and scrolls vertically.
  Cards have 16 pt side margins and 12 pt vertical gaps; the list has 16 pt bottom padding.
* **Note card**: `surface`, radius 14, padding 16.
  * Title: 17 pt semibold `text`, 1 line, ellipsized.
  * Snippet (only when *Show snippets* is on): 4 pt below, 15 pt regular
    `textSecondary`, line height 20, max 2 lines, ellipsized. If the snippet is
    empty, omit it.
  * Footer row 8 pt below: date label 13 pt `textTertiary` on the left; when
    starred, a `★` (16 pt, `star`) on the right.
  * Tapping a card opens the editor.
* **Empty states**, centred in the list area, 17 pt `textTertiary`:
  `No notes yet` (no notes at all) / `No notes found` (search has no results).

### 3.4 Starred screen  (`reference/04-starred.png`)

* Header `Starred` (no `+`), no search field. The list starts 12 pt below the header
  and uses the same cards, showing only starred notes in the current sort order.
* Empty state: `No starred notes`.

### 3.5 Settings screen  (`reference/05-settings.png`)

* Group 1 starts 12 pt below the header: `surface`, radius 14, 16 pt side margins,
  three rows of height 52, 16 pt horizontal padding, row label 17 pt `text`. Rows are
  separated by a 1 pt `separator` line inset 16 pt from the left.
  1. `Sort by` — value on the right in 17 pt `accent`: `Updated` or `Title`.
     Tapping the row toggles between them.
  2. `Show snippets` — custom switch on the right: 51×31 pill; on = `accent`,
     off = `fill`; 27 pt white circular knob with 2 pt inset. Default on.
  3. `Notes` — note count on the right, 17 pt `textTertiary`.
* Group 2, 24 pt below group 1, same style, one row: `Reset sample notes`, centred,
  17 pt `danger`. Tapping it immediately restores the seed notes (no dialog).
* Footer 16 pt below group 2: `Markdown Notes · v1.0`, 13 pt `textTertiary`, centred.

### 3.6 Editor  (`reference/02-editor-preview.png`, `reference/03-editor-edit.png`)

* **Navigation row** directly under the top safe area, height 44, background `bg`.
  * Left: back button `‹ Notes` in 17 pt `accent` with 16 pt left padding. The label is
    always `‹ Notes`, whichever tab the editor was opened from.
  * Right: star toggle, a 44×44 hit area with 16 pt right padding; shows `★` in `star`
    when starred, `☆` in `textTertiary` when not, 22 pt.
* **Segmented control** 4 pt below, 16 pt side margins, height 36, track `fill`
  radius 9. Two equal segments `Edit` and `Preview`. The selected segment is a white
  pill inset 2 pt, radius 7, label 15 pt semibold `text`; the unselected label is
  15 pt medium `textSecondary`.
* **Content** begins 12 pt below the segmented control.
  * **Edit mode**: a multiline text input inside a `surface` card (radius 14,
    16 pt side margins, 16 pt padding) filling the remaining height down to 16 pt above
    the bottom safe area — or 16 pt above the keyboard when it is shown. Menlo 15 pt,
    line height 22, `text`. The raw markdown is shown and editable.
  * **Preview mode**: a vertically scrolling view, 20 pt side padding, no card,
    rendering the markdown per §4.

---

## 4. Markdown rendering (Preview)

Only this subset needs to be supported. Base text is 17 pt `text`, line height 24.

| Markdown | Rendering |
|---|---|
| `# H1` | 28 pt bold, 12 pt space below |
| `## H2` | 22 pt bold, 16 pt above, 8 pt below |
| `### H3` | 18 pt semibold, 12 pt above, 6 pt below |
| paragraph | 17 pt, 12 pt below; consecutive non-blank lines join into one paragraph |
| `**bold**` | bold |
| `*italic*` | italic |
| `` `code` `` | Menlo 15 pt, `accent` text on `accentSoft` background |
| `- item` / `* item` | `•` bullet, 8 pt gap between bullet and text, 4 pt between items, 12 pt below the list |
| `1. item` | `1.` numbers, same spacing as bullets |
| `> quote` | 3 pt `accent` bar on the left, 12 pt gap, italic `textSecondary` text, 12 pt below |
| code fence | `codeBg` box, radius 10, padding 12, Menlo 14 pt `codeText`, line height 20, 12 pt below |

---

## 5. Accessibility identifiers (required)

Automated tests drive every implementation through these identifiers (iOS
`accessibilityIdentifier`). They must be on the tappable/inputs elements themselves.

| Element | identifier |
|---|---|
| Tabs | `tab-notes`, `tab-starred`, `tab-settings` |
| `+` button | `add-note-button` |
| Search field | `search-input` |
| Every note card (all share it) | `note-card` |
| Empty state text | `empty-state` |
| Editor back button | `back-button` |
| Editor star toggle | `star-button` |
| Segments | `mode-edit`, `mode-preview` |
| Editor text input | `editor-input` |
| Preview scroll view | `preview-view` |
| Settings rows | `sort-row`, `snippets-switch`, `notes-count`, `reset-button` |

App identity: display name **Markdown Notes**, bundle identifier
`com.mdnotes.<framework>` (see the task you were given for `<framework>`).

---

## 6. Seed notes

Timestamps are local time. Default sort order is the order below.

**id `welcome`** — starred — updated 2026-10-01 09:30

````markdown
# Welcome to Markdown Notes

Write in **Markdown** and switch to *Preview* to see it rendered.

## What works

- Headings, **bold** and *italic*
- Inline `code` and code blocks
- Bullet and numbered lists

> Notes are saved on your device automatically.

```
const hello = "world";
```
````

**id `groceries`** — not starred — updated 2026-09-30 18:05

```markdown
# Grocery list

- Oat milk
- Sourdough bread
- Blueberries
- Dark chocolate
```

**id `meeting`** — starred — updated 2026-09-28 14:00

```markdown
# Meeting notes

## Q4 planning

1. Ship the beta by **Nov 15**
2. Hire one more designer
3. Review analytics weekly
```

**id `ideas`** — not starred — updated 2026-09-25 08:15

```markdown
# Ideas

Build a tiny habit tracker. Maybe *one tap* per day, no accounts, no sync.
```

(The seed bodies have no trailing newline.)

---

## 7. Real-world engineering requirements

Build it the way a production team would, with the stack's normal ecosystem — not from scratch.

* **Markdown parsing** must use an established, maintained third-party Markdown parser from your
  stack's package ecosystem (a CommonMark/GFM parser such as `swift-markdown`, `marked`,
  `markdown-it`, `remark`, `package:markdown`, `org.jetbrains:markdown`, …). Writing your own
  parser is not allowed. You may render the parsed result with your own views so it matches §4.
* **Storage** must be **SQLite** through a maintained package (for example GRDB / SQLite.swift,
  `expo-sqlite` / `op-sqlite`, `sqflite` / `drift`, SQLDelight / Room, …). Notes live in a table;
  settings may live in SQLite or in a key-value store package. Plain JSON files,
  `UserDefaults`/`AsyncStorage` for notes are not allowed. If your stack has no SQLite package, wire
  SQLite in at the native layer.
* **Dependencies** are added with the stack's standard package manager (Swift Package Manager,
  npm, pub, Gradle, CocoaPods) and **locked** (commit the lockfile / `Package.resolved`).
* Keep the code organised as a real project would: UI, data/storage and markdown in separate
  modules or files.
