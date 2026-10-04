import Foundation

/// Line-level helpers for GFM task items (`- [ ] text`, `* [x] text`).
enum Tasks {
    private static let taskLine = try! NSRegularExpression(pattern: #"^\s*(?:[-*+]|\d+[.)])\s+\[( |x|X)\](?=\s|$)"#)

    /// (done, total) for the task items outside code fences.
    static func progress(of body: String) -> (done: Int, total: Int) {
        var done = 0, total = 0, inFence = false
        for line in body.components(separatedBy: "\n") {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") { inFence.toggle(); continue }
            guard !inFence, let m = taskLine.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                  let r = Range(m.range(at: 1), in: line) else { continue }
            total += 1
            if line[r] != " " { done += 1 }
        }
        return (done, total)
    }

    /// Flips `[ ]` ↔ `[x]` on the given 1-based source line.
    static func toggle(in body: String, line: Int) -> String {
        var lines = body.components(separatedBy: "\n")
        guard line >= 1, line <= lines.count else { return body }
        let text = lines[line - 1]
        guard let m = taskLine.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let r = Range(m.range(at: 1), in: text) else { return body }
        lines[line - 1] = text.replacingCharacters(in: r, with: text[r] == " " ? "x" : " ")
        return lines.joined(separator: "\n")
    }
}
