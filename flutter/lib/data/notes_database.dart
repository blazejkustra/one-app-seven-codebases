import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'note.dart';
import 'seed_notes.dart';

/// SQLite persistence for notes and settings (via sqflite).
class NotesDatabase {
  NotesDatabase._(this._db);

  final Database _db;

  static Future<NotesDatabase> open() async {
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, 'markdown_notes.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id TEXT PRIMARY KEY,
            body TEXT NOT NULL,
            starred INTEGER NOT NULL DEFAULT 0,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        // First launch: seed the sample notes.
        final batch = db.batch();
        for (final note in buildSeedNotes()) {
          batch.insert('notes', note.toRow());
        }
        await batch.commit(noResult: true);
      },
    );
    return NotesDatabase._(db);
  }

  Future<List<Note>> loadNotes() async {
    final rows = await _db.query('notes');
    return rows.map(Note.fromRow).toList();
  }

  Future<void> upsert(Note note) => _db.insert(
    'notes',
    note.toRow(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<void> delete(String id) =>
      _db.delete('notes', where: 'id = ?', whereArgs: [id]);

  Future<void> replaceAll(List<Note> notes) => _db.transaction((txn) async {
    await txn.delete('notes');
    for (final note in notes) {
      await txn.insert('notes', note.toRow());
    }
  });

  Future<Map<String, String>> loadSettings() async {
    final rows = await _db.query('settings');
    return {
      for (final row in rows) row['key']! as String: row['value']! as String,
    };
  }

  Future<void> setSetting(String key, String value) => _db.insert('settings', {
    'key': key,
    'value': value,
  }, conflictAlgorithm: ConflictAlgorithm.replace);
}
