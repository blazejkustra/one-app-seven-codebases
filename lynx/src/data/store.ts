/**
 * Persistence facade over the native `NotesStore` module, which keeps notes and
 * settings in SQLite (SQLite.swift) on the iOS side. Calls are synchronous.
 */
import { seedNotes } from './seeds.js';
import { DEFAULT_SETTINGS } from './types.js';
import type { Note, Settings } from './types.js';

function native() {
  return NativeModules.NotesStore;
}

export function loadNotes(): Note[] {
  const raw = native().loadNotes();
  const parsed = raw ? (JSON.parse(raw) as Note[] | null) : null;
  if (parsed === null) {
    // First launch: seed the sample notes.
    const seeds = seedNotes();
    native().replaceAllNotes(seeds);
    return seeds;
  }
  return parsed.map((n) => ({ ...n, starred: !!n.starred }));
}

export function loadSettings(): Settings {
  const raw = native().loadSettings();
  const map = (raw ? JSON.parse(raw) : {}) as Record<string, string>;
  return {
    sort: map['sort'] === 'title' ? 'title' : DEFAULT_SETTINGS.sort,
    showSnippets: map['showSnippets'] === undefined ? DEFAULT_SETTINGS.showSnippets : map['showSnippets'] === '1',
    appearance: map['appearance'] === 'light' || map['appearance'] === 'dark' ? map['appearance'] : 'system',
  };
}

export function saveNote(note: Note): void {
  native().upsertNote(note);
}

export function deleteNote(id: string): void {
  native().deleteNote(id);
}

export function resetToSeeds(): Note[] {
  const seeds = seedNotes();
  native().replaceAllNotes(seeds);
  return seeds;
}

export function saveSettings(settings: Settings): void {
  native().setSetting('sort', settings.sort);
  native().setSetting('showSnippets', settings.showSnippets ? '1' : '0');
  native().setSetting('appearance', settings.appearance);
}

/**
 * Applies the appearance override to the native window (status bar, keyboard)
 * and returns the current system colour scheme.
 */
export function applyNativeAppearance(appearance: string): 'light' | 'dark' {
  return NativeModules.Appearance.setAppearance(appearance) === 'dark' ? 'dark' : 'light';
}
