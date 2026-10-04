import { Component, computed, input, output } from '@angular/core';
import { Pressable, Text, View } from '@ng-native/components';
import { type Note, formatDate, noteSnippet, noteTags, noteTitle, taskProgress } from '../data/note.ts';

@Component({
  selector: 'app-note-card',
  imports: [Pressable, Text, View],
  template: `
    <pressable
      testID="note-card"
      accessibilityRole="button"
      class="card"
      #p="pressable"
      [style.opacity]="p.pressed() ? 0.7 : 1"
      (press)="open.emit(note().id)"
    >
      <text class="title" [numberOfLines]="1">{{ title() }}</text>
      @if (showSnippet() && snippet()) {
        <text class="snippet" [numberOfLines]="2">{{ snippet() }}</text>
      }
      @if (tags().length > 0) {
        <view class="chips">
          @for (tag of tags(); track tag) {
            <view class="chip">
              <text class="chip-text" [numberOfLines]="1">#{{ tag }}</text>
            </view>
          }
        </view>
      }
      <view class="footer">
        <view class="meta">
          <text class="date">{{ date() }}</text>
          @if (progress().total > 0) {
            <text class="progress">{{ progress().done }}/{{ progress().total }} done</text>
          }
        </view>
        @if (note().starred) {
          <text class="star">★</text>
        }
      </view>
    </pressable>
  `,
  styles: `
    .card {
      background-color: var(--surface);
      border-radius: 14px;
      padding: 16px;
    }
    .title {
      font-size: 17px;
      line-height: 22px;
      font-weight: 600;
      color: var(--text);
    }
    .snippet {
      margin-top: 4px;
      font-size: 15px;
      line-height: 20px;
      color: var(--text-secondary);
    }
    .chips {
      margin-top: 8px;
      flex-direction: row;
      gap: 6px;
      overflow: hidden;
    }
    .chip {
      height: 22px;
      padding-left: 8px;
      padding-right: 8px;
      border-radius: 11px;
      background-color: var(--accent-soft);
      justify-content: center;
      flex-shrink: 0;
    }
    .chip-text {
      font-size: 12px;
      font-weight: 500;
      color: var(--accent);
    }
    .footer {
      margin-top: 8px;
      flex-direction: row;
      align-items: center;
      justify-content: space-between;
      height: 18px;
    }
    .date {
      font-size: 13px;
      line-height: 18px;
      color: var(--text-tertiary);
    }
    .meta {
      flex-direction: row;
      align-items: center;
      gap: 12px;
    }
    .progress {
      font-size: 13px;
      line-height: 18px;
      color: var(--text-secondary);
    }
    .star {
      font-size: 16px;
      line-height: 18px;
      color: var(--star);
    }
  `,
})
export class NoteCard {
  readonly note = input.required<Note>();
  readonly showSnippet = input(true);
  readonly open = output<string>();

  protected readonly title = computed(() => noteTitle(this.note().body));
  protected readonly snippet = computed(() => noteSnippet(this.note().body));
  protected readonly tags = computed(() => noteTags(this.note().body));
  protected readonly progress = computed(() => taskProgress(this.note().body));
  protected readonly date = computed(() => formatDate(this.note().updatedAt));
}
