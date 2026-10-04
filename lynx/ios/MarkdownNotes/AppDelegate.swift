import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lynx must be initialised before any other Lynx API is used.
    LynxEnv.sharedInstance()

    let window = UIWindow(frame: UIScreen.main.bounds)
    // Apply the persisted appearance before the first frame.
    let appearance = (try? NotesDatabase.shared.allSettings()["appearance"]) ?? "system"
    window.overrideUserInterfaceStyle = AppearanceState.style(for: appearance)
    AppearanceState.refreshSystemScheme()
    window.rootViewController = LynxHostViewController()
    window.makeKeyAndVisible()
    self.window = window
    return true
  }
}
