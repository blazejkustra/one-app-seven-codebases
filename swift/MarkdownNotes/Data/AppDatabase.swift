import Foundation
import GRDB

/// SQLite storage (via GRDB) for notes and settings.
final class AppDatabase: Sendable {
    let writer: DatabaseQueue

    init(_ writer: DatabaseQueue) throws {
        self.writer = writer
        try migrator.migrate(writer)
    }

    static func onDisk() throws -> AppDatabase {
        let dir = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let url = dir.appendingPathComponent("notes.sqlite")
        return try AppDatabase(DatabaseQueue(path: url.path))
    }

    static func inMemory() -> AppDatabase {
        // swiftlint:disable:next force_try
        try! AppDatabase(DatabaseQueue())
    }

    private var migrator: DatabaseMigrator {
        var m = DatabaseMigrator()
        m.registerMigration("v1") { db in
            try db.create(table: "note") { t in
                t.primaryKey("id", .text)
                t.column("body", .text).notNull()
                t.column("starred", .boolean).notNull().defaults(to: false)
                t.column("updatedAt", .datetime).notNull()
            }
            try db.create(table: "setting") { t in
                t.primaryKey("key", .text)
                t.column("value", .text).notNull()
            }
            // First launch: seed the sample notes.
            for note in SeedNotes.all { try note.insert(db) }
        }
        m.registerMigration("v2-tags") { db in
            // Existing installs: add the iteration-2 tags to seed notes the user never edited.
            let suffixes = ["welcome": "\n\n#welcome", "groceries": "\n\n#home #shopping",
                            "meeting": "\n\n#work", "ideas": " #ideas"]
            for seed in SeedNotes.all {
                guard let suffix = suffixes[seed.id], seed.body.hasSuffix(suffix) else { continue }
                let oldBody = String(seed.body.dropLast(suffix.count))
                try db.execute(sql: "UPDATE note SET body = ? WHERE id = ? AND body = ?",
                               arguments: [seed.body, seed.id, oldBody])
            }
        }
        m.registerMigration("v3-checklists") { db in
            // Existing installs: turn an unedited grocery seed (iteration 1 or 2) into the checklist.
            let v1 = "# Grocery list\n\n- Oat milk\n- Sourdough bread\n- Blueberries\n- Dark chocolate"
            let v2 = v1 + "\n\n#home #shopping"
            guard let seed = SeedNotes.all.first(where: { $0.id == "groceries" }) else { return }
            try db.execute(sql: "UPDATE note SET body = ? WHERE id = 'groceries' AND body IN (?, ?)",
                           arguments: [seed.body, v1, v2])
        }
        return m
    }

    // MARK: Notes

    func fetchNotes() throws -> [Note] {
        try writer.read { try Note.fetchAll($0) }
    }

    func save(_ note: Note) throws {
        try writer.write { try note.save($0) }
    }

    func deleteNote(id: String) throws {
        _ = try writer.write { try Note.deleteOne($0, key: id) }
    }

    func resetToSeed() throws {
        try writer.write { db in
            try Note.deleteAll(db)
            for note in SeedNotes.all { try note.insert(db) }
        }
    }

    // MARK: Settings

    func setting(_ key: String) throws -> String? {
        try writer.read { db in
            try String.fetchOne(db, sql: "SELECT value FROM setting WHERE key = ?", arguments: [key])
        }
    }

    func setSetting(_ key: String, _ value: String) throws {
        try writer.write { db in
            try db.execute(
                sql: "INSERT INTO setting(key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value",
                arguments: [key, value])
        }
    }
}
