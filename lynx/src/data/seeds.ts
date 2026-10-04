import type { Note } from './types.js';

const FENCE = '```';

/** The four sample notes seeded on first launch and restored by "Reset sample notes". */
export function seedNotes(): Note[] {
  return [
    {
      id: 'welcome',
      starred: true,
      updatedAt: new Date(2026, 9, 1, 9, 30).getTime(),
      body: [
        '# Welcome to Markdown Notes',
        '',
        'Write in **Markdown** and switch to *Preview* to see it rendered.',
        '',
        '## What works',
        '',
        '- Headings, **bold** and *italic*',
        '- Inline `code` and code blocks',
        '- Bullet and numbered lists',
        '',
        '> Notes are saved on your device automatically.',
        '',
        FENCE,
        'const hello = "world";',
        FENCE,
        '',
        '#welcome',
      ].join('\n'),
    },
    {
      id: 'groceries',
      starred: false,
      updatedAt: new Date(2026, 8, 30, 18, 5).getTime(),
      body: [
        '# Grocery list',
        '',
        '- [x] Oat milk',
        '- [ ] Sourdough bread',
        '- [ ] Blueberries',
        '- [x] Dark chocolate',
        '',
        '#home #shopping',
      ].join('\n'),
    },
    {
      id: 'meeting',
      starred: true,
      updatedAt: new Date(2026, 8, 28, 14, 0).getTime(),
      body: [
        '# Meeting notes',
        '',
        '## Q4 planning',
        '',
        '1. Ship the beta by **Nov 15**',
        '2. Hire one more designer',
        '3. Review analytics weekly',
        '',
        '#work',
      ].join('\n'),
    },
    {
      id: 'ideas',
      starred: false,
      updatedAt: new Date(2026, 8, 25, 8, 15).getTime(),
      body: ['# Ideas', '', 'Build a tiny habit tracker. Maybe *one tap* per day, no accounts, no sync. #ideas'].join('\n'),
    },
  ];
}
