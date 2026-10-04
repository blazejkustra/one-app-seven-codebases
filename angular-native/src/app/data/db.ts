import { database } from '@ng-native/expo/database';

/** The app's SQLite database: notes in one table, key/value settings in another. */
export const notesDb = database('markdown-notes.db', [
  {
    to: 1,
    up: (db) =>
      db.execAsync(
        'CREATE TABLE notes (id TEXT PRIMARY KEY NOT NULL, body TEXT NOT NULL, starred INTEGER NOT NULL DEFAULT 0, updated_at INTEGER NOT NULL);' +
          'CREATE TABLE settings (key TEXT PRIMARY KEY NOT NULL, value TEXT NOT NULL);',
      ),
  },
]);
