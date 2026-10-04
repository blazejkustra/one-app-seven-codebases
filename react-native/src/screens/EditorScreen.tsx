import React, { useEffect, useRef, useState } from 'react';
import { BackHandler, Keyboard, Platform, Pressable, Share, ScrollView, Text, TextInput, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useNotes } from '../data/NotesStore';
import type { Note } from '../data/types';
import { makeStyles, useColors, useTheme, mono } from '../theme';
import { MarkdownView } from '../markdown/MarkdownView';
import { Segmented } from '../ui/Segmented';
import { toggleTask } from '../data/tasks';

type Mode = 'edit' | 'preview';

export function EditorScreen({
  noteId,
  isNew,
  onClose,
  onDeleted,
}: {
  noteId: string;
  isNew: boolean;
  onClose: () => void;
  onDeleted: (note: Note) => void;
}) {
  const styles = useStyles();
  const colors = useColors();
  const { dark } = useTheme();
  const { getNote, updateBody, toggleStar, deleteNote } = useNotes();
  const note = getNote(noteId);
  const insets = useSafeAreaInsets();
  const [mode, setMode] = useState<Mode>(isNew ? 'edit' : 'preview');
  const [body, setBody] = useState(note?.body ?? '');
  const [keyboardHeight, setKeyboardHeight] = useState(0);
  const bodyRef = useRef(body);

  useEffect(() => {
    // Android has no keyboardWill* events; its Did* events fire once the IME has settled.
    const ios = Platform.OS === 'ios';
    const show = Keyboard.addListener(ios ? 'keyboardWillShow' : 'keyboardDidShow', (e) =>
      setKeyboardHeight(e.endCoordinates.height),
    );
    const hide = Keyboard.addListener(ios ? 'keyboardWillHide' : 'keyboardDidHide', () => setKeyboardHeight(0));
    return () => {
      show.remove();
      hide.remove();
    };
  }, []);

  const onChangeText = (text: string) => {
    bodyRef.current = text;
    setBody(text);
    updateBody(noteId, text); // persisted synchronously to SQLite
  };

  const goBack = () => {
    Keyboard.dismiss();
    if (bodyRef.current.trim().length === 0) deleteNote(noteId);
    onClose();
  };

  // Android system back (button/gesture) behaves like the `‹ Notes` button instead of leaving the app.
  const goBackRef = useRef(goBack);
  goBackRef.current = goBack;
  useEffect(() => {
    const sub = BackHandler.addEventListener('hardwareBackPress', () => {
      goBackRef.current();
      return true;
    });
    return () => sub.remove();
  }, []);

  // Native share sheet (UIActivityViewController) with the raw markdown as plain text.
  const onShare = () => {
    Keyboard.dismiss();
    Share.share({ message: bodyRef.current }).catch(() => {});
  };

  const onDelete = () => {
    Keyboard.dismiss();
    const snapshot = getNote(noteId);
    deleteNote(noteId);
    onClose();
    if (snapshot) onDeleted(snapshot);
  };

  const starred = note?.starred ?? false;
  // On Android the reported keyboard height excludes the navigation bar inset (edge-to-edge window).
  const keyboardSpace = Platform.OS === 'android' ? keyboardHeight + insets.bottom : keyboardHeight;
  const bottomSpace = (keyboardHeight > 0 ? keyboardSpace : insets.bottom) + 16;

  return (
    <View style={styles.flex}>
      <View style={styles.nav}>
        <Pressable
          testID="back-button"
          accessibilityRole="button"
          accessibilityLabel="Notes"
          onPress={goBack}
          style={styles.back}
          hitSlop={8}
        >
          <Text style={styles.backText}>‹ Notes</Text>
        </Pressable>
        <View style={styles.navRight}>
        <Pressable
          testID="share-button"
          accessibilityRole="button"
          accessibilityLabel="Share"
          onPress={onShare}
          style={styles.shareHit}
          hitSlop={8}
        >
          <Text style={styles.shareText}>Share</Text>
        </Pressable>
        <Pressable
          testID="delete-button"
          accessibilityRole="button"
          accessibilityLabel="Delete"
          onPress={onDelete}
          style={styles.deleteHit}
          hitSlop={8}
        >
          <Text style={styles.deleteText}>Delete</Text>
        </Pressable>
        <Pressable
          testID="star-button"
          accessibilityRole="button"
          accessibilityLabel={starred ? 'Unstar' : 'Star'}
          accessibilityState={{ selected: starred }}
          onPress={() => toggleStar(noteId)}
          style={styles.starHit}
        >
          <Text style={[styles.star, { color: starred ? colors.star : colors.textTertiary }]}>{starred ? '★' : '☆'}</Text>
        </Pressable>
        </View>
      </View>
      <View style={styles.segmentWrap}>
        <Segmented<Mode>
          segments={[
            { key: 'edit', label: 'Edit', testID: 'mode-edit' },
            { key: 'preview', label: 'Preview', testID: 'mode-preview' },
          ]}
          value={mode}
          onChange={(m) => {
            if (m === 'preview') Keyboard.dismiss();
            setMode(m);
          }}
        />
      </View>
      {mode === 'edit' ? (
        <View style={[styles.editCard, { marginBottom: bottomSpace }]}>
          <TextInput
            testID="editor-input"
            accessibilityLabel="Note text"
            style={styles.input}
            value={body}
            onChangeText={onChangeText}
            multiline
            autoFocus={isNew}
            scrollEnabled
            textAlignVertical="top"
            autoCorrect={false}
            autoCapitalize="sentences"
            smartInsertDelete={false}
            keyboardAppearance={dark ? 'dark' : 'light'}
            selectionColor={colors.accent}
          />
        </View>
      ) : (
        <ScrollView
          testID="preview-view"
          style={styles.flex}
          contentContainerStyle={[styles.preview, { paddingBottom: insets.bottom + 16 }]}
        >
          <MarkdownView source={body} onToggleTask={(i) => onChangeText(toggleTask(bodyRef.current, i))} />
        </ScrollView>
      )}
    </View>
  );
}

const useStyles = makeStyles((colors) => ({
  flex: { flex: 1 },
  nav: { height: 44, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', backgroundColor: colors.bg },
  back: { paddingLeft: 16, height: 44, justifyContent: 'center' },
  backText: { fontSize: 17, color: colors.accent },
  navRight: { flexDirection: 'row', alignItems: 'center' },
  shareHit: { height: 44, justifyContent: 'center', marginRight: 12 },
  shareText: { fontSize: 17, color: colors.accent },
  deleteHit: { height: 44, justifyContent: 'center', marginRight: 12 },
  deleteText: { fontSize: 17, color: colors.danger },
  starHit: { width: 44, height: 44, marginRight: 16, alignItems: 'center', justifyContent: 'center' },
  star: { fontSize: 22 },
  segmentWrap: { marginTop: 4 },
  editCard: { flex: 1, marginTop: 12, marginHorizontal: 16, backgroundColor: colors.surface, borderRadius: 14, padding: 16 },
  input: { flex: 1, padding: 0, fontFamily: mono, fontSize: 15, lineHeight: 22, color: colors.text },
  preview: { paddingHorizontal: 20, paddingTop: 12 },
}));
