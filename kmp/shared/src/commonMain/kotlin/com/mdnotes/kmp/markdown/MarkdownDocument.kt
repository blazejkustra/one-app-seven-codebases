package com.mdnotes.kmp.markdown

/** A run of inline text with the styles that apply to it. */
data class InlineRun(
    val text: String,
    val bold: Boolean = false,
    val italic: Boolean = false,
    val code: Boolean = false,
    val tag: Boolean = false,
)

/** The block-level subset of Markdown the preview renders (spec §4). */
sealed interface MdBlock {
    data class Heading(val level: Int, val content: List<InlineRun>) : MdBlock
    data class Paragraph(val content: List<InlineRun>) : MdBlock
    data class ListBlock(val ordered: Boolean, val items: List<ListItem>) : MdBlock
    data class Quote(val content: List<InlineRun>) : MdBlock
    data class Code(val text: String) : MdBlock
    /** Consecutive task items (`- [ ] text` / `- [x] text`). */
    data class TaskList(val items: List<TaskItem>) : MdBlock
}

data class ListItem(val marker: String, val content: List<InlineRun>)

/**
 * A checklist item. [boxOffset] is the source offset of its `[` so the body can be rewritten;
 * [index] is its position among all tasks of the document.
 */
data class TaskItem(val index: Int, val checked: Boolean, val boxOffset: Int, val content: List<InlineRun>)
