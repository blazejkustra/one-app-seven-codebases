declare let NativeModules: {
  /** Android only: tells the host whether system Back should close the editor. */
  BackHandler?: {
    setEditorOpen(open: boolean): void;
  };
  Share: {
    /** Opens the native share sheet (UIActivityViewController) with plain text. */
    shareText(text: string): void;
  };
  Appearance: {
    /** Sets the window style override; returns the system scheme ('light' | 'dark'). */
    setAppearance(mode: string): string;
  };
  NotesStore: {
    loadNotes(): string;
    loadSettings(): string;
    upsertNote(note: { id: string; body: string; starred: boolean; updatedAt: number }): boolean;
    deleteNote(id: string): boolean;
    replaceAllNotes(notes: { id: string; body: string; starred: boolean; updatedAt: number }[]): boolean;
    setSetting(key: string, value: string): boolean;
  };
};
