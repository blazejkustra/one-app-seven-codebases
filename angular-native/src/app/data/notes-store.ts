import { Injectable, computed, signal } from '@angular/core';
import type { SQLiteDatabase } from 'expo-sqlite';
import { notesDb } from './db.ts';
import { type Appearance, type Note, type SortOrder, noteTags, sortNotes } from './note.ts';
import { seedNotes } from './seed.ts';

interface NoteRow {
  id: string;
  body: string;
  starred: number;
  updated_at: number;
}

const NEW_NOTE_BODY = '# New note\n\n';

/**
 * The single source of truth for notes and settings. State lives in signals; every mutation is
 * written straight through to SQLite with the synchronous API, so nothing is pending in memory
 * if the app is killed right after an edit.
 */
@Injectable({ providedIn: 'root' })
export class NotesStore {
  private db: SQLiteDatabase | null = null;

  readonly loaded = signal(false);
  readonly notes = signal<readonly Note[]>([]);
  readonly sortOrder = signal<SortOrder>('updated');
  readonly showSnippets = signal(true);
  readonly appearance = signal<Appearance>('system');

  readonly sorted = computed(() => sortNotes(this.notes(), this.sortOrder()));
  readonly starred = computed(() => this.sorted().filter((n) => n.starred));
  readonly count = computed(() => this.notes().length);
  /** Every tag across all notes, A to Z. */
  readonly allTags = computed(() =>
    [...new Set(this.notes().flatMap((n) => noteTags(n.body)))].sort((a, b) => (a < b ? -1 : a > b ? 1 : 0)),
  );

  constructor() {
    void this.load();
  }

  private async load(): Promise<void> {
    try {
      const db = await notesDb.ready();
      this.db = db;
      const seeded = db.getFirstSync<{ value: string }>("SELECT value FROM settings WHERE key = 'seeded'");
      if (!seeded) {
        db.withTransactionSync(() => {
          this.insertSeeds(db);
          this.writeSetting('seeded', '1');
          this.writeSetting('sortOrder', 'updated');
          this.writeSetting('showSnippets', '1');
        });
      }
      const settings = db.getAllSync<{ key: string; value: string }>('SELECT key, value FROM settings');
      for (const { key, value } of settings) {
        if (key === 'sortOrder') this.sortOrder.set(value === 'title' ? 'title' : 'updated');
        if (key === 'showSnippets') this.showSnippets.set(value !== '0');
        if (key === 'appearance' && (value === 'light' || value === 'dark')) this.appearance.set(value);
      }
      this.notes.set(this.readNotes(db));
    } catch (error) {
      console.error('[notes] failed to open database', error);
    } finally {
      this.loaded.set(true);
    }
  }

  get(id: string): Note | undefined {
    return this.notes().find((n) => n.id === id);
  }

  create(): Note {
    const note: Note = {
      id: `n${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`,
      body: NEW_NOTE_BODY,
      starred: false,
      updatedAt: Date.now(),
    };
    this.notes.update((list) => [...list, note]);
    this.db?.runSync('INSERT INTO notes (id, body, starred, updated_at) VALUES (?, ?, ?, ?)', [
      note.id,
      note.body,
      0,
      note.updatedAt,
    ]);
    return note;
  }

  updateBody(id: string, body: string): void {
    const updatedAt = Date.now();
    this.notes.update((list) => list.map((n) => (n.id === id ? { ...n, body, updatedAt } : n)));
    this.db?.runSync('UPDATE notes SET body = ?, updated_at = ? WHERE id = ?', [body, updatedAt, id]);
  }

  toggleStar(id: string): void {
    const note = this.get(id);
    if (!note) return;
    const starred = !note.starred;
    this.notes.update((list) => list.map((n) => (n.id === id ? { ...n, starred } : n)));
    this.db?.runSync('UPDATE notes SET starred = ? WHERE id = ?', [starred ? 1 : 0, id]);
  }

  delete(id: string): void {
    this.notes.update((list) => list.filter((n) => n.id !== id));
    this.db?.runSync('DELETE FROM notes WHERE id = ?', [id]);
  }

  /** Puts a deleted note back exactly as it was (id, body, star, updatedAt). */
  restore(note: Note): void {
    if (this.get(note.id)) return;
    this.notes.update((list) => [...list, note]);
    this.db?.runSync('INSERT OR REPLACE INTO notes (id, body, starred, updated_at) VALUES (?, ?, ?, ?)', [
      note.id,
      note.body,
      note.starred ? 1 : 0,
      note.updatedAt,
    ]);
  }

  toggleSortOrder(): void {
    const next: SortOrder = this.sortOrder() === 'updated' ? 'title' : 'updated';
    this.sortOrder.set(next);
    this.writeSetting('sortOrder', next);
  }

  /** System -> Light -> Dark -> System. */
  cycleAppearance(): void {
    const order: Appearance[] = ['system', 'light', 'dark'];
    const next = order[(order.indexOf(this.appearance()) + 1) % order.length];
    this.appearance.set(next);
    this.writeSetting('appearance', next);
  }

  toggleSnippets(): void {
    const next = !this.showSnippets();
    this.showSnippets.set(next);
    this.writeSetting('showSnippets', next ? '1' : '0');
  }

  resetSamples(): void {
    const db = this.db;
    if (db) {
      db.withTransactionSync(() => {
        db.runSync('DELETE FROM notes');
        this.insertSeeds(db);
      });
    }
    this.notes.set(seedNotes());
  }

  private insertSeeds(db: SQLiteDatabase): void {
    for (const note of seedNotes()) {
      db.runSync('INSERT OR REPLACE INTO notes (id, body, starred, updated_at) VALUES (?, ?, ?, ?)', [
        note.id,
        note.body,
        note.starred ? 1 : 0,
        note.updatedAt,
      ]);
    }
  }

  private readNotes(db: SQLiteDatabase): Note[] {
    return db.getAllSync<NoteRow>('SELECT id, body, starred, updated_at FROM notes').map((row) => ({
      id: row.id,
      body: row.body,
      starred: row.starred === 1,
      updatedAt: row.updated_at,
    }));
  }

  private writeSetting(key: string, value: string): void {
    this.db?.runSync('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', [key, value]);
  }
}
