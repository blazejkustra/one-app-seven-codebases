package com.mdnotes.kmp.markdown

import com.mdnotes.kmp.data.Tags
import org.intellij.markdown.MarkdownElementTypes
import org.intellij.markdown.parser.CancellationToken
import org.intellij.markdown.MarkdownTokenTypes
import org.intellij.markdown.ast.ASTNode
import org.intellij.markdown.ast.getTextInNode
import org.intellij.markdown.flavours.gfm.GFMFlavourDescriptor
import org.intellij.markdown.flavours.gfm.GFMTokenTypes
import org.intellij.markdown.parser.MarkdownParser as JbMarkdownParser

/**
 * Parses Markdown with JetBrains' `org.jetbrains:markdown` (GFM flavour, for task-list checkboxes) and maps the
 * AST onto the small block/inline model rendered by the preview.
 */
object MarkdownParser {
    private val parser = JbMarkdownParser(GFMFlavourDescriptor(), assertionsEnabled = false, cancellationToken = CancellationToken.NonCancellable)

    fun parse(source: String): List<MdBlock> {
        val root = parser.buildMarkdownTreeFromString(source as CharSequence)
        val blocks = mutableListOf<MdBlock>()
        root.children.forEach { collectBlock(it, source, blocks) }
        // Number tasks in document order.
        var next = 0
        return blocks.map { b ->
            if (b is MdBlock.TaskList) MdBlock.TaskList(b.items.map { it.copy(index = next++) }) else b
        }
    }

    private fun collectBlock(node: ASTNode, src: String, out: MutableList<MdBlock>) {
        when (node.type) {
            MarkdownElementTypes.ATX_1, MarkdownElementTypes.SETEXT_1 -> out += heading(1, node, src)
            MarkdownElementTypes.ATX_2, MarkdownElementTypes.SETEXT_2 -> out += heading(2, node, src)
            MarkdownElementTypes.ATX_3 -> out += heading(3, node, src)
            MarkdownElementTypes.ATX_4, MarkdownElementTypes.ATX_5, MarkdownElementTypes.ATX_6 ->
                out += heading(3, node, src)
            MarkdownElementTypes.PARAGRAPH -> out += MdBlock.Paragraph(inlines(node, src))
            MarkdownElementTypes.UNORDERED_LIST -> out += list(node, src, ordered = false)
            MarkdownElementTypes.ORDERED_LIST -> out += list(node, src, ordered = true)
            MarkdownElementTypes.BLOCK_QUOTE -> {
                val runs = mutableListOf<InlineRun>()
                node.children.filter { it.type == MarkdownElementTypes.PARAGRAPH }.forEachIndexed { i, p ->
                    if (i > 0) runs += InlineRun(" ")
                    runs += inlines(p, src)
                }
                out += MdBlock.Quote(runs.trimmed())
            }
            MarkdownElementTypes.CODE_FENCE -> out += MdBlock.Code(fenceText(node, src))
            MarkdownElementTypes.CODE_BLOCK -> out += MdBlock.Code(
                node.getTextInNode(src).toString().lines().joinToString("\n") { it.removePrefix("    ") }.trimEnd('\n')
            )
            MarkdownElementTypes.HTML_BLOCK -> out += MdBlock.Paragraph(listOf(InlineRun(node.getTextInNode(src).toString())))
            else -> Unit // blank lines, horizontal rules, link definitions…
        }
    }

    private fun heading(level: Int, node: ASTNode, src: String): MdBlock.Heading {
        val content = node.children.firstOrNull {
            it.type == MarkdownTokenTypes.ATX_CONTENT || it.type == MarkdownTokenTypes.SETEXT_CONTENT
        }
        return MdBlock.Heading(level, content?.let { inlines(it, src) }.orEmpty())
    }

    /** A list becomes runs of plain-list blocks and task-list blocks (consecutive tasks group). */
    private fun list(node: ASTNode, src: String, ordered: Boolean): List<MdBlock> {
        val out = mutableListOf<MdBlock>()
        val plain = mutableListOf<ListItem>()
        val tasks = mutableListOf<TaskItem>()
        fun flushPlain() { if (plain.isNotEmpty()) { out += MdBlock.ListBlock(ordered, plain.toList()); plain.clear() } }
        fun flushTasks() { if (tasks.isNotEmpty()) { out += MdBlock.TaskList(tasks.toList()); tasks.clear() } }
        node.children.filter { it.type == MarkdownElementTypes.LIST_ITEM }.forEach { item ->
            val marker = item.children.firstOrNull {
                it.type == MarkdownTokenTypes.LIST_BULLET || it.type == MarkdownTokenTypes.LIST_NUMBER
            }?.getTextInNode(src)?.toString()?.trim().orEmpty()
            val runs = mutableListOf<InlineRun>()
            val box = item.children.firstOrNull { it.type == GFMTokenTypes.CHECK_BOX }
            item.children.filter {
                it.type != MarkdownTokenTypes.LIST_BULLET && it.type != MarkdownTokenTypes.LIST_NUMBER &&
                    it.type != GFMTokenTypes.CHECK_BOX
            }
                .forEach { child ->
                    if (child.type == MarkdownElementTypes.PARAGRAPH || child.children.isNotEmpty()) {
                        if (runs.isNotEmpty()) runs += InlineRun(" ")
                        runs += inlines(child, src)
                    }
                }
            if (box != null) {
                flushPlain()
                val checked = box.getTextInNode(src).toString().trim().lowercase() == "[x]"
                tasks += TaskItem(0, checked, box.startOffset, runs.trimmed())
            } else {
                flushTasks()
                plain += ListItem(if (ordered) marker else "•", runs.trimmed())
            }
        }
        flushPlain()
        flushTasks()
        return out
    }

