# Markdown Notes (Lynx)

ReactLynx UI (`src/`) rendered by a native iOS host app (`ios/`) that embeds the Lynx SDK via CocoaPods.

- `src/screens`, `src/components` – UI
- `src/data` – note model, helpers, persistence facade (`NativeModules.NotesStore`)
- `src/markdown` – Markdown rendering (parsed with `marked`)
- `ios/MarkdownNotes` – host app, SQLite store (SQLite.swift), Lynx native module

See `BUILD.md` for build commands.
