import 'dart:math';

import 'package:flutter/foundation.dart';

import '../markdown/note_text.dart';
import 'note.dart';
import 'notes_database.dart';
import 'seed_notes.dart';

/// In-memory app state backed by [NotesDatabase]. Every mutation is written
/// through to SQLite immediately.
class NotesStore extends ChangeNotifier {
  NotesStore._(
    this._db,
    this._notes,
    this._sort,
    this._showSnippets,
    this._appearance,
  );

  final NotesDatabase _db;
  final Map<String, Note> _notes;
  SortOrder _sort;
  bool _showSnippets;
  Appearance _appearance;

  static Future<NotesStore> load() async {
    final db = await NotesDatabase.open();
    final notes = await db.loadNotes();
    final settings = await db.loadSettings();
    return NotesStore._(
      db,
      {for (final n in notes) n.id: n},
      settings['sort'] == 'title' ? SortOrder.title : SortOrder.updated,
      settings['showSnippets'] != 'false',
      Appearance.values.firstWhere(
        (a) => a.name == settings['appearance'],
        orElse: () => Appearance.system,
      ),
    );
  }

  SortOrder get sort => _sort;
  bool get showSnippets => _showSnippets;
  Appearance get appearance => _appearance;

  /// Cycles System → Light → Dark → System (iteration 5).
  void cycleAppearance() {
    _appearance =
        Appearance.values[(_appearance.index + 1) % Appearance.values.length];
    _db.setSetting('appearance', _appearance.name);
    notifyListeners();
  }

  int get count => _notes.length;

  Note? byId(String id) => _notes[id];

  List<Note> get sortedNotes {
    final list = _notes.values.toList();
    if (_sort == SortOrder.title) {
      list.sort((a, b) {
        final c = noteTitle(a.body)
            .toLowerCase()
            .compareTo(noteTitle(b.body).toLowerCase());
        return c != 0 ? c : b.updatedAt.compareTo(a.updatedAt);
      });
    } else {
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return list;
  }

  /// Notes matching [query] (case-insensitive body substring) and, when
  /// given, carrying [tag].
  List<Note> search(String query, {String? tag}) {
    final q = query.toLowerCase();
    return sortedNotes
        .where((n) => q.isEmpty || n.body.toLowerCase().contains(q))
        .where((n) => tag == null || noteTags(n.body).contains(tag))
        .toList();
  }

  /// Every tag across all notes, A→Z.
  List<String> get allTags {
    final tags = <String>{for (final n in _notes.values) ...noteTags(n.body)};
    return tags.toList()..sort();
  }

  List<Note> get starredNotes => sortedNotes.where((n) => n.starred).toList();

  Note createNote() {
    final now = DateTime.now();
    final id =
        '${now.microsecondsSinceEpoch.toRadixString(36)}-${Random().nextInt(1 << 32).toRadixString(36)}';
    final note = Note(
      id: id,
      body: '# New note\n\n',
      starred: false,
      updatedAt: now,
    );
    _notes[id] = note;
    _db.upsert(note);
    notifyListeners();
    return note;
  }

  void updateBody(String id, String body) {
    final note = _notes[id];
    if (note == null || note.body == body) return;
    final updated = note.copyWith(body: body, updatedAt: DateTime.now());
    _notes[id] = updated;
    _db.upsert(updated);
    notifyListeners();
  }

  void toggleStar(String id) {
    final note = _notes[id];
    if (note == null) return;
    final updated = note.copyWith(starred: !note.starred);
    _notes[id] = updated;
    _db.upsert(updated);
    notifyListeners();
  }

  void delete(String id) {
    if (_notes.remove(id) == null) return;
    _db.delete(id);
    notifyListeners();
  }

  /// Puts a deleted note back exactly as it was (id, body, star, updatedAt).
  void restore(Note note) {
    _notes[note.id] = note;
    _db.upsert(note);
    notifyListeners();
  }

  void toggleSort() {
    _sort = _sort == SortOrder.updated ? SortOrder.title : SortOrder.updated;
    _db.setSetting('sort', _sort == SortOrder.title ? 'title' : 'updated');
    notifyListeners();
  }

  void setShowSnippets(bool value) {
    _showSnippets = value;
    _db.setSetting('showSnippets', value ? 'true' : 'false');
    notifyListeners();
  }

  void resetSampleNotes() {
    final seeds = buildSeedNotes();
    _notes
      ..clear()
      ..addAll({for (final n in seeds) n.id: n});
    _db.replaceAll(seeds);
    notifyListeners();
  }
}
