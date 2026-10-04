import type { Note } from './types';

const at = (y: number, m: number, d: number, h: number, min: number) =>
  new Date(y, m - 1, d, h, min).getTime();

export function seedNotes(): Note[] {
  return [
    {
      id: 'welcome',
      starred: true,
      updatedAt: at(2026, 10, 1, 9, 30),
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
        '```',
        'const hello = "world";',
        '```',
        '',
        '#welcome',
      ].join('\n'),
    },
    {
      id: 'groceries',
      starred: false,
      updatedAt: at(2026, 9, 30, 18, 5),
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
      updatedAt: at(2026, 9, 28, 14, 0),
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
      updatedAt: at(2026, 9, 25, 8, 15),
      body: ['# Ideas', '', 'Build a tiny habit tracker. Maybe *one tap* per day, no accounts, no sync. #ideas'].join('\n'),
    },
  ];
}
