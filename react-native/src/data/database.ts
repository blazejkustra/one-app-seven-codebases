import * as SQLite from 'expo-sqlite';
import { seedNotes } from './seed';
import type { Appearance, Note, Settings } from './types';

type NoteRow = { id: string; body: string; starred: number; updated_at: number };

const db = SQLite.openDatabaseSync('markdown-notes.db');

db.execSync(`
  PRAGMA journal_mode = WAL;
  CREATE TABLE IF NOT EXISTS notes (
    id TEXT PRIMARY KEY NOT NULL,
    body TEXT NOT NULL,
    starred INTEGER NOT NULL DEFAULT 0,
    updated_at INTEGER NOT NULL
  );
  CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY NOT NULL,
    value TEXT NOT NULL
  );
`);

function insertNote(n: Note) {
  db.runSync(
    'INSERT OR REPLACE INTO notes (id, body, starred, updated_at) VALUES (?, ?, ?, ?)',
    n.id,
    n.body,
    n.starred ? 1 : 0,
    n.updatedAt,
  );
}

function getSetting(key: string): string | null {
  const row = db.getFirstSync<{ value: string }>('SELECT value FROM settings WHERE key = ?', key);
  return row ? row.value : null;
}

function setSetting(key: string, value: string) {
  db.runSync('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', key, value);
}

/** Seeds the database on first launch and removes notes left empty by an interrupted session. */
export function initDatabase() {
  if (getSetting('seeded') !== '1') {
    db.withTransactionSync(() => {
      seedNotes().forEach(insertNote);
      setSetting('seeded', '1');
    });
  }
  db.runSync("DELETE FROM notes WHERE trim(body, ' ' || char(9) || char(10) || char(13)) = ''");
}

export function loadNotes(): Note[] {
  return db
    .getAllSync<NoteRow>('SELECT id, body, starred, updated_at FROM notes')
    .map((r) => ({ id: r.id, body: r.body, starred: r.starred === 1, updatedAt: r.updated_at }));
}

export function saveNote(note: Note) {
  insertNote(note);
}

export function deleteNote(id: string) {
  db.runSync('DELETE FROM notes WHERE id = ?', id);
}

export function resetToSeed(): Note[] {
  const seeds = seedNotes();
  db.withTransactionSync(() => {
    db.runSync('DELETE FROM notes');
    seeds.forEach(insertNote);
  });
  return seeds;
}

function parseAppearance(v: string | null): Appearance {
  return v === 'light' || v === 'dark' ? v : 'system';
}

export function loadSettings(): Settings {
  return {
    sortBy: getSetting('sortBy') === 'title' ? 'title' : 'updated',
    showSnippets: getSetting('showSnippets') !== '0',
    appearance: parseAppearance(getSetting('appearance')),
  };
}

export function saveSettings(s: Settings) {
  db.withTransactionSync(() => {
    setSetting('sortBy', s.sortBy);
    setSetting('showSnippets', s.showSnippets ? '1' : '0');
    setSetting('appearance', s.appearance);
  });
}
