package com.mdnotes.kotlin.markdown

import org.intellij.markdown.MarkdownElementTypes as E
import org.intellij.markdown.MarkdownTokenTypes as T
import org.intellij.markdown.ast.ASTNode
import org.intellij.markdown.flavours.gfm.GFMElementTypes
import org.intellij.markdown.flavours.gfm.GFMFlavourDescriptor
import org.intellij.markdown.flavours.gfm.GFMTokenTypes
import org.intellij.markdown.parser.MarkdownParser
import com.mdnotes.kotlin.data.NoteText

/** Inline content of a block. */
sealed interface Inline {
    data class Text(val text: String) : Inline
    data class Strong(val children: List<Inline>) : Inline
    data class Emphasis(val children: List<Inline>) : Inline
    data class Strike(val children: List<Inline>) : Inline
    data class Code(val text: String) : Inline
    data class Tag(val text: String) : Inline
    data object LineBreak : Inline
}

/** Block-level content, the subset of Markdown the Preview renders. */
sealed interface Block {
    data class Heading(val level: Int, val content: List<Inline>) : Block
    data class Paragraph(val content: List<Inline>) : Block
    data class ListBlock(val ordered: Boolean, val items: List<ListItem>) : Block
    data class Quote(val blocks: List<Block>) : Block
    data class CodeBlock(val code: String) : Block
    data object Rule : Block
}

/** A GFM task-list item (`- [ ] text` / `- [x] text`). [offset] is the position of `[` in the source. */
data class Task(val index: Int, val checked: Boolean, val offset: Int)

data class ListItem(val marker: String, val blocks: List<Block>, val task: Task? = null)

/**
 * Parses Markdown with JetBrains' CommonMark/GFM parser (org.jetbrains:markdown)
 * and maps its AST onto the small block model rendered by [MarkdownView].
 */
object MarkdownDocument {
    private val parser = MarkdownParser(GFMFlavourDescriptor())

    fun parse(source: String): List<Block> {
        val root = parser.buildMarkdownTreeFromString(source)
        return Builder(source).blocks(root.children)
    }

    /** All tasks in document order. */
    fun tasks(source: String): List<Task> {
        val out = mutableListOf<Task>()
        fun walk(blocks: List<Block>) {
            for (b in blocks) when (b) {
                is Block.ListBlock -> b.items.forEach { item -> item.task?.let(out::add); walk(item.blocks) }
                is Block.Quote -> walk(b.blocks)
                else -> Unit
            }
        }
        walk(parse(source))
        return out
    }

    /** Returns [source] with [task]'s checkbox flipped (`[ ]` <-> `[x]`). */
    fun toggle(source: String, task: Task): String {
        val i = task.offset + 1
        if (i >= source.length || source[task.offset] != '[') return source
        val replacement = if (task.checked) ' ' else 'x'
        return source.substring(0, i) + replacement + source.substring(i + 1)
    }

    private class Builder(private val src: String) {
        private fun ASTNode.text() = src.substring(startOffset, endOffset)
        private var taskCount = 0

        fun blocks(nodes: List<ASTNode>): List<Block> = nodes.mapNotNull { block(it) }

        private fun block(node: ASTNode): Block? = when (node.type) {
            E.ATX_1, E.ATX_2, E.ATX_3, E.ATX_4, E.ATX_5, E.ATX_6 -> {
                val level = node.children.firstOrNull { it.type == T.ATX_HEADER }?.text()?.length ?: 1
                val content = node.children.firstOrNull { it.type == T.ATX_CONTENT }
                Block.Heading(level, content?.let { inlines(it.children) }.orEmpty())
            }
            E.SETEXT_1, E.SETEXT_2 -> {
                val content = node.children.firstOrNull { it.type == T.SETEXT_CONTENT }
                Block.Heading(if (node.type == E.SETEXT_1) 1 else 2, content?.let { inlines(it.children) }.orEmpty())
            }
            E.PARAGRAPH -> Block.Paragraph(inlines(node.children))
            E.UNORDERED_LIST, E.ORDERED_LIST -> Block.ListBlock(
                ordered = node.type == E.ORDERED_LIST,
                items = node.children.filter { it.type == E.LIST_ITEM }.map { item ->
                    val markerNode = item.children.firstOrNull { it.type == T.LIST_BULLET || it.type == T.LIST_NUMBER }
                    val marker = when (markerNode?.type) {
                        T.LIST_NUMBER -> markerNode.text().trim()
                        else -> "•"
                    }
                    val checkBox = item.children.firstOrNull { it.type == GFMTokenTypes.CHECK_BOX }
                    val task = if (checkBox != null && node.type == E.UNORDERED_LIST) {
                        Task(taskCount++, checkBox.text().contains('x', ignoreCase = true), checkBox.startOffset)
                    } else null
                    val content = blocks(item.children.filter { it !== markerNode && it !== checkBox })
                    // In ordered lists a checkbox is not a task: keep its text.
                    val shown = if (checkBox != null && task == null) prefix(content, checkBox.text()) else content
                    ListItem(marker, shown, task)
                },
            )
            E.BLOCK_QUOTE -> Block.Quote(blocks(node.children))
            E.CODE_FENCE -> Block.CodeBlock(fenceContent(node))
            E.CODE_BLOCK -> Block.CodeBlock(
                node.children.joinToString("") {
                    when (it.type) {
                        T.CODE_LINE -> it.text().removePrefix("    ")
                        T.EOL -> "\n"
                        else -> ""
                    }
                }.trimEnd('\n'),
            )
            E.HTML_BLOCK, GFMElementTypes.TABLE -> Block.Paragraph(listOf(Inline.Text(node.text())))
            T.HORIZONTAL_RULE -> Block.Rule
            else -> null
        }

