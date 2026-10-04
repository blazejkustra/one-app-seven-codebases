import { Component, computed, effect, inject, output, signal } from '@angular/core';
import { Pressable, ScrollView, Text, TextInput } from '@ng-native/components';
import { hasTag, matchesQuery } from '../data/note.ts';
import { NotesStore } from '../data/notes-store.ts';
import { NoteList } from '../ui/note-list.ts';
import { ScreenHeader } from '../ui/screen-header.ts';

@Component({
  selector: 'app-notes-screen',
  imports: [NoteList, Pressable, ScreenHeader, ScrollView, Text, TextInput],
  host: { style: 'flex: 1' },
  template: `
    <app-screen-header title="Notes">
      <pressable
        testID="add-note-button"
        accessibilityRole="button"
        accessibilityLabel="New note"
        class="add"
        #p="pressable"
        [style.opacity]="p.pressed() ? 0.7 : 1"
        (press)="create.emit()"
      >
        <text class="plus">+</text>
      </pressable>
    </app-screen-header>
    <text-input
      testID="search-input"
      class="search"
      placeholder="Search notes"
      placeholderTextColor="#8E8E93"
      autoCapitalize="none"
      [autoCorrect]="false"
      returnKeyType="search"
      clearButtonMode="never"
      [value]="query()"
      (changeText)="query.set($event)"
    />
    <scroll-view
      class="filters"
      [horizontal]="true"
      [showsHorizontalScrollIndicator]="false"
      keyboardShouldPersistTaps="handled"
      [contentContainerStyle]="{ paddingHorizontal: 16, gap: 8 }"
    >
      <pressable
        testID="tag-filter-all"
        accessibilityRole="button"
        accessibilityLabel="All"
        [accessibilityState]="{ selected: activeTag() === null }"
        class="filter"
        [class.filter-on]="activeTag() === null"
        (press)="selectTag(null)"
      >
        <text class="filter-text" [class.filter-text-on]="activeTag() === null">All</text>
      </pressable>
      @for (tag of store.allTags(); track tag) {
        <pressable
          [testID]="'tag-filter-' + tag"
          accessibilityRole="button"
          [accessibilityLabel]="'#' + tag"
          [accessibilityState]="{ selected: activeTag() === tag }"
          class="filter"
          [class.filter-on]="activeTag() === tag"
          (press)="selectTag(tag)"
        >
          <text class="filter-text" [class.filter-text-on]="activeTag() === tag">#{{ tag }}</text>
        </pressable>
      }
    </scroll-view>
    <app-note-list
      [notes]="visible()"
      [showSnippets]="store.showSnippets()"
      [ready]="store.loaded()"
      [emptyText]="store.count() === 0 ? 'No notes yet' : 'No notes found'"
      (open)="open.emit($event)"
    />
  `,
  styles: `
    .add {
      width: 36px;
      height: 36px;
      border-radius: 18px;
      background-color: var(--accent);
      align-items: center;
      justify-content: center;
    }
    .plus {
      font-size: 24px;
      line-height: 28px;
      font-weight: 400;
      color: #ffffff;
    }
    .filters {
      margin-top: 12px;
      height: 32px;
      flex-grow: 0;
      flex-shrink: 0;
    }
    .filter {
      height: 32px;
      padding-left: 12px;
      padding-right: 12px;
      border-radius: 16px;
      background-color: var(--surface);
      justify-content: center;
    }
    .filter-on {
      background-color: var(--accent);
    }
    .filter-text {
      font-size: 15px;
      font-weight: 500;
      color: var(--text);
    }
    .filter-text-on {
      font-weight: 600;
      color: #ffffff;
    }
    .search {
      margin-top: 4px;
      margin-left: 16px;
      margin-right: 16px;
      height: 40px;
      border-radius: 10px;
      background-color: var(--fill);
      padding-left: 12px;
      padding-right: 12px;
      font-size: 17px;
      color: var(--text);
    }
  `,
})
export class NotesScreen {
  protected readonly store = inject(NotesStore);
  protected readonly query = signal('');
  private readonly selectedTag = signal<string | null>(null);
  /** The selected tag, or null (All) when no note carries it any more. */
  protected readonly activeTag = computed(() => {
    const tag = this.selectedTag();
    return tag !== null && this.store.allTags().includes(tag) ? tag : null;
  });
  protected readonly visible = computed(() =>
    this.store.sorted().filter((n) => matchesQuery(n, this.query()) && hasTag(n, this.activeTag())),
  );

  constructor() {
    // A tag that disappears drops the selection back to All for good.
    effect(() => {
      if (this.selectedTag() !== null && this.activeTag() === null) this.selectedTag.set(null);
    });
  }

  protected selectTag(tag: string | null): void {
    this.selectedTag.set(tag);
  }

  readonly create = output<void>();
  readonly open = output<string>();
}
