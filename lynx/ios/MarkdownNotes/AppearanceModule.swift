import UIKit

/// Tracks the system colour scheme and applies the in-app appearance override.
enum AppearanceState {
  /// Last known *system* scheme ("light" / "dark"); only touched on the main thread,
  /// read (atomically enough for a String swap) from the JS thread.
  static var systemScheme: String = "light"

  static func refreshSystemScheme() {
    systemScheme = UIScreen.main.traitCollection.userInterfaceStyle == .dark ? "dark" : "light"
  }

  static func style(for mode: String) -> UIUserInterfaceStyle {
    switch mode {
    case "light": return .light
    case "dark": return .dark
    default: return .unspecified
    }
  }

  static func apply(_ mode: String) {
    let style = style(for: mode)
    for scene in UIApplication.shared.connectedScenes {
      (scene as? UIWindowScene)?.windows.forEach { $0.overrideUserInterfaceStyle = style }
    }
  }
}

/// `NativeModules.Appearance` — lets the Lynx UI set the window appearance override
/// (status bar, keyboard and native inputs follow it).
@objcMembers
public final class AppearanceModule: NSObject, LynxModule {
  public static var name: String { "Appearance" }

  public static var methodLookup: [String: String] {
    ["setAppearance": NSStringFromSelector(#selector(setAppearance(_:)))]
  }

  public override init() { super.init() }
  public init(param: Any) { super.init() }

  /// Sets "system" | "light" | "dark"; returns the current system scheme.
  public func setAppearance(_ mode: NSString) -> NSString {
    let value = mode as String
    DispatchQueue.main.async { AppearanceState.apply(value) }
    return AppearanceState.systemScheme as NSString
  }
}
