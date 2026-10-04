import UIKit

/// Hosts a single full-screen LynxView rendering the embedded `main.lynx.bundle`.
final class LynxHostViewController: UIViewController {
  private var lynxView: LynxView?
  private var lastSentScheme = AppearanceState.systemScheme

  // Status bar follows the effective (possibly overridden) appearance.
  override var preferredStatusBarStyle: UIStatusBarStyle { .default }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor { traits in
      traits.userInterfaceStyle == .dark
        ? .black
        : UIColor(red: 0xF5 / 255.0, green: 0xF5 / 255.0, blue: 0xF7 / 255.0, alpha: 1)
    }

    let size = UIScreen.main.bounds.size
    let lynxView = LynxView { builder in
      let config = LynxConfig(provider: BundleTemplateProvider())
      config.register(NotesStoreModule.self)
      config.register(AppearanceModule.self)
      config.register(ShareModule.self)
      config.registerUI(WordWrapTextArea.self, withName: "textarea")
      config.registerShadowNode(LynxUITextAreaShadowNode.self, withName: "textarea")
      config.registerUI(LynxUIInput.self, withName: "input")
      config.registerShadowNode(LynxUIInputShadowNode.self, withName: "input")
      builder.config = config
      builder.screenSize = size
      builder.fontScale = 1.0
    }
    lynxView.frame = CGRect(origin: .zero, size: size)
    lynxView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    lynxView.preferredLayoutWidth = size.width
    lynxView.preferredLayoutHeight = size.height
    lynxView.layoutWidthMode = .exact
    lynxView.layoutHeightMode = .exact
    view.addSubview(lynxView)
    self.lynxView = lynxView

    if #available(iOS 17.0, *) {
      registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _: UITraitCollection) in
        self.systemSchemeDidMaybeChange()
      }
    }
    lastSentScheme = AppearanceState.systemScheme
    lynxView.updateGlobalProps(with: safeAreaProps())
    lynxView.loadTemplate(fromURL: "main.lynx", initData: nil)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    systemSchemeDidMaybeChange()
  }

  private func systemSchemeDidMaybeChange() {
    // With no window override the view controller's traits *are* the system's.
    if view.window?.overrideUserInterfaceStyle ?? .unspecified == .unspecified {
      AppearanceState.systemScheme = traitCollection.userInterfaceStyle == .dark ? "dark" : "light"
    } else {
      AppearanceState.refreshSystemScheme()
    }
    if lastSentScheme != AppearanceState.systemScheme {
      lastSentScheme = AppearanceState.systemScheme
      lynxView?.updateGlobalProps(with: safeAreaProps())
      lynxView?.sendGlobalEvent("systemColorSchemeChanged", withParams: [AppearanceState.systemScheme])
    }
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    lynxView?.updateGlobalProps(with: safeAreaProps())
  }

  private func safeAreaProps() -> [String: Any] {
    var insets = view.safeAreaInsets
    if insets == .zero, let window = UIApplication.shared.connectedScenes
      .compactMap({ ($0 as? UIWindowScene)?.windows.first }).first {
      insets = window.safeAreaInsets
    }
    return [
      "safeAreaTop": insets.top > 0 ? Double(insets.top) : 62.0,
      "safeAreaBottom": insets.bottom > 0 ? Double(insets.bottom) : 34.0,
      "systemColorScheme": AppearanceState.systemScheme,
      "appearance": (try? NotesDatabase.shared.allSettings()["appearance"]) ?? "system",
    ]
  }
}
