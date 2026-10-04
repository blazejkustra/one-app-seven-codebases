import 'note.dart';

/// The sample notes seeded on first launch and restored by "Reset sample notes".
List<Note> buildSeedNotes() => [
  Note(
    id: 'welcome',
    starred: true,
    updatedAt: DateTime(2026, 10, 1, 9, 30),
    body:
        '# Welcome to Markdown Notes\n'
        '\n'
        'Write in **Markdown** and switch to *Preview* to see it rendered.\n'
        '\n'
        '## What works\n'
        '\n'
        '- Headings, **bold** and *italic*\n'
        '- Inline `code` and code blocks\n'
        '- Bullet and numbered lists\n'
        '\n'
        '> Notes are saved on your device automatically.\n'
        '\n'
        '```\n'
        'const hello = "world";\n'
        '```\n'
        '\n'
        '#welcome',
  ),
  Note(
    id: 'groceries',
    starred: false,
    updatedAt: DateTime(2026, 9, 30, 18, 5),
    body:
        '# Grocery list\n'
        '\n'
        '- [x] Oat milk\n'
        '- [ ] Sourdough bread\n'
        '- [ ] Blueberries\n'
        '- [x] Dark chocolate\n'
        '\n'
        '#home #shopping',
  ),
  Note(
    id: 'meeting',
    starred: true,
    updatedAt: DateTime(2026, 9, 28, 14, 0),
    body:
        '# Meeting notes\n'
        '\n'
        '## Q4 planning\n'
        '\n'
        '1. Ship the beta by **Nov 15**\n'
        '2. Hire one more designer\n'
        '3. Review analytics weekly\n'
        '\n'
        '#work',
  ),
  Note(
    id: 'ideas',
    starred: false,
    updatedAt: DateTime(2026, 9, 25, 8, 15),
    body:
        '# Ideas\n'
        '\n'
        'Build a tiny habit tracker. Maybe *one tap* per day, no accounts, no sync. #ideas',
  ),
];
