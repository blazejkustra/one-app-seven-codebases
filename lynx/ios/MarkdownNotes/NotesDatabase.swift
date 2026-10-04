import Foundation
import SQLite

/// SQLite-backed storage for notes and settings (via SQLite.swift).
final class NotesDatabase {
  static let shared = NotesDatabase()

  struct NoteRecord {
    let id: String
    let body: String
    let starred: Bool
    let updatedAt: Double  // milliseconds since 1970
  }

  private let db: Connection

  private let notes = Table("notes")
  private let colId = SQLite.Expression<String>("id")
  private let colBody = SQLite.Expression<String>("body")
  private let colStarred = SQLite.Expression<Bool>("starred")
  private let colUpdatedAt = SQLite.Expression<Double>("updated_at")

  private let settings = Table("settings")
  private let colKey = SQLite.Expression<String>("key")
  private let colValue = SQLite.Expression<String>("value")

  private init() {
    let fm = FileManager.default
    let dir = try! fm.url(for: .applicationSupportDirectory, in: .userDomainMask,
                          appropriateFor: nil, create: true)
    let path = dir.appendingPathComponent("notes.sqlite3").path
    db = try! Connection(path)
    try? db.execute("PRAGMA journal_mode = WAL;")
    try! db.run(notes.create(ifNotExists: true) { t in
      t.column(colId, primaryKey: true)
      t.column(colBody)
      t.column(colStarred, defaultValue: false)
      t.column(colUpdatedAt)
    })
    try! db.run(settings.create(ifNotExists: true) { t in
      t.column(colKey, primaryKey: true)
      t.column(colValue)
    })
  }

  func allNotes() throws -> [NoteRecord] {
    try db.prepare(notes).map { row in
      NoteRecord(id: row[colId], body: row[colBody], starred: row[colStarred],
                 updatedAt: row[colUpdatedAt])
    }
  }

  func upsert(_ note: NoteRecord) throws {
    try db.run(notes.upsert(
      colId <- note.id, colBody <- note.body, colStarred <- note.starred,
      colUpdatedAt <- note.updatedAt,
      onConflictOf: colId))
  }

  func delete(id: String) throws {
    try db.run(notes.filter(colId == id).delete())
  }

  func replaceAll(_ records: [NoteRecord]) throws {
    try db.transaction {
      try db.run(notes.delete())
      for record in records { try upsert(record) }
    }
  }

  func allSettings() throws -> [String: String] {
    var result: [String: String] = [:]
    for row in try db.prepare(settings) { result[row[colKey]] = row[colValue] }
    return result
  }

  func setSetting(_ key: String, _ value: String) throws {
    try db.run(settings.upsert(colKey <- key, colValue <- value, onConflictOf: colKey))
  }
}
