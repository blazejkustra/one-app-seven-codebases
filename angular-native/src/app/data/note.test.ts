import { expect, test } from 'vitest';
import { formatDate, noteSnippet, noteTitle, sortNotes } from './note.ts';
import { seedNotes } from './seed.ts';
import { parseMarkdown } from '../markdown/markdown-model.ts';

test('title strips leading hashes and falls back to Untitled', () => {
  expect(noteTitle('# Welcome to Markdown Notes\n\nBody')).toBe('Welcome to Markdown Notes');
  expect(noteTitle('   \nmore')).toBe('Untitled');
  expect(noteTitle('')).toBe('Untitled');
});

test('snippets match the spec for the seed notes', () => {
  const [welcome, groceries, meeting, ideas] = seedNotes();
  expect(noteSnippet(welcome.body)).toBe(
    'Write in Markdown and switch to Preview to see it rendered. What works Headings, bold and italic Inline code and code blocks Bullet and numbered lists Notes are saved on your device automatically. const hello = "world";',
  );
  expect(noteSnippet(groceries.body)).toBe('Oat milk Sourdough bread Blueberries Dark chocolate');
  expect(noteSnippet(meeting.body)).toBe('Q4 planning Ship the beta by Nov 15 Hire one more designer Review analytics weekly');
  expect(noteSnippet(ideas.body)).toBe('Build a tiny habit tracker. Maybe one tap per day, no accounts, no sync.');
  expect(noteSnippet('# New note\n\n')).toBe('');
});

test('date label and sorting', () => {
  expect(formatDate(new Date(2026, 9, 1, 9, 30).getTime())).toBe('Oct 1, 2026');
  const notes = seedNotes();
  expect(sortNotes(notes, 'updated').map((n) => n.id)).toEqual(['welcome', 'groceries', 'meeting', 'ideas']);
  expect(sortNotes(notes, 'title').map((n) => n.id)).toEqual(['groceries', 'ideas', 'meeting', 'welcome']);
});

test('markdown model covers the welcome note', () => {
  const blocks = parseMarkdown(seedNotes()[0].body);
  expect(blocks.map((b) => b.kind)).toEqual(['heading', 'paragraph', 'heading', 'list', 'quote', 'code', 'paragraph']);
});

test('tags', async () => {
  const { noteTags } = await import('./note.ts');
  const [welcome, groceries, meeting, ideas] = seedNotes();
  expect(noteTags(welcome.body)).toEqual(['welcome']);
  expect(noteTags(groceries.body)).toEqual(['home', 'shopping']);
  expect(noteTags(meeting.body)).toEqual(['work']);
  expect(noteTags(ideas.body)).toEqual(['ideas']);
  expect(noteTags('# Title #nope\n\n# Heading\nx #Work #work a#b `#code`\n```\n#fenced\n```\n#q4-plans')).toEqual(['work', 'q4-plans']);
  expect(noteSnippet('# T\n\nhello #tag `#code` world\n## Sub #x')).toBe('hello #code world Sub');
  expect(noteSnippet('# T\n#heading-tag only')).toBe('only');
  const blocks = parseMarkdown(ideas.body);
  const runs = blocks[1].kind === 'paragraph' ? blocks[1].runs : [];
  expect(runs.filter((r) => r.tag).map((r) => r.text)).toEqual(['#ideas']);
});

test('tasks', async () => {
  const { taskProgress, toggleTask } = await import('./note.ts');
  const groceries = seedNotes()[1];
  expect(noteSnippet(groceries.body)).toBe('Oat milk Sourdough bread Blueberries Dark chocolate');
  expect(taskProgress(groceries.body)).toEqual({ done: 2, total: 4 });
  const toggled = toggleTask(groceries.body, 1);
  expect(toggled).toContain('- [x] Sourdough bread');
  expect(taskProgress(toggled)).toEqual({ done: 3, total: 4 });
  expect(toggleTask(toggleTask(groceries.body, 0), 0)).toBe(groceries.body);
  const blocks = parseMarkdown(groceries.body);
  expect(blocks.map((b) => b.kind)).toEqual(['heading', 'tasks', 'paragraph']);
  expect(taskProgress('# t\n```\n- [ ] no\n```\n* [X] yes')).toEqual({ done: 1, total: 1 });
});
