import Foundation
import GRDB

struct Note: Identifiable, Equatable, Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "note"

    var id: String
    var body: String
    var starred: Bool
    var updatedAt: Date

    var title: String { NoteText.title(of: body) }
    var snippet: String { NoteText.snippet(of: body) }
    var dateLabel: String { NoteText.dateLabel(updatedAt) }
    var tags: [String] { Tags.extract(from: body) }
    var taskProgress: (done: Int, total: Int) { Tasks.progress(of: body) }
}

enum SortOrder: String {
    case updated
    case title

    var label: String { self == .updated ? "Updated" : "Title" }
}

enum Appearance: String, CaseIterable {
    case system, light, dark

    var label: String { rawValue.capitalized }
    var next: Appearance {
        switch self {
        case .system: return .light
        case .light: return .dark
        case .dark: return .system
        }
    }
}
