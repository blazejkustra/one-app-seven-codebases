import 'package:flutter/cupertino.dart';

import '../data/note.dart';
import '../markdown/note_text.dart';
import 'tokens.dart';

/// A tappable region that exposes an iOS accessibilityIdentifier.
class Tappable extends StatelessWidget {
  const Tappable({
    super.key,
    required this.identifier,
    required this.onTap,
    required this.child,
    this.label,
    this.selected,
    this.toggled,
  });

  final String identifier;
  final VoidCallback onTap;
  final Widget child;
  final String? label;
  final bool? selected;
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: identifier,
      container: true,
      button: toggled == null,
      label: label,
      selected: selected,
      toggled: toggled,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        excludeFromSemantics: true,
        child: label == null ? child : ExcludeSemantics(child: child),
      ),
    );
  }
}

/// Large-title header used by the three tab screens (spec §3.2).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: sf(34, weight: FontWeight.w700),
                  maxLines: 1,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Note card used in the Notes and Starred lists (spec §3.3).
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.showSnippet,
    required this.onTap,
  });

  final Note note;
  final bool showSnippet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final snippet = showSnippet ? noteSnippet(note.body) : '';
    final tags = noteTags(note.body);
    final tasks = noteTasks(note.body);
    return Tappable(
      identifier: 'note-card',
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              noteTitle(note.body),
              style: sf(17, weight: FontWeight.w600, lineHeight: 22),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (snippet.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                snippet,
                style: sf(15, color: AppColors.textSecondary, lineHeight: 20),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              _TagChips(tags: tags),
            ],
            const SizedBox(height: 8),
            SizedBox(
              height: 18,
              child: Row(
                children: [
                  Text(
                    formatNoteDate(note.updatedAt),
                    style: sf(13, color: AppColors.textTertiary),
                  ),
                  if (tasks.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text(
                      '${tasks.where((t) => t).length}/${tasks.length} done',
                      style: sf(13, color: AppColors.textSecondary),
                    ),
                  ],
                  const Spacer(),
                  if (note.starred)
                    Text(
                      '★',
                      style: sf(16, color: AppColors.star, lineHeight: 18),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered empty-state text (spec §3.3 / §3.4).
class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        identifier: 'empty-state',
        container: true,
        child: Text(text, style: sf(17, color: AppColors.textTertiary)),
      ),
    );
  }
}

/// Vertical list of note cards (or an empty state).
class NoteList extends StatelessWidget {
  const NoteList({
    super.key,
    required this.notes,
    required this.showSnippets,
    required this.emptyText,
    required this.onOpen,
  });

  final List<Note> notes;
  final bool showSnippets;
  final String emptyText;
  final ValueChanged<Note> onOpen;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return EmptyState(emptyText);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: notes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => NoteCard(
        key: ValueKey(notes[i].id),
        note: notes[i],
        showSnippet: showSnippets,
        onTap: () => onOpen(notes[i]),
      ),
    );
  }
}

/// Custom pill switch (spec §3.5).
class PillSwitch extends StatelessWidget {
  const PillSwitch({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 51,
      height: 31,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: value ? AppColors.accent : AppColors.fill,
        borderRadius: BorderRadius.circular(15.5),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Single-line row of tag chips on a note card (iteration 2). Overflow is
/// clipped.
class _TagChips extends StatelessWidget {
  const _TagChips({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: 0,
          maxWidth: double.infinity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < tags.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Container(
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    '#${tags[i]}',
                    style: sf(
                      12,
                      weight: FontWeight.w500,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Selectable filter chip for the Notes tab tag row (iteration 2).
class TagFilterChip extends StatelessWidget {
  const TagFilterChip({
    super.key,
    required this.label,
    required this.identifier,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String identifier;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      identifier: identifier,
      selected: selected,
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: sf(
            15,
            weight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.white : AppColors.text,
          ),
        ),
      ),
    );
  }
}
