export interface Note {
  id: string;
  body: string;
  starred: boolean;
  /** Milliseconds since epoch. */
  updatedAt: number;
}

export type SortMode = 'updated' | 'title';

export type Appearance = 'system' | 'light' | 'dark';

export interface Settings {
  sort: SortMode;
  showSnippets: boolean;
  appearance: Appearance;
}

export const DEFAULT_SETTINGS: Settings = { sort: 'updated', showSnippets: true, appearance: 'system' };