    private fun fenceText(node: ASTNode, src: String): String {
        val children = node.children
        val firstEol = children.indexOfFirst { it.type == MarkdownTokenTypes.EOL }
        if (firstEol < 0) return ""
        val start = children[firstEol].endOffset
        val endNode = children.lastOrNull { it.type == MarkdownTokenTypes.CODE_FENCE_END }
        val end = endNode?.startOffset ?: node.endOffset
        return if (end <= start) "" else src.substring(start, end).removeSuffix("\n")
    }

    private fun inlines(node: ASTNode, src: String): List<InlineRun> {
        val out = mutableListOf<InlineRun>()
        walkInline(node, src, bold = false, italic = false, out = out)
        return splitTags(out.trimmed())
    }

    /** Marks `#tag` tokens (iteration 2) inside non-code runs so the preview can style them. */
    private fun splitTags(runs: List<InlineRun>): List<InlineRun> {
        val out = mutableListOf<InlineRun>()
        var prev: Char? = null
        for (run in runs) {
            if (run.code) { out += run; prev = run.text.lastOrNull(); continue }
            // Prefix a sentinel so a tag at a run start is only accepted after whitespace / line start.
            val ctx = (if (prev == null || prev.isWhitespace()) " " else "x") + run.text
            val matches = Tags.findInLine(ctx)
            var last = 1
            for (m in matches) {
                if (m.start > last) out += run.copy(text = ctx.substring(last, m.start))
                out += run.copy(text = ctx.substring(m.start, m.end), tag = true)
                last = m.end
            }
            if (last < ctx.length) out += run.copy(text = ctx.substring(last))
            prev = run.text.lastOrNull()
        }
        return out
    }

    private fun walkInline(node: ASTNode, src: String, bold: Boolean, italic: Boolean, out: MutableList<InlineRun>) {
        when (node.type) {
            MarkdownElementTypes.STRONG -> node.children.forEach {
                if (it.type != MarkdownTokenTypes.EMPH) walkInline(it, src, true, italic, out)
            }
            MarkdownElementTypes.EMPH -> node.children.forEach {
                if (it.type != MarkdownTokenTypes.EMPH) walkInline(it, src, bold, true, out)
            }
            MarkdownElementTypes.CODE_SPAN -> {
                val text = node.children.filter { it.type != MarkdownTokenTypes.BACKTICK }
                    .joinToString("") { it.getTextInNode(src) }
                    .replace('\n', ' ')
                out += InlineRun(text.trim(), bold, italic, code = true)
            }
            MarkdownTokenTypes.EOL -> out += InlineRun(" ", bold, italic)
            MarkdownTokenTypes.BLOCK_QUOTE -> Unit
            else -> if (node.children.isEmpty()) {
                out += InlineRun(node.getTextInNode(src).toString(), bold, italic)
            } else {
                node.children.forEach { walkInline(it, src, bold, italic, out) }
            }
        }
    }

    /** Merge adjacent runs with identical style and trim surrounding whitespace. */
    private fun List<InlineRun>.trimmed(): List<InlineRun> {
        val merged = mutableListOf<InlineRun>()
        for (r in this) {
            val last = merged.lastOrNull()
            if (last != null && last.bold == r.bold && last.italic == r.italic && last.code == r.code && last.tag == r.tag) {
                merged[merged.lastIndex] = last.copy(text = last.text + r.text)
            } else merged += r
        }
        // collapse whitespace introduced by soft breaks + indentation
        val collapsed = merged.map { if (it.code || it.tag) it else it.copy(text = it.text.replace(Regex("[ \\t]*\\n?[ \\t]+"), " ")) }
            .toMutableList()
        if (collapsed.isNotEmpty() && !collapsed.first().code) collapsed[0] = collapsed[0].copy(text = collapsed[0].text.trimStart())
        if (collapsed.isNotEmpty() && !collapsed.last().code) collapsed[collapsed.lastIndex] = collapsed.last().copy(text = collapsed.last().text.trimEnd())
        return collapsed.filter { it.text.isNotEmpty() }
    }
}
