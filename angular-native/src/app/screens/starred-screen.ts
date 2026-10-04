import { Component, inject, output } from '@angular/core';
import { NotesStore } from '../data/notes-store.ts';
import { NoteList } from '../ui/note-list.ts';
import { ScreenHeader } from '../ui/screen-header.ts';

@Component({
  selector: 'app-starred-screen',
  imports: [NoteList, ScreenHeader],
  host: { style: 'flex: 1' },
  template: `
    <app-screen-header title="Starred" />
    <app-note-list
      [notes]="store.starred()"
      [showSnippets]="store.showSnippets()"
      [ready]="store.loaded()"
      emptyText="No starred notes"
      (open)="open.emit($event)"
    />
  `,
})
export class StarredScreen {
  protected readonly store = inject(NotesStore);
  readonly open = output<string>();
}
