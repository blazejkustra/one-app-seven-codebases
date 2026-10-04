import SwiftUI
import UIKit

/// Plain multiline editor (UITextView) with Menlo 15 / 22pt line height and no extra insets.
struct MarkdownTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var focusRequest: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> FocusableTextView {
        let tv = FocusableTextView()
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .sentences
        tv.smartQuotesType = .no
        tv.smartDashesType = .no
        tv.spellCheckingType = .no
        tv.keyboardDismissMode = .interactive
        tv.tintColor = Palette.accent
        tv.typingAttributes = Self.attributes
        tv.attributedText = NSAttributedString(string: text, attributes: Self.attributes)
        tv.accessibilityIdentifier = "editor-input"
        tv.delegate = context.coordinator
        return tv
    }

    func updateUIView(_ tv: FocusableTextView, context: Context) {
        context.coordinator.parent = self
        if tv.text != text {
            let selection = tv.selectedRange
            tv.attributedText = NSAttributedString(string: text, attributes: Self.attributes)
            tv.selectedRange = NSRange(location: min(selection.location, (text as NSString).length), length: 0)
        }
        if focusRequest {
            tv.pendingFocus = true
            tv.focusIfPossible()
            DispatchQueue.main.async { focusRequest = false }
        }
    }

    static var attributes: [NSAttributedString.Key: Any] {
        let font = UIFont(name: "Menlo", size: 15) ?? .monospacedSystemFont(ofSize: 15, weight: .regular)
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = 22
        style.maximumLineHeight = 22
        return [
            .font: font,
            .foregroundColor: Palette.text,
            .paragraphStyle: style,
            .baselineOffset: (22 - font.lineHeight) / 4,
        ]
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: MarkdownTextView
        init(_ parent: MarkdownTextView) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}

/// UITextView that can defer becoming first responder until it is in a window.
final class FocusableTextView: UITextView {
    var pendingFocus = false

    override func didMoveToWindow() {
        super.didMoveToWindow()
        focusIfPossible()
    }

    func focusIfPossible() {
        guard pendingFocus, window != nil else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.window != nil, self.pendingFocus else { return }
            if self.becomeFirstResponder() {
                self.pendingFocus = false
                let end = (self.text as NSString).length
                self.selectedRange = NSRange(location: end, length: 0)
            }
        }
    }
}
