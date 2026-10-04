import Foundation

/// Lynx native module exposing the SQLite note store to JavaScript as
/// `NativeModules.NotesStore`. All calls are synchronous so that every edit is
/// committed to disk before control returns to JS.
@objcMembers
public final class NotesStoreModule: NSObject, LynxModule {
  public static var name: String { "NotesStore" }

  public static var methodLookup: [String: String] {
    [
      "loadNotes": NSStringFromSelector(#selector(loadNotes)),
      "loadSettings": NSStringFromSelector(#selector(loadSettings)),
      "upsertNote": NSStringFromSelector(#selector(upsertNote(_:))),
      "deleteNote": NSStringFromSelector(#selector(deleteNote(_:))),
      "replaceAllNotes": NSStringFromSelector(#selector(replaceAllNotes(_:))),
      "setSetting": NSStringFromSelector(#selector(setSetting(_:value:))),
    ]
  }

  private var store: NotesDatabase { NotesDatabase.shared }

  public override init() { super.init() }
  public init(param: Any) { super.init() }

  /// Returns a JSON array of notes, or `null` JSON if the store was never seeded.
  public func loadNotes() -> NSString {
    do {
      let settings = try store.allSettings()
      guard settings["seeded"] == "1" else { return "null" }
      let list = try store.allNotes().map { n -> [String: Any] in
        ["id": n.id, "body": n.body, "starred": n.starred, "updatedAt": n.updatedAt]
      }
      return Self.json(list)
    } catch {
      NSLog("NotesStore.loadNotes failed: \(error)")
      return "null"
    }
  }

  public func loadSettings() -> NSString {
    (try? Self.json(store.allSettings())) ?? "{}"
  }

  public func upsertNote(_ note: NSDictionary) -> NSNumber {
    guard let record = Self.record(from: note) else { return NSNumber(value: false) }
    do { try store.upsert(record); return NSNumber(value: true) } catch {
      NSLog("NotesStore.upsertNote failed: \(error)")
      return NSNumber(value: false)
    }
  }

  public func deleteNote(_ id: NSString) -> NSNumber {
    NSNumber(value: (try? store.delete(id: id as String)) != nil)
  }

  public func replaceAllNotes(_ list: NSArray) -> NSNumber {
    let records = list.compactMap { ($0 as? NSDictionary).flatMap(Self.record(from:)) }
    do {
      try store.replaceAll(records)
      try store.setSetting("seeded", "1")
      return NSNumber(value: true)
    } catch {
      NSLog("NotesStore.replaceAllNotes failed: \(error)")
      return NSNumber(value: false)
    }
  }

  public func setSetting(_ key: NSString, value: NSString) -> NSNumber {
    NSNumber(value: (try? store.setSetting(key as String, value as String)) != nil)
  }

  private static func record(from dict: NSDictionary) -> NotesDatabase.NoteRecord? {
    guard let id = dict["id"] as? String, let body = dict["body"] as? String else { return nil }
    let starred = (dict["starred"] as? NSNumber)?.boolValue ?? false
    let updatedAt = (dict["updatedAt"] as? NSNumber)?.doubleValue ?? Date().timeIntervalSince1970 * 1000
    return NotesDatabase.NoteRecord(id: id, body: body, starred: starred, updatedAt: updatedAt)
  }

  private static func json(_ object: Any) -> NSString {
    guard let data = try? JSONSerialization.data(withJSONObject: object),
          let s = String(data: data, encoding: .utf8) else { return "null" }
    return s as NSString
  }
}
