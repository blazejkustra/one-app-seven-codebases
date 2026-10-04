import Foundation

/// Plain-text derivations of a note body used by the list cards.
enum NoteText {
    static func title(of body: String) -> String {
        let first = body.components(separatedBy: "\n").first ?? ""
        let stripped = first.drop { $0 == "#" || $0 == " " }
        let title = String(stripped).trimmingCharacters(in: .whitespaces)
        return title.isEmpty ? "Untitled" : title
    }

    static func snippet(of body: String) -> String {
        let lines = body.components(separatedBy: "\n").dropFirst()
        var parts: [String] = []
        var inFence = false
        for raw in lines {
            var line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("```") { inFence.toggle(); continue }
            if let range = line.range(of: #"^#+\s+"#, options: .regularExpression) {
                line.removeSubrange(range)
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("> ") {
                let wasList = !line.hasPrefix("> ")
                line = String(line.dropFirst(2))
                if wasList, let range = line.range(of: #"^\[( |x|X)\] "#, options: .regularExpression) {
                    line.removeSubrange(range)
                }
            } else if let range = line.range(of: #"^\d+\. "#, options: .regularExpression) {
                line.removeSubrange(range)
            }
            if !inFence { line = Tags.strip(fromLine: line) }
            line = line.replacingOccurrences(of: "**", with: "")
                .replacingOccurrences(of: "*", with: "")
                .replacingOccurrences(of: "`", with: "")
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
            if !line.isEmpty { parts.append(line) }
        }
        return parts.joined(separator: " ")
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    static func dateLabel(_ date: Date) -> String { formatter.string(from: date) }
}
