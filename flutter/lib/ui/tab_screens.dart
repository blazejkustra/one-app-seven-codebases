import 'package:flutter/cupertino.dart';

import '../data/note.dart';
import '../data/notes_store.dart';
import 'tokens.dart';
import 'widgets.dart';

/// Notes tab (spec §3.3).
class NotesScreen extends StatefulWidget {
  const NotesScreen({
    super.key,
    required this.store,
    required this.onOpen,
    required this.onCreate,
  });

  final NotesStore store;
  final ValueChanged<Note> onOpen;
  final VoidCallback onCreate;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _search = TextEditingController();

  /// Selected tag filter; null means `All`. Not persisted.
  String? _tag;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final tags = store.allTags;
    // A tag that no longer exists on any note falls back to `All`.
    if (_tag != null && !tags.contains(_tag)) _tag = null;
    final notes = store.search(_search.text, tag: _tag);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(
          title: 'Notes',
          trailing: Tappable(
            identifier: 'add-note-button',
            label: 'New note',
            onTap: widget.onCreate,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '+',
                style: sf(24, color: AppColors.white, lineHeight: 24),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 40,
            child: Semantics(
              identifier: 'search-input',
              child: CupertinoTextField(
                controller: _search,
                decoration: BoxDecoration(
                  color: AppColors.fill,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textAlignVertical: TextAlignVertical.center,
                placeholder: 'Search notes',
                placeholderStyle: sf(17, color: AppColors.textTertiary),
                style: sf(17),
                cursorColor: AppColors.accent,
                autocorrect: false,
                textInputAction: TextInputAction.search,
                keyboardAppearance: AppColors.dark
                    ? Brightness.dark
                    : Brightness.light,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tags.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final tag = i == 0 ? null : tags[i - 1];
              return TagFilterChip(
                label: tag == null ? 'All' : '#$tag',
                identifier: tag == null ? 'tag-filter-all' : 'tag-filter-$tag',
                selected: _tag == tag,
                onTap: () => setState(() => _tag = tag),
              );
            },
          ),
        ),
        Expanded(
          child: NoteList(
            notes: notes,
            showSnippets: store.showSnippets,
            emptyText: store.count == 0 ? 'No notes yet' : 'No notes found',
            onOpen: widget.onOpen,
          ),
        ),
      ],
    );
  }
}

/// Starred tab (spec §3.4).
class StarredScreen extends StatelessWidget {
  const StarredScreen({super.key, required this.store, required this.onOpen});

  final NotesStore store;
  final ValueChanged<Note> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ScreenHeader(title: 'Starred'),
        Expanded(
          child: NoteList(
            notes: store.starredNotes,
            showSnippets: store.showSnippets,
            emptyText: 'No starred notes',
            onOpen: onOpen,
          ),
        ),
      ],
    );
  }
}

/// Settings tab (spec §3.5).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.store});

  final NotesStore store;

  @override
  Widget build(BuildContext context) {
    final rowLabel = sf(17);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ScreenHeader(title: 'Settings'),
        const SizedBox(height: 12),
        _Group(
          children: [
            Tappable(
              identifier: 'sort-row',
              onTap: store.toggleSort,
              child: _Row(
                label: Text('Sort by', style: rowLabel),
                value: Text(
                  store.sort == SortOrder.updated ? 'Updated' : 'Title',
                  style: sf(17, color: AppColors.accent),
                ),
              ),
            ),
            _Row(
              label: Text('Show snippets', style: rowLabel),
              value: Tappable(
                identifier: 'snippets-switch',
                label: 'Show snippets',
                toggled: store.showSnippets,
                onTap: () => store.setShowSnippets(!store.showSnippets),
                child: PillSwitch(value: store.showSnippets),
              ),
            ),
            Tappable(
              identifier: 'appearance-row',
              onTap: store.cycleAppearance,
              child: _Row(
                label: Text('Appearance', style: rowLabel),
                value: Text(switch (store.appearance) {
                  Appearance.system => 'System',
                  Appearance.light => 'Light',
                  Appearance.dark => 'Dark',
                }, style: sf(17, color: AppColors.accent)),
              ),
            ),
            _Row(
              label: Text('Notes', style: rowLabel),
              value: Semantics(
                identifier: 'notes-count',
                container: true,
                child: Text(
                  '${store.count}',
                  style: sf(17, color: AppColors.textTertiary),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _Group(
          children: [
            Tappable(
              identifier: 'reset-button',
              onTap: store.resetSampleNotes,
              child: SizedBox(
                height: 52,
                child: Center(
                  child: Text(
                    'Reset sample notes',
                    style: sf(17, color: AppColors.danger),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Markdown Notes · v1.0',
          textAlign: TextAlign.center,
          style: sf(13, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Separators are drawn over the top edge of each following row so the
    // rows keep their exact 52 pt height.
    final rows = <Widget>[
      for (var i = 0; i < children.length; i++)
        if (i == 0)
          children[i]
        else
          Stack(
            children: [
              children[i],
              Positioned(
                top: 0,
                left: 16,
                right: 0,
                child: Container(height: 1, color: AppColors.separator),
              ),
            ],
          ),
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final Widget label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(child: label),
            value,
          ],
        ),
      ),
    );
  }
}
