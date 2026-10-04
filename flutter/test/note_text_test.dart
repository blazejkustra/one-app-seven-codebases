import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_notes/data/seed_notes.dart';
import 'package:markdown_notes/markdown/note_text.dart';

void main() {
  test('tags parsing', () {
    expect(noteTags('# T #nope\n#Work and #q4-plans #work\n`#code` x#no\n```\n#fenced\n```\n## Heading'),
        ['work', 'q4-plans']);
  });
  test('seed snippets and tags', () {
    final seeds = {for (final n in buildSeedNotes()) n.id: n};
    expect(noteTags(seeds['welcome']!.body), ['welcome']);
    expect(noteTags(seeds['groceries']!.body), ['home', 'shopping']);
    expect(noteSnippet(seeds['groceries']!.body),
        'Oat milk Sourdough bread Blueberries Dark chocolate');
    expect(noteSnippet(seeds['ideas']!.body),
        'Build a tiny habit tracker. Maybe one tap per day, no accounts, no sync.');
    expect(noteSnippet(seeds['welcome']!.body),
        'Write in Markdown and switch to Preview to see it rendered. What works Headings, bold and italic Inline code and code blocks Bullet and numbered lists Notes are saved on your device automatically. const hello = "world";');
    expect(noteSnippet('T\n#heading-ish tag'), 'tag');
  });
  test('tasks', () {
    final seeds = {for (final n in buildSeedNotes()) n.id: n};
    final body = seeds['groceries']!.body;
    expect(noteTasks(body), [true, false, false, true]);
    final toggled = toggleTask(body, 1);
    expect(noteTasks(toggled), [true, true, false, true]);
    expect(toggled.contains('- [x] Sourdough bread'), isTrue);
    expect(toggleTask(toggled, 1), body);
    expect(noteTasks('T\n* [X] a\n```\n- [ ] no\n```\n1. [ ] no\n- [ ]x'), [true]);
  });
}
