import { Component, input, output } from '@angular/core';
import { ScrollView, Text, View } from '@ng-native/components';
import type { Note } from '../data/note.ts';
import { NoteCard } from './note-card.ts';

/** The scrolling card list shared by the Notes and Starred tabs, with its empty state. */
@Component({
  selector: 'app-note-list',
  imports: [NoteCard, ScrollView, Text, View],
  host: { style: 'flex: 1' },
  template: `
    @if (notes().length === 0) {
      <view class="empty">
        @if (ready()) {
          <text testID="empty-state" class="empty-text">{{ emptyText() }}</text>
        }
      </view>
    } @else {
      <scroll-view
        class="list"
        keyboardShouldPersistTaps="handled"
        keyboardDismissMode="on-drag"
        [contentContainerStyle]="{ paddingTop: 12, paddingHorizontal: 16, paddingBottom: 16, gap: 12 }"
      >
        @for (note of notes(); track note.id) {
          <app-note-card [note]="note" [showSnippet]="showSnippets()" (open)="open.emit($event)" />
        }
      </scroll-view>
    }
  `,
  styles: `
    .list {
      flex: 1;
    }
    .empty {
      flex: 1;
      align-items: center;
      justify-content: center;
    }
    .empty-text {
      font-size: 17px;
      color: var(--text-tertiary);
    }
  `,
})
export class NoteList {
  readonly notes = input.required<readonly Note[]>();
  readonly showSnippets = input(true);
  readonly emptyText = input.required<string>();
  readonly ready = input(true);
  readonly open = output<string>();
}
