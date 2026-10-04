import Foundation
import Observation

/// App state backed by SQLite. Every mutation is written through immediately.
@MainActor
@Observable
final class NoteStore {
    private(set) var notes: [Note] = []
    private(set) var sortOrder: SortOrder = .updated
    private(set) var showSnippets: Bool = true
    private(set) var appearance: Appearance = .system

    private let db: AppDatabase

    init(db: AppDatabase) {
        self.db = db
        reload()
    }

    static func makeDefault() -> NoteStore {
        let db = (try? AppDatabase.onDisk()) ?? AppDatabase.inMemory()
        return NoteStore(db: db)
    }

    private func reload() {
        notes = (try? db.fetchNotes()) ?? []
        // A note left empty (e.g. app killed inside the editor) is discarded on launch.
        for note in notes where note.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try? db.deleteNote(id: note.id)
        }
        notes.removeAll { $0.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        sortOrder = (try? db.setting("sortOrder")).flatMap { $0.flatMap(SortOrder.init(rawValue:)) } ?? .updated
        showSnippets = ((try? db.setting("showSnippets")) ?? nil).map { $0 == "1" } ?? true
        appearance = ((try? db.setting("appearance")) ?? nil).flatMap(Appearance.init(rawValue:)) ?? .system
    }

    // MARK: Queries

    var sortedNotes: [Note] {
        switch sortOrder {
        case .updated:
            return notes.sorted { $0.updatedAt > $1.updatedAt }
        case .title:
            return notes.sorted {
                let c = $0.title.localizedCaseInsensitiveCompare($1.title)
                return c == .orderedSame ? $0.updatedAt > $1.updatedAt : c == .orderedAscending
            }
        }
    }

    func notes(matching query: String, tag: String? = nil) -> [Note] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return sortedNotes.filter { note in
            (q.isEmpty || note.body.range(of: q, options: .caseInsensitive) != nil)
                && (tag == nil || note.tags.contains(tag!))
        }
    }

    /// Every tag across all notes, A→Z.
    var allTags: [String] {
        Array(Set(notes.flatMap(\.tags))).sorted()
    }

    var starredNotes: [Note] { sortedNotes.filter(\.starred) }

    func note(id: String) -> Note? { notes.first { $0.id == id } }

    // MARK: Mutations

    func createNote() -> Note {
        let note = Note(id: UUID().uuidString, body: "# New note\n\n", starred: false, updatedAt: Date())
        persist(note)
        return note
    }

    func updateBody(id: String, body: String) {
        guard var note = note(id: id), note.body != body else { return }
        note.body = body
        note.updatedAt = Date()
        persist(note)
    }

    func toggleStar(id: String) {
        guard var note = note(id: id) else { return }
        note.starred.toggle()
        persist(note)
    }

    /// Called when the editor is left: empty notes are discarded.
    func finishEditing(id: String) {
        guard let note = note(id: id) else { return }
        if note.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try? db.deleteNote(id: id)
            notes.removeAll { $0.id == id }
        }
    }

    /// Deletes a note and returns it exactly as it was, for undo.
    @discardableResult
    func deleteNote(id: String) -> Note? {
        guard let note = note(id: id) else { return nil }
        try? db.deleteNote(id: id)
        notes.removeAll { $0.id == id }
        return note
    }

    /// Re-inserts a deleted note unchanged (id, body, star, updatedAt).
    func restore(_ note: Note) {
        persist(note)
    }

    func toggleSortOrder() {
        sortOrder = sortOrder == .updated ? .title : .updated
        try? db.setSetting("sortOrder", sortOrder.rawValue)
    }

    func cycleAppearance() {
        appearance = appearance.next
        try? db.setSetting("appearance", appearance.rawValue)
    }

    func setShowSnippets(_ value: Bool) {
        showSnippets = value
        try? db.setSetting("showSnippets", value ? "1" : "0")
    }

    func resetSampleNotes() {
        try? db.resetToSeed()
        notes = (try? db.fetchNotes()) ?? []
    }

    private func persist(_ note: Note) {
        try? db.save(note)
        if let i = notes.firstIndex(where: { $0.id == note.id }) {
            notes[i] = note
        } else {
            notes.append(note)
        }
    }
}
