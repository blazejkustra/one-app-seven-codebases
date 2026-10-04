import React, { createContext, useCallback, useContext, useMemo, useState } from 'react';
import * as Db from './database';
import type { Note, Settings } from './types';

type Store = {
  notes: Note[];
  settings: Settings;
  getNote: (id: string) => Note | undefined;
  createNote: () => Note;
  updateBody: (id: string, body: string) => void;
  toggleStar: (id: string) => void;
  deleteNote: (id: string) => void;
  restoreNote: (note: Note) => void;
  resetSamples: () => void;
  updateSettings: (patch: Partial<Settings>) => void;
};

const Ctx = createContext<Store | null>(null);

export function NotesProvider({ children }: { children: React.ReactNode }) {
  const [notes, setNotes] = useState<Note[]>(() => {
    Db.initDatabase();
    return Db.loadNotes();
  });
  const [settings, setSettings] = useState<Settings>(() => Db.loadSettings());

  const getNote = useCallback((id: string) => notes.find((n) => n.id === id), [notes]);

  const createNote = useCallback(() => {
    const note: Note = {
      id: `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`,
      body: '# New note\n\n',
      starred: false,
      updatedAt: Date.now(),
    };
    Db.saveNote(note);
    setNotes((prev) => [...prev, note]);
    return note;
  }, []);

  const updateBody = useCallback((id: string, body: string) => {
    setNotes((prev) =>
      prev.map((n) => {
        if (n.id !== id) return n;
        const next = { ...n, body, updatedAt: Date.now() };
        Db.saveNote(next);
        return next;
      }),
    );
  }, []);

  const toggleStar = useCallback((id: string) => {
    setNotes((prev) =>
      prev.map((n) => {
        if (n.id !== id) return n;
        const next = { ...n, starred: !n.starred };
        Db.saveNote(next);
        return next;
      }),
    );
  }, []);

  const deleteNote = useCallback((id: string) => {
    Db.deleteNote(id);
    setNotes((prev) => prev.filter((n) => n.id !== id));
  }, []);

  const restoreNote = useCallback((note: Note) => {
    Db.saveNote(note);
    setNotes((prev) => [...prev.filter((n) => n.id !== note.id), note]);
  }, []);

  const resetSamples = useCallback(() => {
    setNotes(Db.resetToSeed());
  }, []);

  const updateSettings = useCallback((patch: Partial<Settings>) => {
    setSettings((prev) => {
      const next = { ...prev, ...patch };
      Db.saveSettings(next);
      return next;
    });
  }, []);

  const value = useMemo(
    () => ({ notes, settings, getNote, createNote, updateBody, toggleStar, deleteNote, restoreNote, resetSamples, updateSettings }),
    [notes, settings, getNote, createNote, updateBody, toggleStar, deleteNote, restoreNote, resetSamples, updateSettings],
  );
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useNotes(): Store {
  const s = useContext(Ctx);
  if (!s) throw new Error('useNotes must be used inside NotesProvider');
  return s;
}
