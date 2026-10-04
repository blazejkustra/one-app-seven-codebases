import UIKit

/// `NativeModules.Share` — presents the native iOS share sheet with plain text.
@objcMembers
public final class ShareModule: NSObject, LynxModule {
  public static var name: String { "Share" }

  public static var methodLookup: [String: String] {
    ["shareText": NSStringFromSelector(#selector(shareText(_:)))]
  }

  public override init() { super.init() }
  public init(param: Any) { super.init() }

  public func shareText(_ text: NSString) {
    let body = text as String
    DispatchQueue.main.async {
      guard let root = UIApplication.shared.connectedScenes
        .compactMap({ ($0 as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow }) })
        .first?.rootViewController else { return }
      var top = root
      while let presented = top.presentedViewController { top = presented }
      let sheet = UIActivityViewController(activityItems: [body], applicationActivities: nil)
      sheet.popoverPresentationController?.sourceView = top.view
      top.present(sheet, animated: true)
    }
  }
}
