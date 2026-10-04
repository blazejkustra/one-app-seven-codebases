import { StatusBar } from 'expo-status-bar';
import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Appearance, useColorScheme, View } from 'react-native';
import { SafeAreaProvider, useSafeAreaInsets } from 'react-native-safe-area-context';
import { NotesProvider, useNotes } from './src/data/NotesStore';
import { EditorScreen } from './src/screens/EditorScreen';
import { NotesScreen } from './src/screens/NotesScreen';
import { SettingsScreen } from './src/screens/SettingsScreen';
import { StarredScreen } from './src/screens/StarredScreen';
import { makeStyles, ThemeProvider, useTheme } from './src/theme';
import { TabBar, type TabKey } from './src/ui/TabBar';
import { Toast } from './src/ui/Toast';
import type { Note } from './src/data/types';

type EditorRoute = { noteId: string; isNew: boolean } | null;

function Root() {
  const styles = useStyles();
  const { dark } = useTheme();
  const insets = useSafeAreaInsets();
  const { createNote, restoreNote } = useNotes();
  const [tab, setTab] = useState<TabKey>('notes');
  const [query, setQuery] = useState('');
  const [tagFilter, setTagFilter] = useState<string | null>(null);
  const [editor, setEditor] = useState<EditorRoute>(null);

  const [deleted, setDeleted] = useState<Note | null>(null);
  const toastTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const clearToastTimer = () => {
    if (toastTimer.current) clearTimeout(toastTimer.current);
    toastTimer.current = null;
  };
  const showDeleted = useCallback((note: Note) => {
    clearToastTimer();
    setDeleted(note); // replaces any toast already showing; only the latest deletion is undoable
    toastTimer.current = setTimeout(() => setDeleted(null), 4000);
  }, []);
  const undo = () => {
    clearToastTimer();
    if (deleted) restoreNote(deleted);
    setDeleted(null);
  };
  useEffect(() => clearToastTimer, []);

  const open = useCallback((id: string) => setEditor({ noteId: id, isNew: false }), []);
  const create = useCallback(() => setEditor({ noteId: createNote().id, isNew: true }), [createNote]);

  return (
    <View style={[styles.root, { paddingTop: insets.top }]}>
      <StatusBar style={dark ? 'light' : 'dark'} />
      {editor ? (
        <EditorScreen key={editor.noteId} noteId={editor.noteId} isNew={editor.isNew} onClose={() => setEditor(null)} onDeleted={showDeleted} />
      ) : (
        <>
          <View style={styles.flex}>
            {tab === 'notes' && <NotesScreen query={query} onQueryChange={setQuery} tag={tagFilter} onTagChange={setTagFilter} onOpen={open} onCreate={create} />}
            {tab === 'starred' && <StarredScreen onOpen={open} />}
            {tab === 'settings' && <SettingsScreen />}
          </View>
          <TabBar active={tab} onChange={setTab} />
          {deleted && <Toast message="Note deleted" bottom={56 + insets.bottom + 12} onUndo={undo} />}
        </>
      )}
    </View>
  );
}

/** Resolves the Appearance setting (System / Light / Dark) and provides the palette. */
function Themed({ children }: { children: React.ReactNode }) {
  const { settings } = useNotes();
  const mode = settings.appearance;
  // Override the native window style too, so the keyboard and system UI follow the setting.
  useEffect(() => {
    Appearance.setColorScheme(mode === 'system' ? 'unspecified' : mode);
  }, [mode]);
  const system = useColorScheme();
  const dark = mode === 'system' ? system === 'dark' : mode === 'dark';
  return <ThemeProvider dark={dark}>{children}</ThemeProvider>;
}

export default function App() {
  return (
    <SafeAreaProvider>
      <NotesProvider>
        <Themed>
          <Root />
        </Themed>
      </NotesProvider>
    </SafeAreaProvider>
  );
}

const useStyles = makeStyles((colors) => ({
  root: { flex: 1, backgroundColor: colors.bg },
  flex: { flex: 1 },
}));
