import SwiftUI
import UIKit

/// Renders `MDBlock`s with the typography from spec §4.
struct MarkdownView: View {
    let blocks: [MDBlock]

    init(source: String) { blocks = MarkdownParser.parse(source) }
    init(blocks: [MDBlock]) { self.blocks = blocks }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                BlockView(block: block)
                    .padding(.top, gap(before: index))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Collapsing vertical margins (like CSS): max(previous bottom, next top).
    private func gap(before index: Int) -> CGFloat {
        guard index > 0 else { return 0 }
        return max(Self.margins(blocks[index - 1]).bottom, Self.margins(blocks[index]).top)
    }

    static func margins(_ block: MDBlock) -> (top: CGFloat, bottom: CGFloat) {
        switch block {
        case .heading(let level, _):
            switch level {
            case 1: return (0, 12)
            case 2: return (16, 8)
            default: return (12, 6)
            }
        default: return (0, 12)
        }
    }
}

private struct BlockView: View {
    let block: MDBlock

    var body: some View {
        switch block {
        case .heading(let level, let runs):
            let size: CGFloat = level == 1 ? 28 : level == 2 ? 22 : 18
            let weight: UIFont.Weight = level <= 2 ? .bold : .semibold
            RichText(text: InlineText.attributed(runs, size: size, weight: weight,
                                                 lineHeight: (size * 1.2).rounded(), color: .mdText))
                .accessibilityAddTraits(.isHeader)
        case .paragraph(let runs):
            RichText(text: InlineText.attributed(runs, size: 17))
        case .list(let ordered, let start, let items):
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                    Group {
                        if let task = item.task {
                            TaskRow(task: task, blocks: item.blocks)
                        } else {
                            HStack(alignment: .top, spacing: 8) {
                                RichText(text: TextStyle.plain(ordered ? "\(start + i)." : "•",
                                                               font: TextStyle.font(size: 17), color: .mdText, lineHeight: 24))
                                    .fixedSize()
                                ListItemView(blocks: item.blocks)
                            }
                        }
                    }
                    // Task rows are 8 pt apart, other items 4 pt.
                    .padding(.top, i == 0 ? 0 : (item.task != nil && items[i - 1].task != nil ? 8 : 4))
                }
            }
        case .quote(let blocks):
            HStack(alignment: .top, spacing: 12) {
                Rectangle().fill(Theme.accent).frame(width: 3)
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(blocks.enumerated()), id: \.offset) { _, b in
                        if case .paragraph(let runs) = b {
                            RichText(text: InlineText.attributed(runs.map { var r = $0; r.italic = true; return r },
                                                                 size: 17, color: .mdTextSecondary))
                        } else {
                            BlockView(block: b)
                        }
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        case .code(let code):
            ScrollView(.horizontal, showsIndicators: false) {
                RichText(text: TextStyle.plain(code, font: TextStyle.mono(14), color: .mdCodeText,
                                               lineHeight: 20, lineBreak: .byClipping))
                    .fixedSize()
                    .padding(12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.codeBg, in: RoundedRectangle(cornerRadius: 10))
        case .rule:
            Rectangle().fill(Theme.separator).frame(height: 1)
        }
    }
}

extension EnvironmentValues {
    /// Called with the 1-based source line of a task item the user toggled in Preview.
    @Entry var toggleTask: ((Int) -> Void)? = nil
}

/// Interactive checklist row: 22×22 checkbox, 10 pt gap, 17 pt text.
private struct TaskRow: View {
    let task: MDListItem.Task
    let blocks: [MDBlock]
    @Environment(\.toggleTask) private var toggleTask

    var body: some View {
        let label = blocks.compactMap { b -> [MDRun]? in
            if case .paragraph(let runs) = b { return runs } else { return nil }
        }.flatMap { $0 }
        let nested = blocks.filter { if case .paragraph = $0 { return false } else { return true } }

        VStack(alignment: .leading, spacing: 4) {
            Button { toggleTask?(task.line) } label: {
                HStack(alignment: .top, spacing: 10) {
                    checkbox.padding(.top, 1)
                    RichText(text: text(label))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label.map(\.text).joined())
            .accessibilityValue(task.checked ? "checked" : "unchecked")
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("task-\(task.index)")

            ForEach(Array(nested.enumerated()), id: \.offset) { _, b in
                BlockView(block: b).padding(.leading, 32)
            }
        }
    }

    private var checkbox: some View {
        ZStack {
            if task.checked {
                RoundedRectangle(cornerRadius: 6).fill(Theme.accent)
                Text("✓").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
            } else {
                RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.textTertiary, lineWidth: 2)
            }
        }
        .frame(width: 22, height: 22)
    }

    private func text(_ runs: [MDRun]) -> NSAttributedString {
        let base = InlineText.attributed(runs, size: 17)
        guard task.checked else { return base }
        let m = NSMutableAttributedString(attributedString: base)
        let all = NSRange(location: 0, length: m.length)
        let tertiary = Palette.textTertiary
        m.addAttributes([.foregroundColor: tertiary,
                         .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                         .strikethroughColor: tertiary], range: all)
        return m
    }
}

/// Content of a list item: paragraphs inline, nested blocks underneath.
private struct ListItemView: View {
    let blocks: [MDBlock]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, b in
                if case .paragraph(let runs) = b {
                    RichText(text: InlineText.attributed(runs, size: 17))
                } else {
                    BlockView(block: b)
                }
            }
        }
    }
}

enum InlineText {
    static func attributed(_ runs: [MDRun], size: CGFloat, weight: UIFont.Weight = .regular,
                           lineHeight: CGFloat = 24, color: UIColor = .mdText) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for run in runs {
            if run.code {
                let mono = TextStyle.mono(15)
                var attrs = TextStyle.attributes(font: mono, color: .mdAccent, lineHeight: lineHeight)
                attrs[.backgroundColor] = UIColor.mdAccentSoft
                // Narrow padding inside the highlighted background.
                var padAttrs = TextStyle.attributes(font: TextStyle.font(size: size), color: color, lineHeight: lineHeight)
                padAttrs[.backgroundColor] = UIColor.mdAccentSoft
                result.append(NSAttributedString(string: "\u{2009}", attributes: padAttrs))
                result.append(NSAttributedString(string: run.text, attributes: attrs))
                result.append(NSAttributedString(string: "\u{2009}", attributes: padAttrs))
            } else if run.tag {
                let font = TextStyle.font(size: size, weight: run.bold ? .bold : max(weight, .medium), italic: run.italic)
                result.append(NSAttributedString(
                    string: run.text,
                    attributes: TextStyle.attributes(font: font, color: .mdAccent, lineHeight: lineHeight)))
            } else {
                let font = TextStyle.font(size: size, weight: run.bold ? .bold : weight, italic: run.italic)
                result.append(NSAttributedString(
                    string: run.text,
                    attributes: TextStyle.attributes(font: font, color: color, lineHeight: lineHeight)))
            }
        }
        return result
    }
}
