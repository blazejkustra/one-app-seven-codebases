import Foundation

/// Loads Lynx bundles that are embedded in the app bundle (no dev server).
final class BundleTemplateProvider: NSObject, LynxTemplateProvider {
  func loadTemplate(withUrl url: String!, onComplete callback: LynxTemplateLoadBlock!) {
    guard let path = Bundle.main.path(forResource: url, ofType: "bundle") else {
      callback(nil, NSError(domain: "com.mdnotes.lynx", code: 404,
                            userInfo: [NSLocalizedDescriptionKey: "Bundle \(url ?? "") not found"]))
      return
    }
    do {
      callback(try Data(contentsOf: URL(fileURLWithPath: path)), nil)
    } catch {
      callback(nil, error)
    }
  }
}
