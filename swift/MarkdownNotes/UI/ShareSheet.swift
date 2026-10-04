import UIKit

/// Presents the native iOS share sheet (UIActivityViewController) with plain text.
@MainActor
enum ShareSheet {
    static func present(text: String) {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } ?? UIApplication.shared.connectedScenes.first as? UIWindowScene
        guard var top = scene?.keyWindow?.rootViewController ?? scene?.windows.first?.rootViewController else { return }
        while let presented = top.presentedViewController { top = presented }

        let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            popover.sourceView = top.view
            popover.sourceRect = CGRect(x: top.view.bounds.maxX - 100, y: 80, width: 1, height: 1)
        }
        top.present(controller, animated: true)
    }
}
