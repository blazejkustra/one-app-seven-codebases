package com.mdnotes.kmp.data

import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import kotlin.time.Instant

/** Derived, display-only values of a note (spec §2). */
object NoteText {
    // A heading marker is a #-run followed by whitespace; "#tag" is not a heading.
    private val listMarker = Regex("^(#+\\s+|- |\\* |> |\\d+\\. )")
    private val taskBox = Regex("^\\[[ xX]\\] ")
    private val taskLine = Regex("^\\s*[-*] \\[([ xX])\\](\\s|$)")
    private val months = listOf("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")

    fun title(body: String): String {
        val first = body.lineSequence().firstOrNull().orEmpty()
        val t = first.trimStart('#', ' ').trim()
        return t.ifEmpty { "Untitled" }
    }

    fun snippet(body: String): String {
        var inFence = false
        val parts = mutableListOf<String>()
        for (raw in body.lines().drop(1)) {
            val line = raw.trim()
            if (line.startsWith("```")) { inFence = !inFence; continue }
            var t = line.replaceFirst(listMarker, "").replaceFirst(taskBox, "")
            if (!inFence) t = Tags.removeFromLine(t)
            t = t.replace("**", "").replace("*", "").replace("`", "").trim()
            if (t.isNotEmpty()) parts += t
        }
        return parts.joinToString(" ")
    }

    /** (done, total) of `- [ ]` / `- [x]` task lines outside code fences. */
    fun taskProgress(body: String): Pair<Int, Int> {
        var inFence = false
        var done = 0
        var total = 0
        for (line in body.lines()) {
            if (line.trim().startsWith("```")) { inFence = !inFence; continue }
            if (inFence) continue
            val m = taskLine.find(line) ?: continue
            total++
            if (m.groupValues[1] != " ") done++
        }
        return done to total
    }

    /** Flips the task checkbox whose `[` sits at [boxOffset]. */
    fun toggleTask(body: String, boxOffset: Int): String {
        if (boxOffset + 2 >= body.length || body[boxOffset] != '[' || body[boxOffset + 2] != ']') return body
        val checked = body[boxOffset + 1] != ' '
        return body.substring(0, boxOffset + 1) + (if (checked) " " else "x") + body.substring(boxOffset + 2)
    }

    fun dateLabel(epochMillis: Long): String {
        val dt = Instant.fromEpochMilliseconds(epochMillis).toLocalDateTime(TimeZone.currentSystemDefault())
        return "${months[dt.month.ordinal]} ${dt.day}, ${dt.year}"
    }

    fun sorted(notes: List<Note>, order: SortOrder): List<Note> = when (order) {
        SortOrder.Updated -> notes.sortedByDescending { it.updatedAt }
        SortOrder.Title -> notes.sortedWith(compareBy(String.CASE_INSENSITIVE_ORDER) { title(it.body) })
    }
}
