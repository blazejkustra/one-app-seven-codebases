package com.mdnotes.kotlin.data

import java.time.LocalDateTime
import java.time.ZoneId

object SeedNotes {
    private fun at(y: Int, mo: Int, d: Int, h: Int, mi: Int): Long =
        LocalDateTime.of(y, mo, d, h, mi).atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()

    private const val FENCE = "```"

    /** Bumped whenever the seed bodies change; see [NotesRepository.initialize]. */
    const val VERSION = 3

    private val v2TagSuffixes = mapOf(
        "welcome" to "\n\n#welcome",
        "groceries" to "\n\n#home #shopping",
        "meeting" to "\n\n#work",
        "ideas" to " #ideas",
    )

    /**
     * Bodies earlier app versions seeded, per note id. An untouched seed (body still equal
     * to one of these) is upgraded to the current seed body on launch.
     */
    fun legacyBodies(): Map<String, List<String>> = all().associate { seed ->
        val v2 = if (seed.id == "groceries") {
            seed.body.replace("- [x] ", "- ").replace("- [ ] ", "- ")
        } else {
            seed.body
        }
        val v1 = v2.removeSuffix(v2TagSuffixes.getValue(seed.id))
        seed.id to listOf(v1, v2).filter { it != seed.body }
    }

    fun all(): List<NoteEntity> = listOf(
        NoteEntity(
            id = "welcome",
            body = """
                |# Welcome to Markdown Notes
                |
                |Write in **Markdown** and switch to *Preview* to see it rendered.
                |
                |## What works
                |
                |- Headings, **bold** and *italic*
                |- Inline `code` and code blocks
                |- Bullet and numbered lists
                |
                |> Notes are saved on your device automatically.
                |
                |$FENCE
                |const hello = "world";
                |$FENCE
                |
                |#welcome
            """.trimMargin(),
            starred = true,
            updatedAt = at(2026, 10, 1, 9, 30),
        ),
        NoteEntity(
            id = "groceries",
            body = """
                |# Grocery list
                |
                |- [x] Oat milk
                |- [ ] Sourdough bread
                |- [ ] Blueberries
                |- [x] Dark chocolate
                |
                |#home #shopping
            """.trimMargin(),
            starred = false,
            updatedAt = at(2026, 9, 30, 18, 5),
        ),
        NoteEntity(
            id = "meeting",
            body = """
                |# Meeting notes
                |
                |## Q4 planning
                |
                |1. Ship the beta by **Nov 15**
                |2. Hire one more designer
                |3. Review analytics weekly
                |
                |#work
            """.trimMargin(),
            starred = true,
            updatedAt = at(2026, 9, 28, 14, 0),
        ),
        NoteEntity(
            id = "ideas",
            body = """
                |# Ideas
                |
                |Build a tiny habit tracker. Maybe *one tap* per day, no accounts, no sync. #ideas
            """.trimMargin(),
            starred = false,
            updatedAt = at(2026, 9, 25, 8, 15),
        ),
    )
}
