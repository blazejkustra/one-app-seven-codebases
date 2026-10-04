import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../data/note.dart';
import '../data/notes_store.dart';
import 'editor_screen.dart';
import 'tab_screens.dart';
import 'tokens.dart';
import 'widgets.dart';

/// Root screen with the custom bottom tab bar (spec §3.1).
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});

  final NotesStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  /// The most recently deleted note while its Undo toast is visible.
  Note? _deleted;
  Timer? _toastTimer;

  void _showUndo(Note note) {
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 4), _hideToast);
    setState(() => _deleted = note);
  }

  void _hideToast() {
    _toastTimer?.cancel();
    _toastTimer = null;
    if (mounted) setState(() => _deleted = null);
  }

  void _undo() {
    final note = _deleted;
    _hideToast();
    if (note != null) widget.store.restore(note);
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _open(Note note, {bool isNew = false}) {
    // Drop search focus so it is not restored when the editor is popped.
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => EditorScreen(
          store: widget.store,
          noteId: note.id,
          isNew: isNew,
          onDeleted: _showUndo,
        ),
      ),
    );
  }

  void _create() => _open(widget.store.createNote(), isNew: true);

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);
    return ColoredBox(
      color: AppColors.bg,
      child: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: padding.top),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IndexedStack(
                      index: _tab,
                      children: [
                        NotesScreen(
                          store: widget.store,
                          onOpen: _open,
                          onCreate: _create,
                        ),
                        StarredScreen(store: widget.store, onOpen: _open),
                        SettingsScreen(store: widget.store),
                      ],
                    ),
                  ),
                  if (_deleted != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 12,
                      child: _UndoToast(onUndo: _undo),
                    ),
                ],
              ),
            ),
            _TabBar(
              index: _tab,
              bottomInset: padding.bottom,
              onSelect: (i) {
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() => _tab = i);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.index,
    required this.bottomInset,
    required this.onSelect,
  });

  final int index;
  final double bottomInset;
  final ValueChanged<int> onSelect;

  static const _labels = ['Notes', 'Starred', 'Settings'];
  static const _ids = ['tab-notes', 'tab-starred', 'tab-settings'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.separator, width: 1)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      // 1 pt top border + 55 = 56 pt bar above the safe area.
      child: SizedBox(
        height: 55,
        child: Row(
          children: [
            for (var i = 0; i < _labels.length; i++)
              Expanded(
                child: Tappable(
                  identifier: _ids[i],
                  selected: i == index,
                  onTap: () => onSelect(i),
                  child: Center(
                    child: Text(
                      _labels[i],
                      style: sf(
                        15,
                        weight: i == index ? FontWeight.w600 : FontWeight.w500,
                        color: i == index
                            ? AppColors.accent
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Note deleted · Undo" toast (iteration 4).
class _UndoToast extends StatelessWidget {
  const _UndoToast({required this.onUndo});

  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'toast',
      label: 'Note deleted',
      container: true,
      explicitChildNodes: true,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.toastBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: ExcludeSemantics(
                child: Text(
                  'Note deleted',
                  style: sf(15, color: const Color(0xFFFFFFFF)),
                ),
              ),
            ),
            Tappable(
              identifier: 'undo-button',
              onTap: onUndo,
              child: SizedBox(
                height: 48,
                child: Center(
                  child: Text(
                    'Undo',
                    style: sf(
                      15,
                      weight: FontWeight.w600,
                      color: const Color(0xFFA79FFF),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
