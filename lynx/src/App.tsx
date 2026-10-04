import type { ReactNode } from '@lynx-js/react';
import { useCallback, useEffect, useLynxGlobalEventListener, useMemo, useRef, useState } from '@lynx-js/react';

import './App.css';
import { TabBar } from './components/TabBar.js';
import { Toast } from './components/Toast.js';
import type { Tab } from './components/TabBar.js';
import { newNoteId, sortNotes } from './data/notes.js';
import { noteTags } from './data/tags.js';
import { toggleTask } from './data/tasks.js';
import * as store from './data/store.js';
import { DEFAULT_SETTINGS } from './data/types.js';
import type { Note, Settings } from './data/types.js';
import { EditorScreen } from './screens/EditorScreen.js';
import type { EditorMode } from './screens/EditorScreen.js';
import { NotesScreen } from './screens/NotesScreen.js';
import { SettingsScreen } from './screens/SettingsScreen.js';
import { StarredScreen } from './screens/StarredScreen.js';
import { applyTheme, colors, getInitialAppearance, getSafeArea, getSystemScheme } from './theme.js';
import type { ColorScheme } from './theme.js';

interface EditorState {
  id: string;
  mode: EditorMode;
  autoFocus: boolean;
}

export function App() {
  const [loaded, setLoaded] = useState(false);
  const [notes, setNotes] = useState<Note[]>([]);
  const [settings, setSettings] = useState<Settings>(() => ({ ...DEFAULT_SETTINGS, appearance: getInitialAppearance() }));
  const [systemScheme, setSystemScheme] = useState<ColorScheme>(getSystemScheme);
  const [tab, setTab] = useState<Tab>('notes');
  const [query, setQuery] = useState('');
  const [tagFilter, setTagFilter] = useState<string | null>(null);
  const [editor, setEditor] = useState<EditorState | null>(null);
  const [keyboardHeight, setKeyboardHeight] = useState(0);
  // Last deleted note, undoable while the toast is visible.
  const [deleted, setDeleted] = useState<Note | null>(null);
  const toastTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const safe = getSafeArea();
  const scheme: ColorScheme = settings.appearance === 'system' ? systemScheme : settings.appearance;
  applyTheme(scheme);

  useLynxGlobalEventListener('systemColorSchemeChanged', (value: unknown) => {
    setSystemScheme(value === 'dark' ? 'dark' : 'light');
  });

  useEffect(() => {
    setNotes(store.loadNotes());
    const loaded = store.loadSettings();
    setSettings(loaded);
    setSystemScheme(store.applyNativeAppearance(loaded.appearance));
    setLoaded(true);
  }, []);

  useLynxGlobalEventListener('keyboardstatuschanged', (status: unknown, height: unknown) => {
    setKeyboardHeight(status === 'on' ? Number(height) || 0 : 0);
  });

  const sorted = useMemo(() => sortNotes(notes, settings.sort), [notes, settings.sort]);

  // If the selected tag no longer exists on any note, fall back to `All`.
  useEffect(() => {
    if (tagFilter !== null && !notes.some((n) => noteTags(n.body).includes(tagFilter))) setTagFilter(null);
  }, [notes, tagFilter]);

  const updateSettings = useCallback((s: Settings) => {
    setSettings(s);
    store.saveSettings(s);
    setSystemScheme(store.applyNativeAppearance(s.appearance));
  }, []);

  const openNote = useCallback((id: string) => {
    setEditor({ id, mode: 'preview', autoFocus: false });
  }, []);

  const addNote = useCallback(() => {
    const note: Note = { id: newNoteId(), body: '# New note\n\n', starred: false, updatedAt: Date.now() };
    store.saveNote(note);
    setNotes((prev) => [note, ...prev]);
    setEditor({ id: note.id, mode: 'edit', autoFocus: true });
  }, []);

  const editorNote = editor ? notes.find((n) => n.id === editor.id) : undefined;

  const updateBody = (body: string) => {
    if (!editorNote || body === editorNote.body) return;
    const next: Note = { ...editorNote, body, updatedAt: Date.now() };
    store.saveNote(next);
    setNotes((prev) => prev.map((n) => (n.id === next.id ? next : n)));
  };

  const toggleStar = () => {
    if (!editorNote) return;
    const next: Note = { ...editorNote, starred: !editorNote.starred };
    store.saveNote(next);
    setNotes((prev) => prev.map((n) => (n.id === next.id ? next : n)));
  };

  const closeEditor = () => {
    if (editorNote && editorNote.body.trim() === '') {
      store.deleteNote(editorNote.id);
      setNotes((prev) => prev.filter((n) => n.id !== editorNote.id));
    }
    setKeyboardHeight(0);
    setEditor(null);
  };

  const deleteCurrent = () => {
    if (!editorNote) return;
    const note = editorNote;
    store.deleteNote(note.id);
    setNotes((prev) => prev.filter((n) => n.id !== note.id));
    setKeyboardHeight(0);
    setEditor(null);
    if (toastTimer.current) clearTimeout(toastTimer.current);
    setDeleted(note);
    toastTimer.current = setTimeout(() => {
      toastTimer.current = null;
      setDeleted(null);
    }, 4000);
  };

  const undoDelete = () => {
    if (!deleted) return;
    const note = deleted;
    if (toastTimer.current) clearTimeout(toastTimer.current);
    toastTimer.current = null;
    store.saveNote(note);
    setNotes((prev) => (prev.some((n) => n.id === note.id) ? prev : [...prev, note]));
    setDeleted(null);
  };

  const resetSamples = () => {
    if (toastTimer.current) clearTimeout(toastTimer.current);
    toastTimer.current = null;
    setDeleted(null);
    setNotes(store.resetToSeeds());
  };

  // Android system Back: the host asks JS to close the editor while one is open
  // (otherwise Back leaves the app as usual). No-op on iOS, which has no such module.
  const editorOpen = editor !== null;
  useEffect(() => {
    NativeModules.BackHandler?.setEditorOpen(editorOpen);
  }, [editorOpen]);
  const closeEditorRef = useRef(closeEditor);
  closeEditorRef.current = closeEditor;
  useLynxGlobalEventListener('androidBackPressed', () => {
    lynx.createSelectorQuery().select('#editor-input').invoke({ method: 'blur' }).exec();
    closeEditorRef.current();
  });

  let content: ReactNode | null = null;
  if (!loaded) {
    content = null;
  } else if (tab === 'notes') {
    content = (
      <NotesScreen
        notes={sorted}
        query={query}
        tag={tagFilter}
        onTag={setTagFilter}
        showSnippets={settings.showSnippets}
        onQuery={setQuery}
        onAdd={addNote}
        onOpen={openNote}
      />
    );
  } else if (tab === 'starred') {
    content = <StarredScreen notes={sorted} showSnippets={settings.showSnippets} onOpen={openNote} />;
  } else {
    content = (
      <SettingsScreen settings={settings} noteCount={notes.length} onChange={updateSettings} onReset={resetSamples} />
    );
  }

  return (
    <view className='root' style={{ backgroundColor: colors.bg }}>
      <view style={{ height: `${safe.top}px` }} />
      {editor && editorNote ? (
        <EditorScreen
          key={editorNote.id}
          note={editorNote}
          mode={editor.mode}
          autoFocus={editor.autoFocus}
          keyboardHeight={keyboardHeight}
          bottomInset={safe.bottom}
          onMode={(mode) => setEditor({ ...editor, mode, autoFocus: false })}
          onBody={updateBody}
          onToggleTask={(i) => editorNote && updateBody(toggleTask(editorNote.body, i))}
          onToggleStar={toggleStar}
          onBack={closeEditor}
          onDelete={deleteCurrent}
        />
      ) : (
        <view style={{ flexGrow: 1, flexShrink: 1, flexBasis: '0px', display: 'flex', flexDirection: 'column', position: 'relative' }}>
          <view style={{ flexGrow: 1, flexShrink: 1, flexBasis: '0px', display: 'flex', flexDirection: 'column' }}>{content}</view>
          <TabBar active={tab} bottomInset={safe.bottom} onSelect={setTab} />
          {deleted ? <Toast bottom={56 + safe.bottom + 12} onUndo={undoDelete} /> : null}
        </view>
      )}
    </view>
  );
}
