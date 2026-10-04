import { Component, DestroyRef, effect, inject, signal } from '@angular/core';
import { SafeAreaProvider, SafeAreaView, View } from '@ng-native/components';
import { ColorScheme, HardwareBack, Keyboard, SafeArea, StatusBar } from '@ng-native/device';
import type { Note } from './data/note.ts';
import { NotesStore } from './data/notes-store.ts';
import { EditorScreen } from './screens/editor-screen.ts';
import { NotesScreen } from './screens/notes-screen.ts';
import { SettingsScreen } from './screens/settings-screen.ts';
import { StarredScreen } from './screens/starred-screen.ts';
import { type Tab, TabBar } from './ui/tab-bar.ts';
import { Toast } from './ui/toast.ts';

interface EditorState {
  readonly id: string;
  readonly isNew: boolean;
}

/**
 * App shell: three custom tabs plus the editor pushed over them. Tabs stay mounted (hidden with
 * display: none) while the editor is open so search text and scroll positions survive "back".
 */
@Component({
  imports: [
    EditorScreen,
    NotesScreen,
    SafeAreaProvider,
    SafeAreaView,
    SettingsScreen,
    StarredScreen,
    TabBar,
    Toast,
    View,
  ],
  selector: 'app-root',
  template: `
    <safe-area-provider>
      <safe-area-view class="screen" [edges]="['top']">
        <view class="tabs" [style.display]="editor() ? 'none' : 'flex'">
          <view class="page" [style.display]="tab() === 'notes' ? 'flex' : 'none'">
            <app-notes-screen (create)="createNote()" (open)="openNote($event)" />
          </view>
          <view class="page" [style.display]="tab() === 'starred' ? 'flex' : 'none'">
            <app-starred-screen (open)="openNote($event)" />
          </view>
          <view class="page" [style.display]="tab() === 'settings' ? 'flex' : 'none'">
            <app-settings-screen />
          </view>
          <app-tab-bar [active]="tab()" (select)="selectTab($event)" />
          @if (deleted()) {
            <view class="toast-slot" [style.bottom]="56 + 1 + safeArea.insets().bottom + 12">
              <app-toast (undo)="undoDelete()" />
            </view>
          }
        </view>
        @if (editor(); as current) {
          <app-editor-screen
            [noteId]="current.id"
            [isNew]="current.isNew"
            (back)="closeEditor()"
            (delete)="deleteNote()"
          />
        }
      </safe-area-view>
    </safe-area-provider>
  `,
  styles: `
    :host {
      flex: 1;
      --bg: #f5f5f7;
      --surface: #ffffff;
      --text: #1c1c1e;
      --text-secondary: #6e6e73;
      --text-tertiary: #8e8e93;
      --fill: #e9e9ee;
      --separator: #e5e5ea;
      --accent: #5b4fe9;
      --accent-soft: #ecebff;
      --star: #f5a623;
      --danger: #e5484d;
      --code-bg: #1c1c1e;
      --code-text: #f5f5f7;
      --toast-bg: #1c1c1e;
      background-color: var(--bg);
    }
    @media (prefers-color-scheme: dark) {
      :host {
        --bg: #000000;
        --surface: #1c1c1e;
        --text: #f5f5f7;
        --text-secondary: #a1a1a6;
        --text-tertiary: #8e8e93;
        --fill: #2c2c2e;
        --separator: #38383a;
        --accent: #7d74ff;
        --accent-soft: #2a2650;
        --star: #ffb340;
        --danger: #ff6369;
        --code-bg: #2c2c2e;
        --code-text: #f5f5f7;
        --toast-bg: #3a3a3c;
      }
    }
    .screen {
      flex: 1;
      background-color: var(--bg);
    }
    .tabs {
      flex: 1;
    }
    .toast-slot {
      position: absolute;
      left: 16px;
      right: 16px;
    }
    .page {
      flex: 1;
    }
  `,
})
export class App {
  private readonly store = inject(NotesStore);
  private readonly keyboard = inject(Keyboard);

  protected readonly tab = signal<Tab>('notes');
  protected readonly editor = signal<EditorState | null>(null);
  protected readonly safeArea = inject(SafeArea);
  /** The most recently deleted note, undoable while its toast is showing. */
  protected readonly deleted = signal<Note | null>(null);
  private toastTimer: ReturnType<typeof setTimeout> | undefined;

  constructor() {
    // Status bar content follows the active scheme: dark in light mode, light in dark mode.
    inject(StatusBar).set({ style: 'auto' });
    // Apply the Appearance preference to the whole window (app CSS, keyboard, native chrome).
    const scheme = inject(ColorScheme);
    effect(() => {
      const appearance = this.store.appearance();
      scheme.set(appearance === 'system' ? null : appearance);
    });
    // Android's back button/gesture leaves the editor like "‹ Notes" does; on the tabs it is not
    // consumed, so the system backgrounds the app. A no-op on iOS.
    const unsubscribe = inject(HardwareBack).handle(() => {
      if (!this.editor()) return false;
      this.closeEditor();
      return true;
    });
    inject(DestroyRef).onDestroy(unsubscribe);
  }

  protected selectTab(tab: Tab): void {
    this.keyboard.dismiss();
    this.tab.set(tab);
  }

  protected createNote(): void {
    const note = this.store.create();
    this.editor.set({ id: note.id, isNew: true });
  }

  protected openNote(id: string): void {
    this.keyboard.dismiss();
    this.editor.set({ id, isNew: false });
  }

  protected deleteNote(): void {
    const current = this.editor();
    this.keyboard.dismiss();
    this.editor.set(null);
    if (!current) return;
    const note = this.store.get(current.id);
    if (!note) return;
    this.store.delete(note.id);
    this.deleted.set(note);
    clearTimeout(this.toastTimer);
    this.toastTimer = setTimeout(() => this.deleted.set(null), 4000);
  }

  protected undoDelete(): void {
    const note = this.deleted();
    clearTimeout(this.toastTimer);
    this.deleted.set(null);
    if (note) this.store.restore(note);
  }

  protected closeEditor(): void {
    const current = this.editor();
    this.keyboard.dismiss();
    if (current) {
      const note = this.store.get(current.id);
      if (note && note.body.trim().length === 0) this.store.delete(current.id);
    }
    this.editor.set(null);
  }
}
