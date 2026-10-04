import 'package:flutter/widgets.dart';
import 'package:markdown/markdown.dart' as md;

import '../ui/tokens.dart';
import 'note_text.dart';

/// Inline syntax that turns `#tag` into a `tag` element (iteration 2).
/// Code spans are matched by their own syntax first, so tags never appear
/// inside inline code; fenced code is block-level and never inline-parsed.
class _TagSyntax extends md.InlineSyntax {
  _TagSyntax() : super(tagPattern.pattern, startCharacter: 0x23);

  @override
  RegExp get pattern => tagPattern;

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('tag', match[0]!));
    return true;
  }
}

/// GFM without ordered-list checkboxes: only `- [ ]` / `* [ ]` lines are
/// tasks (iteration 3), matching [taskLinePattern].
final _extensions = md.ExtensionSet(const [
  md.FencedCodeBlockSyntax(),
  md.TableSyntax(),
  md.UnorderedListWithCheckboxSyntax(),
  md.FootnoteDefSyntax(),
], md.ExtensionSet.gitHubFlavored.inlineSyntaxes);

/// Renders markdown (parsed with `package:markdown`) using the styles in
/// spec §4. Vertical margins between blocks collapse like CSS margins.
class MarkdownView extends StatelessWidget {
  const MarkdownView({super.key, required this.source, this.onToggleTask});

  final String source;

  /// Called with the task's document-order index when it is tapped.
  final ValueChanged<int>? onToggleTask;

  @override
  Widget build(BuildContext context) {
    final doc = md.Document(
      extensionSet: _extensions,
      inlineSyntaxes: [_TagSyntax()],
      encodeHtml: false,
    );
    return _Renderer(onToggleTask).render(doc.parse(source));
  }
}

class _Renderer {
  _Renderer(this.onToggleTask);

  final ValueChanged<int>? onToggleTask;
  int _taskIndex = 0;

  static TextStyle get _baseStyle => sf(17, lineHeight: 24);

  Widget render(List<md.Node> nodes) => _stack(_blocks(nodes, _baseStyle));

  // ---- Blocks --------------------------------------------------------------

  List<_Block> _blocks(List<md.Node> nodes, TextStyle base) {
    final out = <_Block>[];
    for (final node in nodes) {
      final block = _block(node, base);
      if (block != null) out.add(block);
    }
    return out;
  }

