import Foundation
import Markdown

/// A minimal, view-friendly model of a parsed Markdown document.
/// Parsing is done by Apple's `swift-markdown` (cmark-gfm); this file only maps its AST.
struct MDRun: Equatable, Sendable {
    var text: String
    var bold = false
    var italic = false
    var code = false
    var tag = false
}

indirect enum MDBlock: Equatable, Sendable {
    case heading(level: Int, runs: [MDRun])
    case paragraph(runs: [MDRun])
    case list(ordered: Bool, start: Int, items: [MDListItem])
    case quote([MDBlock])
    case code(String)
    case rule
}

/// A list item; `task` is set for GFM task items (`- [ ] text` / `- [x] text`).
struct MDListItem: Equatable, Sendable {
    struct Task: Equatable, Sendable {
        var index: Int      // document order, used for `task-<index>` identifiers
        var checked: Bool
        var line: Int       // 1-based source line, used to rewrite the checkbox
    }
    var blocks: [MDBlock]
    var task: Task?
}

enum MarkdownParser {
    private final class State { var taskIndex = 0 }

    static func parse(_ source: String) -> [MDBlock] {
        let document = Document(parsing: source)
        let state = State()
        return document.children.compactMap { block($0, state) }
    }

    private static func items(_ list: ListItemContainer, _ state: State) -> [MDListItem] {
        list.listItems.map { item in
            var task: MDListItem.Task?
            if let checkbox = item.checkbox, let line = item.range?.lowerBound.line {
                task = .init(index: state.taskIndex, checked: checkbox == .checked, line: line)
                state.taskIndex += 1
            }
            return MDListItem(blocks: item.children.compactMap { block($0, state) }, task: task)
        }
    }

    private static func block(_ markup: Markup, _ state: State) -> MDBlock? {
        switch markup {
        case let h as Heading:
            return .heading(level: h.level, runs: inlines(h.children))
        case let p as Paragraph:
            return .paragraph(runs: inlines(p.children))
        case let l as UnorderedList:
            return .list(ordered: false, start: 1, items: items(l, state))
        case let l as OrderedList:
            return .list(ordered: true, start: Int(l.startIndex), items: items(l, state))
        case let q as BlockQuote:
            return .quote(q.children.compactMap { block($0, state) })
        case let c as CodeBlock:
            var code = c.code
            if code.hasSuffix("\n") { code.removeLast() }
            return .code(code)
        case let h as HTMLBlock:
            return .paragraph(runs: [MDRun(text: h.rawHTML.trimmingCharacters(in: .newlines))])
        case is ThematicBreak:
            return .rule
        default:
            let text = markup.format()
            return text.isEmpty ? nil : .paragraph(runs: [MDRun(text: text)])
        }
    }

    private static func inlines(_ children: MarkupChildren, bold: Bool = false, italic: Bool = false) -> [MDRun] {
        var runs: [MDRun] = []
        for child in children {
            switch child {
            case let t as Markdown.Text:
                let onTitleLine = (t.range?.lowerBound.line ?? 0) == 1
                let afterWord = runs.last.map { !($0.text.last?.isWhitespace ?? true) } ?? false
                runs += splitTags(t.string, bold: bold, italic: italic,
                                  enabled: !onTitleLine, afterWord: afterWord)
            case let s as Strong:
                runs += inlines(s.children, bold: true, italic: italic)
            case let e as Emphasis:
                runs += inlines(e.children, bold: bold, italic: true)
            case let c as InlineCode:
                runs.append(MDRun(text: c.code, bold: bold, italic: italic, code: true))
            case is SoftBreak:
                runs.append(MDRun(text: " ", bold: bold, italic: italic))
            case is LineBreak:
                runs.append(MDRun(text: "\n", bold: bold, italic: italic))
            case let s as Strikethrough:
                runs += inlines(s.children, bold: bold, italic: italic)
            case let l as Markdown.Link:
                runs += inlines(l.children, bold: bold, italic: italic)
            case let i as InlineHTML:
                runs.append(MDRun(text: i.rawHTML, bold: bold, italic: italic))
            default:
                runs.append(MDRun(text: child.format(), bold: bold, italic: italic))
            }
        }
        return runs
    }

    /// Splits plain text into normal and `#tag` runs.
    private static func splitTags(_ text: String, bold: Bool, italic: Bool,
                                  enabled: Bool, afterWord: Bool) -> [MDRun] {
        guard enabled else { return [MDRun(text: text, bold: bold, italic: italic)] }
        var runs: [MDRun] = []
        var cursor = text.startIndex
        for match in Tags.matches(in: text) {
            // A tag must start a line or follow whitespace, including across inline nodes.
            if match.range.lowerBound == text.startIndex && afterWord { continue }
            if cursor < match.range.lowerBound {
                runs.append(MDRun(text: String(text[cursor..<match.range.lowerBound]), bold: bold, italic: italic))
            }
            runs.append(MDRun(text: String(text[match.range]), bold: bold, italic: italic, tag: true))
            cursor = match.range.upperBound
        }
        if cursor < text.endIndex {
            runs.append(MDRun(text: String(text[cursor...]), bold: bold, italic: italic))
        }
        return runs
    }
}
