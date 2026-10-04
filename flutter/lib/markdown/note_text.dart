import 'package:intl/intl.dart';

final _leadingHashes = RegExp(r'^[#\s]+');
final _listOrQuoteMarker = RegExp(r'^(#+\s+|- |\* |> |\d+\. )');
final _emphasisChars = RegExp(r'\*\*|\*|`');
final _inlineCode = RegExp(r'`[^`]*`');
final _spaces = RegExp(r'\s+');
final _taskBox = RegExp(r'^\[[ xX]\]\s+');
final _dateFormat = DateFormat('MMM d, yyyy', 'en_US');

/// A tag: `#` + letter + letters/digits/`-`/`_`, at line start or after
/// whitespace. `# Heading` (hash + space) never matches.
final tagPattern = RegExp(r'(?<=^|\s)#\p{L}[\p{L}\p{N}_-]*', unicode: true);

/// First line of [body] without leading `#`s and spaces; `Untitled` if empty.
String noteTitle(String body) {
  final firstLine = body.split('\n').first;
  final title = firstLine.replaceFirst(_leadingHashes, '').trim();
  return title.isEmpty ? 'Untitled' : title;
}

/// Tag matches in [line] that are not inside an inline code span.
Iterable<RegExpMatch> _tagMatches(String line) {
  final code = _inlineCode.allMatches(line).toList();
  return tagPattern
      .allMatches(line)
      .where((t) => !code.any((c) => t.start >= c.start && t.start < c.end));
}

/// Lower-cased, de-duplicated tags of [body] (title line, code fences and
/// inline code excluded), in order of first appearance.
List<String> noteTags(String body) {
  final tags = <String>{};
  var inFence = false;
  for (final line in body.split('\n').skip(1)) {
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    for (final m in _tagMatches(line)) {
      tags.add(m.group(0)!.substring(1).toLowerCase());
    }
  }
  return tags.toList();
}

/// Plain-text snippet of every line after the first (spec §2, iteration 2).
String noteSnippet(String body) {
  final lines = body.split('\n');
  final parts = <String>[];
  var inFence = false;
  for (final raw in lines.skip(1)) {
    var line = raw.trim();
    if (line.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    line = line.replaceFirst(_listOrQuoteMarker, '').replaceFirst(_taskBox, '');
    if (!inFence) {
      for (final m in _tagMatches(line).toList().reversed) {
        line = line.replaceRange(m.start, m.end, '');
      }
    }
    line = line.replaceAll(_emphasisChars, '').replaceAll(_spaces, ' ').trim();
    if (line.isEmpty) continue;
    parts.add(line);
  }
  return parts.join(' ');
}

/// A task line (iteration 3): `- [ ] text` / `* [x] text`, optionally
/// indented or inside a blockquote. Group 2 is the box state.
final taskLinePattern = RegExp(
  r'^([ \t]*(?:>[ \t]*)*[-*][ \t]+)\[([ xX])\](?=[ \t])',
);

/// Checked state of every task in [body], in document order (code fences
/// excluded).
List<bool> noteTasks(String body) {
  final tasks = <bool>[];
  var inFence = false;
  for (final line in body.split('\n')) {
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    final m = taskLinePattern.firstMatch(line);
    if (m != null) tasks.add(m.group(2) != ' ');
  }
  return tasks;
}

/// Returns [body] with task number [index] flipped between `[ ]` and `[x]`.
String toggleTask(String body, int index) {
  final lines = body.split('\n');
  var inFence = false;
  var seen = 0;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    final m = taskLinePattern.firstMatch(line);
    if (m == null) continue;
    if (seen++ == index) {
      final box = m.group(2) == ' ' ? '[x]' : '[ ]';
      lines[i] = '${m.group(1)}$box${line.substring(m.end)}';
      return lines.join('\n');
    }
  }
  return body;
}

String formatNoteDate(DateTime date) => _dateFormat.format(date);
