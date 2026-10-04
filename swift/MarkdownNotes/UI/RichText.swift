import SwiftUI
import UIKit

/// UILabel-backed text. Used for wrapped text so that line breaking matches a plain
/// greedy layout (no orphan "push-out") and line heights are exact, like the mockups.
struct RichText: UIViewRepresentable {
    let text: NSAttributedString
    var lineLimit: Int = 0

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = lineLimit
        label.lineBreakStrategy = []
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.attributedText = text
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        label.numberOfLines = lineLimit
        if label.attributedText != text { label.attributedText = text }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
        let width = proposal.width ?? UIView.layoutFittingExpandedSize.width
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: min(width, ceil(size.width)), height: ceil(size.height))
    }
}

enum TextStyle {
    static func font(size: CGFloat, weight: UIFont.Weight = .regular, italic: Bool = false) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard italic, let d = base.fontDescriptor.withSymbolicTraits(
            base.fontDescriptor.symbolicTraits.union(.traitItalic)) else { return base }
        return UIFont(descriptor: d, size: size)
    }

    static func mono(_ size: CGFloat) -> UIFont {
        UIFont(name: Theme.mono, size: size) ?? .monospacedSystemFont(ofSize: size, weight: .regular)
    }

    /// Attributes giving a fixed CSS-like line height with the glyphs vertically centred.
    static func attributes(font: UIFont, color: UIColor, lineHeight: CGFloat,
                           lineBreak: NSLineBreakMode = .byWordWrapping) -> [NSAttributedString.Key: Any] {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        style.lineBreakMode = lineBreak
        style.lineBreakStrategy = []
        return [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style,
            .baselineOffset: (lineHeight - font.lineHeight) / 4,
        ]
    }

    static func plain(_ string: String, font: UIFont, color: UIColor, lineHeight: CGFloat,
                      lineBreak: NSLineBreakMode = .byWordWrapping) -> NSAttributedString {
        NSAttributedString(string: string, attributes: attributes(font: font, color: color, lineHeight: lineHeight, lineBreak: lineBreak))
    }
}

extension UIColor {
    static let mdText = Palette.text
    static let mdTextSecondary = Palette.textSecondary
    static let mdAccent = Palette.accent
    static let mdAccentSoft = Palette.accentSoft
    static let mdCodeText = Palette.codeText
}
