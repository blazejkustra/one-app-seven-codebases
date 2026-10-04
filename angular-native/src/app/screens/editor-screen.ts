import { Component, computed, inject, input, output, signal } from '@angular/core';
import { Pressable, ScrollView, Text, TextInput, View } from '@ng-native/components';
import { Keyboard, SafeArea, Sharing } from '@ng-native/device';
import { toggleTask } from '../data/note.ts';
import { NotesStore } from '../data/notes-store.ts';
import { KEYBOARD_EXCLUDES_BOTTOM_INSET } from '../platform.ts';
import { MarkdownView } from '../markdown/markdown-view.ts';
import { type EditorMode, SegmentedControl } from '../ui/segmented-control.ts';

@Component({
  selector: 'app-editor-screen',
  imports: [MarkdownView, Pressable, ScrollView, SegmentedControl, Text, TextInput, View],
  host: { style: 'flex: 1' },
  template: `
    <view class="nav">
      <pressable
        testID="back-button"
        accessibilityRole="button"
        class="back"
        [hitSlop]="8"
        #b="pressable"
        [style.opacity]="b.pressed() ? 0.5 : 1"
        (press)="back.emit()"
      >
        <text class="back-text">‹ Notes</text>
      </pressable>
      <view class="actions">
      <pressable
        testID="share-button"
        accessibilityRole="button"
        class="delete"
        [hitSlop]="8"
        #sh="pressable"
        [style.opacity]="sh.pressed() ? 0.5 : 1"
        (press)="share()"
      >
        <text class="share-text">Share</text>
      </pressable>
      <pressable
        testID="delete-button"
        accessibilityRole="button"
        class="delete"
        [hitSlop]="8"
        #d="pressable"
        [style.opacity]="d.pressed() ? 0.5 : 1"
        (press)="delete.emit()"
      >
        <text class="delete-text">Delete</text>
      </pressable>
      <pressable
        testID="star-button"
        accessibilityRole="button"
        [accessibilityLabel]="starred() ? 'Unstar' : 'Star'"
        [accessibilityState]="{ selected: starred() }"
        class="star"
        (press)="toggleStar()"
      >
        <text class="star-text" [class.starred]="starred()">{{ starred() ? '★' : '☆' }}</text>
      </pressable>
      </view>
    </view>

    <view class="segments">
      <app-segmented-control [mode]="mode()" (change)="setMode($event)" />
    </view>

    @if (mode() === 'edit') {
      <view class="card" [style.marginBottom]="cardBottom()">
        <text-input
          testID="editor-input"
          class="input"
          [multiline]="true"
          [autoFocus]="focusOnMount()"
          autoCapitalize="sentences"
          [autoCorrect]="false"
          [smartInsertDelete]="false"
          [value]="body()"
          (changeText)="onChange($event)"
        />
      </view>
    } @else {
      <scroll-view
        testID="preview-view"
        class="preview"
        [contentContainerStyle]="{ paddingTop: 12, paddingHorizontal: 20, paddingBottom: safeArea.insets().bottom + 16 }"
      >
        <app-markdown-view [source]="body()" (toggleTask)="onToggleTask($event)" />
      </scroll-view>
    }
  `,
  styles: `
    .nav {
      height: 44px;
      flex-direction: row;
      align-items: center;
      justify-content: space-between;
      background-color: var(--bg);
    }
    .back {
      padding-left: 16px;
      height: 44px;
      justify-content: center;
    }
    .back-text {
      font-size: 17px;
      color: var(--accent);
    }
    .actions {
      flex-direction: row;
      align-items: center;
      gap: 12px;
    }
    .delete {
      height: 44px;
      justify-content: center;
    }
    .share-text {
      font-size: 17px;
      color: var(--accent);
    }
    .delete-text {
      font-size: 17px;
      color: var(--danger);
    }
    .star {
      width: 44px;
      height: 44px;
      margin-right: 16px;
      align-items: center;
      justify-content: center;
    }
    .star-text {
      font-size: 22px;
      color: var(--text-tertiary);
    }
    .starred {
      color: var(--star);
    }
    .segments {
      margin-top: 4px;
      margin-left: 16px;
      margin-right: 16px;
    }
    .card {
      flex: 1;
      margin-top: 12px;
      margin-left: 16px;
      margin-right: 16px;
      padding: 16px;
      border-radius: 14px;
      background-color: var(--surface);
    }
    .input {
      flex: 1;
      padding: 0;
      font-family: var(--mono, Menlo);
      font-size: 15px;
      line-height: 22px;
      color: var(--text);
    }
    .preview {
      flex: 1;
    }
  `,
})
export class EditorScreen {
  private readonly store = inject(NotesStore);
  private readonly keyboard = inject(Keyboard);
  protected readonly safeArea = inject(SafeArea);
  private readonly sharing = inject(Sharing);
  private readonly keyboardExcludesInset = inject(KEYBOARD_EXCLUDES_BOTTOM_INSET);

  readonly noteId = input.required<string>();
  readonly isNew = input(false);
  readonly back = output<void>();
  readonly delete = output<void>();

  private readonly chosenMode = signal<EditorMode | null>(null);
  protected readonly mode = computed<EditorMode>(() => this.chosenMode() ?? (this.isNew() ? 'edit' : 'preview'));
  /** Only a freshly created note raises the keyboard on its own. */
  protected readonly focusOnMount = computed(() => this.isNew() && this.chosenMode() === null);

  private readonly note = computed(() => this.store.get(this.noteId()));
  protected readonly body = computed(() => this.note()?.body ?? '');
  protected readonly starred = computed(() => this.note()?.starred ?? false);

  protected readonly cardBottom = computed(() => {
    const kb = this.keyboard.height();
    const inset = this.safeArea.insets().bottom;
    if (kb <= 0) return inset + 16;
    return kb + (this.keyboardExcludesInset ? inset : 0) + 16;
  });

  protected setMode(mode: EditorMode): void {
    if (mode === 'preview') this.keyboard.dismiss();
    this.chosenMode.set(mode);
  }

  protected onChange(text: string): void {
    this.store.updateBody(this.noteId(), text);
  }

  protected onToggleTask(index: number): void {
    const next = toggleTask(this.body(), index);
    if (next !== this.body()) this.store.updateBody(this.noteId(), next);
  }

  /** Opens the native share sheet (UIActivityViewController / Android chooser) with the raw markdown. */
  protected share(): void {
    this.keyboard.dismiss();
    void this.sharing.share({ message: this.body() }).catch((error: unknown) => {
      console.warn('[editor] share failed', error);
    });
  }

  protected toggleStar(): void {
    this.store.toggleStar(this.noteId());
  }
}
