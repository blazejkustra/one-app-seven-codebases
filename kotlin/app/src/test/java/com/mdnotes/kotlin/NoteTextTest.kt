package com.mdnotes.kotlin

import com.mdnotes.kotlin.data.NoteText
import com.mdnotes.kotlin.data.SeedNotes
import com.mdnotes.kotlin.markdown.Block
import com.mdnotes.kotlin.markdown.MarkdownDocument
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.ZoneId

class NoteTextTest {
    private val welcome = SeedNotes.all().first { it.id == "welcome" }.body

    @Test fun title() {
        assertEquals("Welcome to Markdown Notes", NoteText.title(welcome))
        assertEquals("Untitled", NoteText.title("##   \nbody"))
        assertEquals("Untitled", NoteText.title(""))
    }

    @Test fun snippet() {
        assertEquals(
            "Write in Markdown and switch to Preview to see it rendered. What works Headings, bold and italic " +
                "Inline code and code blocks Bullet and numbered lists Notes are saved on your device automatically. " +
                "const hello = \"world\";",
            NoteText.snippet(welcome),
        )
        assertEquals("Q4 planning Ship the beta by Nov 15 Hire one more designer Review analytics weekly",
            NoteText.snippet(SeedNotes.all().first { it.id == "meeting" }.body))
    }

    @Test fun tags() {
        val seeds = SeedNotes.all().associate { it.id to it.body }
        assertEquals(listOf("welcome"), NoteText.tags(seeds.getValue("welcome")))
        assertEquals(listOf("home", "shopping"), NoteText.tags(seeds.getValue("groceries")))
        assertEquals(listOf("work"), NoteText.tags(seeds.getValue("meeting")))
        assertEquals(listOf("ideas"), NoteText.tags(seeds.getValue("ideas")))
        assertEquals("Build a tiny habit tracker. Maybe one tap per day, no accounts, no sync.",
            NoteText.snippet(seeds.getValue("ideas")))
        assertEquals(listOf("q4-plans", "work"),
            NoteText.tags("# #title\n## Heading\n#Q4-plans and #work, #WORK a#b `#code`\n```\n#fenced\n```\n#9no"))
        assertEquals("Heading and , a#b #code", NoteText.snippet("# t\n## Heading\n#Q4-plans and #work, a#b `#code`"))
    }

    @Test fun previewTags() {
        val blocks = MarkdownDocument.parse("# T\n\nhello #work and `#no`\n\n#home #shopping")
        val p1 = (blocks[1] as Block.Paragraph).content
        assertTrue(p1.contains(com.mdnotes.kotlin.markdown.Inline.Tag("#work")))
        assertTrue(p1.none { it == com.mdnotes.kotlin.markdown.Inline.Tag("#no") })
        val p2 = (blocks[2] as Block.Paragraph).content.filterIsInstance<com.mdnotes.kotlin.markdown.Inline.Tag>()
        assertEquals(listOf("#home", "#shopping"), p2.map { it.text })
    }

    @Test fun tasks() {
        val groceries = SeedNotes.all().first { it.id == "groceries" }.body
        assertEquals("Oat milk Sourdough bread Blueberries Dark chocolate", NoteText.snippet(groceries))
        val tasks = MarkdownDocument.tasks(groceries)
        assertEquals(listOf(true, false, false, true), tasks.map { it.checked })
        assertEquals(listOf(0, 1, 2, 3), tasks.map { it.index })
        val toggled = MarkdownDocument.toggle(groceries, tasks[1])
        assertTrue(toggled.contains("- [x] Sourdough bread"))
        assertEquals(listOf(true, true, false, true), MarkdownDocument.tasks(toggled).map { it.checked })
        assertEquals(groceries, MarkdownDocument.toggle(toggled, MarkdownDocument.tasks(toggled)[1]))
        // `*` bullets are tasks too; numbered items and code are not.
        assertEquals(2, MarkdownDocument.tasks("# t\n\n* [ ] a\n- [X] b\n\n1. [x] c\n\n```\n- [ ] d\n```").size)
    }

    @Test fun seedMigration() {
        val legacy = SeedNotes.legacyBodies()
        assertTrue(legacy.getValue("groceries").contains("# Grocery list\n\n- Oat milk\n- Sourdough bread\n- Blueberries\n- Dark chocolate"))
        assertTrue(legacy.getValue("groceries").contains("# Grocery list\n\n- Oat milk\n- Sourdough bread\n- Blueberries\n- Dark chocolate\n\n#home #shopping"))
    }

    @Test fun dateLabel() {
        val utc = ZoneId.of("UTC")
        assertEquals("Oct 1, 2026", NoteText.dateLabel(1790847000000L, utc))
    }

    @Test fun markdownBlocks() {
        val blocks = MarkdownDocument.parse(welcome)
        assertEquals(listOf(Block.Heading::class, Block.Paragraph::class, Block.Heading::class,
            Block.ListBlock::class, Block.Quote::class, Block.CodeBlock::class, Block.Paragraph::class), blocks.map { it::class })
        assertEquals("const hello = \"world\";", (blocks[5] as Block.CodeBlock).code)
        assertTrue((blocks[3] as Block.ListBlock).items.size == 3)
    }
}
