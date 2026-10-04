package com.mdnotes.kmp.data

/**
 * Tag scanning (iteration 2): `#` directly followed by a letter, then letters, digits, `-` or `_`,
 * at the start of a line or after whitespace. Inline code and code fences never contain tags.
 */
object Tags {
    /** A tag occurrence inside a single line: [start, end) offsets of `#tag`. */
    data class Match(val start: Int, val end: Int, val name: String)

    private fun isTagChar(c: Char) = c.isLetterOrDigit() || c == '-' || c == '_'

    /** Finds tags in one line, skipping `inline code` spans. */
    fun findInLine(line: String): List<Match> {
        val out = mutableListOf<Match>()
        var i = 0
        var inCode = false
        while (i < line.length) {
            val c = line[i]
            if (c == '`') { inCode = !inCode; i++; continue }
            if (!inCode && c == '#' && (i == 0 || line[i - 1].isWhitespace()) &&
                i + 1 < line.length && line[i + 1].isLetter()
            ) {
                var j = i + 1
                while (j < line.length && isTagChar(line[j])) j++
                out += Match(i, j, line.substring(i + 1, j).lowercase())
                i = j
                continue
            }
            i++
        }
        return out
    }

    /** Tags of a whole note body: lower-cased, de-duplicated, in order of appearance. */
    fun extract(body: String): List<String> {
        val result = LinkedHashSet<String>()
        var inFence = false
        body.lines().drop(1).forEach { raw ->
            if (raw.trim().startsWith("```")) { inFence = !inFence; return@forEach }
            if (!inFence) findInLine(raw).forEach { result += it.name }
        }
        return result.toList()
    }

    /** Removes tag tokens from a line (used for snippets). */
    fun removeFromLine(line: String): String {
        val matches = findInLine(line)
        if (matches.isEmpty()) return line
        val sb = StringBuilder()
        var last = 0
        for (m in matches) { sb.append(line, last, m.start); last = m.end }
        sb.append(line, last, line.length)
        return sb.toString().replace(Regex("\\s+"), " ").trim()
    }
}