  Widget _stack(List<_Block> blocks) {
    final children = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      if (i > 0) {
        final gap = blocks[i - 1].bottom > blocks[i].top
            ? blocks[i - 1].bottom
            : blocks[i].top;
        children.add(SizedBox(height: gap));
      }
      children.add(blocks[i].child);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  _Block? _block(md.Node node, TextStyle base) {
    if (node is md.Text) {
      final text = node.text.trim();
      if (text.isEmpty) return null;
      return _Block(_rich([node], base), 0, 12);
    }
    if (node is! md.Element) return null;
    switch (node.tag) {
      case 'h1':
        return _Block(
          _rich(node.children, sf(28, weight: FontWeight.w700, lineHeight: 34)),
          0,
          12,
        );
      case 'h2':
        return _Block(
          _rich(node.children, sf(22, weight: FontWeight.w700, lineHeight: 28)),
          16,
          8,
        );
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        return _Block(
          _rich(node.children, sf(18, weight: FontWeight.w600, lineHeight: 24)),
          12,
          6,
        );
      case 'p':
        return _Block(_rich(node.children, base), 0, 12);
      case 'ul':
      case 'ol':
        return _Block(_list(node, base), 0, 12);
      case 'blockquote':
        return _Block(_quote(node, base), 0, 12);
      case 'pre':
        return _Block(_codeBlock(node), 0, 12);
      case 'hr':
        return _Block(Container(height: 1, color: AppColors.separator), 0, 12);
      default:
        // Unsupported block (e.g. table): fall back to its plain text.
        return _Block(Text(node.textContent, style: base), 0, 12);
    }
  }

  /// Removes and returns the GFM checkbox of a task list item, if any.
  md.Element? _takeCheckbox(md.Element item) {
    final children = item.children;
    if (children == null || children.isEmpty) return null;
    bool isBox(md.Node n) => n is md.Element && n.tag == 'input';
    if (isBox(children.first)) return children.removeAt(0) as md.Element;
    final first = children.first;
    if (first is md.Element &&
        first.tag == 'p' &&
        (first.children?.isNotEmpty ?? false) &&
        isBox(first.children!.first)) {
      return first.children!.removeAt(0) as md.Element;
    }
    return null;
  }

  Widget _list(md.Element list, TextStyle base) {
    final ordered = list.tag == 'ol';
    final start = int.tryParse(list.attributes['start'] ?? '') ?? 1;
    final items = list.children?.whereType<md.Element>().toList() ?? const [];
    final boxes = [for (final item in items) _takeCheckbox(item)];
    // Give every marker the width of the widest one so item text aligns.
    double markerWidth = 0;
    for (var i = 0; i < items.length; i++) {
      final painter = TextPainter(
        text: TextSpan(text: ordered ? '${start + i}.' : '•', style: base),
        textDirection: TextDirection.ltr,
      )..layout();
      if (painter.width > markerWidth) markerWidth = painter.width;
      painter.dispose();
    }
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final box = boxes[i];
      if (i > 0) {
        // 8 pt between task rows, 4 pt between bullets, 12 pt between groups.
        final prevTask = boxes[i - 1] != null;
        final gap = prevTask && box != null
            ? 8.0
            : (prevTask != (box != null) ? 12.0 : 4.0);
        rows.add(SizedBox(height: gap));
      }
      if (box != null) {
        rows.add(_taskRow(items[i], box.attributes['checked'] == 'true', base));
        continue;
      }
      final marker = ordered ? '${start + i}.' : '•';
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: markerWidth,
              child: Text(marker, style: base),
            ),
            const SizedBox(width: 8),
            Expanded(child: _listItemBody(items[i], base)),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  Widget _taskRow(md.Element item, bool checked, TextStyle base) {
    final index = _taskIndex++;
    final style = checked
        ? base.copyWith(
            color: AppColors.textTertiary,
            decoration: TextDecoration.lineThrough,
            decorationColor: AppColors.textTertiary,
          )
        : base;
    final toggle = onToggleTask == null ? null : () => onToggleTask!(index);
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checked ? AppColors.accent : null,
                borderRadius: BorderRadius.circular(6),
                border: checked
                    ? null
                    : Border.all(color: AppColors.textTertiary, width: 2),
              ),
              child: checked
                  ? Text(
                      '✓',
                      style: sf(
                        14,
                        weight: FontWeight.w700,
                        color: AppColors.white,
                        lineHeight: 16,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _listItemBody(item, style)),
      ],
    );
    return Semantics(
      identifier: 'task-$index',
      container: true,
      button: true,
      value: checked ? 'checked' : 'unchecked',
      onTap: toggle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: toggle,
        child: row,
      ),
    );
  }

  Widget _listItemBody(md.Element item, TextStyle base) {
    final children = item.children ?? const <md.Node>[];
    final hasBlocks = children.any(
      (c) =>
          c is md.Element &&
          const {
            'p',
            'ul',
            'ol',
            'blockquote',
            'pre',
            'h1',
            'h2',
            'h3',
          }.contains(c.tag),
    );
    if (!hasBlocks) return _rich(children, base);
    final blocks = _blocks(children, base);
    return _stack(blocks);
  }

  Widget _quote(md.Element quote, TextStyle base) {
    final quoteStyle = base.copyWith(
      fontStyle: FontStyle.italic,
      color: AppColors.textSecondary,
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 3, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: _stack(_blocks(quote.children ?? const [], quoteStyle)),
          ),
        ],
      ),
    );
  }

  Widget _codeBlock(md.Element pre) {
    var code = pre.textContent;
    if (code.endsWith('\n')) code = code.substring(0, code.length - 1);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.codeBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          code,
          style: mono(14, color: AppColors.codeText, lineHeight: 20),
        ),
      ),
    );
  }

  // ---- Inlines -------------------------------------------------------------

  Widget _rich(List<md.Node>? nodes, TextStyle style) => Text.rich(
    TextSpan(style: style, children: _inlines(nodes ?? const [], style)),
  );

  List<InlineSpan> _inlines(List<md.Node> nodes, TextStyle style) {
    final spans = <InlineSpan>[];
    for (final node in nodes) {
      if (node is md.Text) {
        // Soft line breaks inside a paragraph render as spaces.
        spans.add(TextSpan(text: node.text.replaceAll('\n', ' ')));
        continue;
      }
      if (node is! md.Element) continue;
      switch (node.tag) {
        case 'strong':
          final s = style.copyWith(fontWeight: FontWeight.w700);
          spans.add(TextSpan(style: s, children: _inlines(node.children!, s)));
        case 'em':
          final s = style.copyWith(fontStyle: FontStyle.italic);
          spans.add(TextSpan(style: s, children: _inlines(node.children!, s)));
        case 'del':
          final s = style.copyWith(decoration: TextDecoration.lineThrough);
          spans.add(TextSpan(style: s, children: _inlines(node.children!, s)));
        case 'a':
          final s = style.copyWith(color: AppColors.accent);
          spans.add(
            TextSpan(
              style: s,
              children: _inlines(node.children ?? const [], s),
            ),
          );
        case 'code':
          spans.add(_inlineCode(node.textContent));
        case 'tag':
          spans.add(
            TextSpan(
              text: node.textContent,
              style: style.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        case 'br':
          spans.add(const TextSpan(text: '\n'));
        case 'img':
          spans.add(TextSpan(text: node.attributes['alt'] ?? ''));
        default:
          spans.add(TextSpan(text: node.textContent));
      }
    }
    return spans;
  }

  InlineSpan _inlineCode(String code) => WidgetSpan(
    alignment: PlaceholderAlignment.baseline,
    baseline: TextBaseline.alphabetic,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(code, style: mono(15, color: AppColors.accent)),
    ),
  );
}

class _Block {
  const _Block(this.child, this.top, this.bottom);
  final Widget child;
  final double top;
  final double bottom;
}
