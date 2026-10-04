import Foundation

/// `#tag` detection shared by the model (tag lists, snippets) and the Markdown preview.
enum Tags {
    /// `#` + letter + letters/digits/`-`/`_`, at line start or after whitespace.
    static let regex = try! NSRegularExpression(pattern: #"(?<![^\s])#(\p{L}[\p{L}\p{N}_-]*)"#)

    /// Tags of a body: lower-cased, de-duplicated, in order of first appearance.
    /// The title line, fenced code and inline code never contribute tags.
    static func extract(from body: String) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        forEachProseSegment(of: body) { segment in
            for match in matches(in: segment) {
                let tag = match.name.lowercased()
                if seen.insert(tag).inserted { result.append(tag) }
            }
        }
        return result
    }

    struct Match {
        let range: Range<String.Index>   // includes the leading `#`
        let name: String
    }

    static func matches(in text: String) -> [Match] {
        let ns = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: ns).compactMap { m in
            guard let r = Range(m.range, in: text), let n = Range(m.range(at: 1), in: text) else { return nil }
            return Match(range: r, name: String(text[n]))
        }
    }

    /// Removes tags from a line of prose, leaving inline code untouched.
    static func strip(fromLine line: String) -> String {
        let parts = line.components(separatedBy: "`")
        let cleaned = parts.enumerated().map { i, part -> String in
            guard i % 2 == 0 else { return part }   // odd segments are inside inline code
            var s = part
            for m in matches(in: part).reversed() {
                s.removeSubrange(m.range)
            }
            return s
        }
        return cleaned.joined(separator: "`")
    }

    /// Calls `body` with every piece of non-code text after the title line.
    private static func forEachProseSegment(of text: String, _ body: (String) -> Void) {
        var inFence = false
        for line in text.components(separatedBy: "\n").dropFirst() {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                inFence.toggle()
                continue
            }
            if inFence { continue }
            for (i, part) in line.components(separatedBy: "`").enumerated() where i % 2 == 0 {
                body(part)
            }
        }
    }
}
