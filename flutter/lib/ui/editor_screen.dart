import 'package:flutter/cupertino.dart';
import 'package:share_plus/share_plus.dart';

import '../data/note.dart';
import '../data/notes_store.dart';
import '../markdown/markdown_view.dart';
import '../markdown/note_text.dart';
import 'tokens.dart';
import 'widgets.dart';

/// Note editor with Edit / Preview modes (spec §3.6).
class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.store,
    required this.noteId,
    required this.isNew,
    required this.onDeleted,
  });

  final NotesStore store;
  final String noteId;
  final bool isNew;

  /// Called after the note was deleted with the Delete button, with the note
  /// as it was, so the caller can offer Undo.
  final ValueChanged<Note> onDeleted;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final TextEditingController _controller;
  final _focus = FocusNode();
  late bool _editing = widget.isNew;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.store.byId(widget.noteId)?.body ?? '',
    );
    // Autosave: every change is written through to SQLite immediately.
    _controller.addListener(
      () => widget.store.updateBody(widget.noteId, _controller.text),
    );
  }

  bool _finalized = false;

  /// Leaving the editor: flush the body and delete the note if it is empty.
  void _finalize() {
    if (_finalized) return;
    _finalized = true;
    final text = _controller.text;
    widget.store.updateBody(widget.noteId, text);
    if (text.trim().isEmpty) widget.store.delete(widget.noteId);
  }

  @override
  void dispose() {
    if (!_finalized) {
      final text = _controller.text;
      _finalized = true;
      Future.microtask(() {
        widget.store.updateBody(widget.noteId, text);
        if (text.trim().isEmpty) widget.store.delete(widget.noteId);
      });
    }
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Opens the native share sheet (UIActivityViewController via share_plus)
  /// with the raw markdown body as plain text (iteration 6).
  Future<void> _share(BuildContext buttonContext) async {
    final body = widget.store.byId(widget.noteId)?.body ?? _controller.text;
    final box = buttonContext.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: body,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  /// Deletes the note immediately (no confirmation) and leaves the editor.
  void _delete() {
    final note = widget.store.byId(widget.noteId);
    if (note == null) return;
    _finalized = true;
    _focus.unfocus();
    widget.store.delete(widget.noteId);
    Navigator.of(context).pop();
    widget.onDeleted(note);
  }

  void _setMode(bool editing) {
    if (editing == _editing) return;
    if (!editing) _focus.unfocus();
    setState(() => _editing = editing);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom;
    final bottom = (keyboard > 0 ? keyboard : mq.viewPadding.bottom) + 16;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _finalize();
      },
      child: ColoredBox(
        color: AppColors.bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: mq.viewPadding.top),
            _navRow(context),
            const SizedBox(height: 4),
            _SegmentedControl(editing: _editing, onChanged: _setMode),
            const SizedBox(height: 12),
            Expanded(
              child: _editing
                  ? _editor(bottom)
                  : _preview(mq.viewPadding.bottom + 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navRow(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Tappable(
            identifier: 'back-button',
            label: 'Notes',
            onTap: () => Navigator.of(context).maybePop(),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: SizedBox(
                height: 44,
                child: Center(
                  child: Text(
                    '‹ Notes',
                    style: sf(17, color: AppColors.accent),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          Builder(
            builder: (buttonContext) => Tappable(
              identifier: 'share-button',
              onTap: () => _share(buttonContext),
              child: SizedBox(
                height: 44,
                child: Center(
                  child: Text('Share', style: sf(17, color: AppColors.accent)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Tappable(
            identifier: 'delete-button',
            onTap: _delete,
            child: SizedBox(
              height: 44,
              child: Center(
                child: Text('Delete', style: sf(17, color: AppColors.danger)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ListenableBuilder(
            listenable: widget.store,
            builder: (context, _) {
              final starred =
                  widget.store.byId(widget.noteId)?.starred ?? false;
              return Tappable(
                identifier: 'star-button',
                label: starred ? 'Starred' : 'Not starred',
                selected: starred,
                onTap: () => widget.store.toggleStar(widget.noteId),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Text(
                        starred ? '★' : '☆',
                        style: sf(
                          22,
                          color: starred
                              ? AppColors.star
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _editor(double bottom) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Semantics(
          identifier: 'editor-input',
          child: CupertinoTextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: widget.isNew,
            decoration: null,
            padding: EdgeInsets.zero,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            keyboardAppearance: AppColors.dark
                ? Brightness.dark
                : Brightness.light,
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            style: mono(15, lineHeight: 22),
            cursorColor: AppColors.accent,
          ),
        ),
      ),
    );
  }

  Widget _preview(double bottom) {
    // The label makes the container a real accessibility element so the
    // identifier is exposed even when the content does not overflow.
    return Semantics(
      identifier: 'preview-view',
      label: 'Preview',
      container: true,
      explicitChildNodes: true,
      child: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 0, 20, bottom),
          child: MarkdownView(
            source: widget.store.byId(widget.noteId)?.body ?? '',
            // Rewriting the controller text saves through its listener,
            // which also bumps updatedAt and keeps Edit mode in sync.
            onToggleTask: (i) =>
                _controller.text = toggleTask(_controller.text, i),
          ),
        ),
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({required this.editing, required this.onChanged});

  final bool editing;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget segment(String label, String id, bool selected, bool value) {
      return Expanded(
        child: Tappable(
          identifier: id,
          selected: selected,
          onTap: () => onChanged(value),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: selected ? AppColors.surface : null,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: sf(
                15,
                weight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.text : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          segment('Edit', 'mode-edit', editing, true),
          segment('Preview', 'mode-preview', !editing, false),
        ],
      ),
    );
  }
}
