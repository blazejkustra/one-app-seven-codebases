package com.mdnotes.kotlin.data

import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

/** Derived, display-only text for a note (title, snippet, tags, date label). */
object NoteText {
    private val leadingHashes = Regex("^[#\\s]+")
    private val lineMarker = Regex("^(#+\\s+|(?:[-*] |\\d+\\. )(?:\\[[ xX]\\] )?|> )")
    private val inlineCode = Regex("`[^`]*`")
    private val dateFormat = DateTimeFormatter.ofPattern("MMM d, yyyy", Locale.US)

    /** `#` + letter + letters/digits/`-`/`_`, at line start or after whitespace. Group 1 = tag name. */
    val TAG = Regex("(?<=^|\\s)#(\\p{L}[\\p{L}\\p{N}_-]*)")

    fun title(body: String): String {
        val first = body.lineSequence().firstOrNull().orEmpty()
        return first.replace(leadingHashes, "").trim().ifEmpty { "Untitled" }
    }

    /** Lines after the title, with fenced code blocks removed. */
    private fun bodyLines(body: String): List<String> {
        val out = mutableListOf<String>()
        var inFence = false
        for (line in body.lines().drop(1)) {
            if (line.trim().startsWith("```")) { inFence = !inFence; continue }
            if (!inFence) out += line
        }
        return out
    }

    /** Applies [transform] to the parts of [line] that are not inline code. */
    private fun outsideCode(line: String, transform: (String) -> String): String {
        val sb = StringBuilder()
        var last = 0
        for (m in inlineCode.findAll(line)) {
            sb.append(transform(line.substring(last, m.range.first))).append(m.value)
            last = m.range.last + 1
        }
        return sb.append(transform(line.substring(last))).toString()
    }

    /** Lower-cased, de-duplicated tags in order of appearance (title line excluded). */
    fun tags(body: String): List<String> {
        val result = LinkedHashSet<String>()
        for (line in bodyLines(body)) {
            outsideCode(line) { part ->
                TAG.findAll(part).forEach { result += it.groupValues[1].lowercase(Locale.ROOT) }
                part
            }
        }
        return result.toList()
    }

    fun snippet(body: String): String =
        body.lines().drop(1)
            .asSequence()
            .map { it.trim() }
            .filterNot { it.startsWith("```") }
            .map { line -> outsideCode(line) { it.replace(TAG, "") }.replace(Regex("\\s{2,}"), " ").trim() }
            .map { it.replaceFirst(lineMarker, "") }
            .map { it.replace("**", "").replace("*", "").replace("`", "").trim() }
            .filter { it.isNotEmpty() }
            .joinToString(" ")

    fun dateLabel(epochMillis: Long, zone: ZoneId = ZoneId.systemDefault()): String =
        dateFormat.format(Instant.ofEpochMilli(epochMillis).atZone(zone))
}
