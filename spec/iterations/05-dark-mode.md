# Iteration 5 — Dark mode

References: `ref/05-settings.png`, `ref/05-notes-dark.png`, `ref/05-checklist-preview-dark.png`.

**Setting.** A new row `Appearance` (identifier `appearance-row`) is the third row of the
first Settings group (before `Notes`). Value on the right in `accent`: `System`, `Light`
or `Dark`; tapping cycles System → Light → Dark → System. Default `System` (follows the
iOS appearance, live). Persisted.

**Dark tokens.**

| Token | Dark value |
|---|---|
| `bg` | `#000000` |
| `surface` | `#1C1C1E` |
| `text` | `#F5F5F7` |
| `textSecondary` | `#A1A1A6` |
| `textTertiary` | `#8E8E93` |
| `fill` | `#2C2C2E` |
| `separator` | `#38383A` |
| `accent` | `#7D74FF` |
| `accentSoft` | `#2A2650` |
| `star` | `#FFB340` |
| `danger` | `#FF6369` |
| `codeBg` / `codeText` | `#2C2C2E` / `#F5F5F7` |

The toast background becomes `#3A3A3C` in dark mode. Status-bar content is light in dark
mode and dark in light mode. Every screen, control, keyboard appearance and the editor
text follow the active theme.