        private fun prefix(content: List<Block>, text: String): List<Block> {
            val first = content.firstOrNull() as? Block.Paragraph ?: return listOf(Block.Paragraph(listOf(Inline.Text(text)))) + content
            return listOf(Block.Paragraph(listOf(Inline.Text(text)) + first.content)) + content.drop(1)
        }

        private fun fenceContent(node: ASTNode): String {
            val sb = StringBuilder()
            var started = false
            for (child in node.children) {
                when (child.type) {
                    T.CODE_FENCE_START, T.FENCE_LANG -> Unit
                    T.CODE_FENCE_END -> break
                    T.EOL -> if (started) sb.append('\n') else started = true
                    else -> if (started) sb.append(child.text())
                }
            }
            return sb.toString().trimEnd('\n')
        }

        /** Inline content of a block with `#tags` split out of plain text runs. */
        fun inlines(nodes: List<ASTNode>): List<Inline> = tagify(rawInlines(nodes))

        private fun tagify(items: List<Inline>): List<Inline> {
            // Merge adjacent text so tag boundaries (line start / whitespace) are seen correctly.
            val merged = mutableListOf<Inline>()
            for (item in items) {
                val last = merged.lastOrNull()
                if (item is Inline.Text && last is Inline.Text) merged[merged.lastIndex] = Inline.Text(last.text + item.text)
                else merged += item
            }
            val out = mutableListOf<Inline>()
            merged.forEachIndexed { index, item ->
                when (item) {
                    is Inline.Text -> {
                        // Text right after a non-text inline (e.g. **bold**#x) is not at a boundary.
                        val atBoundary = index == 0 || (merged[index - 1] as? Inline.Text)?.text?.lastOrNull()?.isWhitespace() == true
                        val text = item.text
                        var last = 0
                        for (m in NoteText.TAG.findAll(text)) {
                            if (m.range.first == 0 && !atBoundary) continue
                            if (m.range.first > last) out += Inline.Text(text.substring(last, m.range.first))
                            out += Inline.Tag(m.value)
                            last = m.range.last + 1
                        }
                        if (last < text.length) out += Inline.Text(text.substring(last))
                    }
                    is Inline.Strong -> out += Inline.Strong(tagify(item.children))
                    is Inline.Emphasis -> out += Inline.Emphasis(tagify(item.children))
                    is Inline.Strike -> out += Inline.Strike(tagify(item.children))
                    else -> out += item
                }
            }
            return out.filterNot { it is Inline.Text && it.text.isEmpty() }
        }

        private fun rawInlines(nodes: List<ASTNode>): List<Inline> {
            val out = mutableListOf<Inline>()
            var atLineStart = true
            for (node in nodes) {
                when (node.type) {
                    T.EOL -> { out += Inline.Text(" "); atLineStart = true; continue }
                    T.BLOCK_QUOTE -> continue
                    T.WHITE_SPACE -> if (atLineStart) continue else out += Inline.Text(" ")
                    T.HARD_LINE_BREAK -> { out += Inline.LineBreak; atLineStart = true; continue }
                    E.STRONG -> out += Inline.Strong(rawInlines(node.children.filterNot { it.type == T.EMPH }))
                    E.EMPH -> out += Inline.Emphasis(rawInlines(node.children.filterNot { it.type == T.EMPH }))
                    GFMElementTypes.STRIKETHROUGH ->
                        out += Inline.Strike(rawInlines(node.children.filterNot { it.type == GFMTokenTypes.TILDE }))
                    E.CODE_SPAN -> out += Inline.Code(
                        node.children.filterNot { it.type == T.BACKTICK }.joinToString("") { it.text() }
                            .replace('\n', ' ').let { if (it.length > 2 && it.startsWith(" ") && it.endsWith(" ")) it.substring(1, it.length - 1) else it },
                    )
                    E.INLINE_LINK, E.FULL_REFERENCE_LINK, E.SHORT_REFERENCE_LINK -> {
                        val label = node.children.firstOrNull { it.type == E.LINK_TEXT }
                        if (label != null) {
                            out += rawInlines(label.children.filterNot { it.type == T.LBRACKET || it.type == T.RBRACKET })
                        } else {
                            out += Inline.Text(node.text())
                        }
                    }
                    E.AUTOLINK -> out += Inline.Text(node.text().removePrefix("<").removeSuffix(">"))
                    else -> if (node.children.isEmpty()) out += Inline.Text(node.text()) else out += rawInlines(node.children)
                }
                atLineStart = false
            }
            return out
        }
    }
}
