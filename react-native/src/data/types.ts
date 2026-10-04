export type Note = {
  id: string;
  body: string;
  starred: boolean;
  updatedAt: number; // epoch milliseconds
};

export type SortOrder = 'updated' | 'title';

export type Appearance = 'system' | 'light' | 'dark';

export type Settings = {
  appearance: Appearance;
  sortBy: SortOrder;
  showSnippets: boolean;
};
