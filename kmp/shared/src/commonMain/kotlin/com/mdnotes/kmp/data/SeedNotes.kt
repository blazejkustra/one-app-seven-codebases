package com.mdnotes.kmp.data

import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toInstant

object SeedNotes {
    private fun local(y: Int, mo: Int, d: Int, h: Int, mi: Int): Long =
        LocalDateTime(y, mo, d, h, mi).toInstant(TimeZone.currentSystemDefault()).toEpochMilliseconds()

    fun create(): List<Note> = listOf(
        Note(
            id = "welcome",
            body = "# Welcome to Markdown Notes\n\n" +
                "Write in **Markdown** and switch to *Preview* to see it rendered.\n\n" +
                "## What works\n\n" +
                "- Headings, **bold** and *italic*\n" +
                "- Inline `code` and code blocks\n" +
                "- Bullet and numbered lists\n\n" +
                "> Notes are saved on your device automatically.\n\n" +
                "```\n" +
                "const hello = \"world\";\n" +
                "```\n\n" +
                "#welcome",
            starred = true,
            updatedAt = local(2026, 10, 1, 9, 30),
        ),
        Note(
            id = "groceries",
            body = "# Grocery list\n\n- [x] Oat milk\n- [ ] Sourdough bread\n- [ ] Blueberries\n- [x] Dark chocolate\n\n#home #shopping",
            starred = false,
            updatedAt = local(2026, 9, 30, 18, 5),
        ),
        Note(
            id = "meeting",
            body = "# Meeting notes\n\n## Q4 planning\n\n" +
                "1. Ship the beta by **Nov 15**\n" +
                "2. Hire one more designer\n" +
                "3. Review analytics weekly\n\n" +
                "#work",
            starred = true,
            updatedAt = local(2026, 9, 28, 14, 0),
        ),
        Note(
            id = "ideas",
            body = "# Ideas\n\nBuild a tiny habit tracker. Maybe *one tap* per day, no accounts, no sync. #ideas",
            starred = false,
            updatedAt = local(2026, 9, 25, 8, 15),
        ),
    )

    /**
     * Earlier shipped versions of each seed body. An install whose seed is still exactly one of
     * these (i.e. never edited) is upgraded to the current seed body.
     */
    fun legacyBodies(): Map<String, List<String>> {
        val current = create().associate { it.id to it.body }
        val groceriesV2 = "# Grocery list\n\n- Oat milk\n- Sourdough bread\n- Blueberries\n- Dark chocolate\n\n#home #shopping"
        return mapOf(
            "welcome" to listOf(current.getValue("welcome").removeSuffix("\n\n#welcome")),
            "groceries" to listOf(groceriesV2, groceriesV2.removeSuffix("\n\n#home #shopping")),
            "meeting" to listOf(current.getValue("meeting").removeSuffix("\n\n#work")),
            "ideas" to listOf(current.getValue("ideas").removeSuffix(" #ideas")),
        )
    }

    const val VERSION = 3
}
