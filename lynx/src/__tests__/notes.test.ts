import { describe, expect, test } from '@rstest/core';

import { dateLabel, noteSnippet, noteTitle, sortNotes } from '../data/notes.js';
import { seedNotes } from '../data/seeds.js';

describe('note helpers', () => {
  test('title strips leading hashes and falls back to Untitled', () => {
    expect(noteTitle('# Welcome to Markdown Notes\nbody')).toBe('Welcome to Markdown Notes');
    expect(noteTitle('   \nbody')).toBe('Untitled');
  });

  test('snippet follows the spec rules', () => {
    const welcome = seedNotes()[0]!;
    expect(noteSnippet(welcome.body)).toBe(
      'Write in Markdown and switch to Preview to see it rendered. What works Headings, bold and italic Inline code and code blocks Bullet and numbered lists Notes are saved on your device automatically. const hello = "world";',
    );
    expect(noteSnippet(seedNotes()[2]!.body)).toBe(
      'Q4 planning Ship the beta by Nov 15 Hire one more designer Review analytics weekly',
    );
  });

  test('date label is MMM d, yyyy', () => {
    expect(dateLabel(new Date(2026, 9, 1, 9, 30).getTime())).toBe('Oct 1, 2026');
  });

  test('sorting', () => {
    const seeds = seedNotes();
    expect(sortNotes(seeds, 'updated').map((n) => n.id)).toEqual(['welcome', 'groceries', 'meeting', 'ideas']);
    expect(sortNotes(seeds, 'title').map((n) => n.id)).toEqual(['groceries', 'ideas', 'meeting', 'welcome']);
  });
});

import { allTags, noteTags } from '../data/tags.js';

describe('tags', () => {
  test('parses tags per spec', () => {
    expect(noteTags('# Title #nope\n#Work and #q4-plans, #work\n## Heading\n`#code` x#no #a_b')).toEqual([
      'work',
      'q4-plans',
      'a_b',
    ]);
    expect(noteTags('# T\n```\n#infence\n```\n#after')).toEqual(['after']);
    expect(noteTags('# T\n#1abc #-x')).toEqual([]);
  });

  test('seed tags and snippets', () => {
    const seeds = seedNotes();
    expect(seeds.map((n) => noteTags(n.body))).toEqual([['welcome'], ['home', 'shopping'], ['work'], ['ideas']]);
    expect(allTags(seeds.map((n) => noteTags(n.body)))).toEqual(['home', 'ideas', 'shopping', 'welcome', 'work']);
    expect(noteSnippet(seeds[3]!.body)).toBe('Build a tiny habit tracker. Maybe one tap per day, no accounts, no sync.');
    expect(noteSnippet(seeds[1]!.body)).toBe('Oat milk Sourdough bread Blueberries Dark chocolate');
    expect(noteSnippet('# T\n#heading-like\n#  real heading')).toBe('real heading');
  });
});

import { noteTasks, taskProgress, toggleTask } from '../data/tasks.js';

describe('tasks', () => {
  test('parse, progress, toggle', () => {
    const g = seedNotes()[1]!.body;
    expect(taskProgress(g)).toEqual({ done: 2, total: 4 });
    expect(noteSnippet(g)).toBe('Oat milk Sourdough bread Blueberries Dark chocolate');
    const t = toggleTask(g, 1);
    expect(t).toContain('- [x] Sourdough bread');
    expect(toggleTask(t, 0)).toContain('- [ ] Oat milk');
    expect(noteTasks('# T\n* [X] a\n```\n- [ ] no\n```\n- [ ]b')).toEqual([{ line: 1, checked: true }]);
    expect(taskProgress(seedNotes()[0]!.body)).toBeNull();
  });
});
