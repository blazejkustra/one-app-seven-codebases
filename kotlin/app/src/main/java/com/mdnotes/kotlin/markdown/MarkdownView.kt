package com.mdnotes.kotlin.markdown

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.foundation.border
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.selection.toggleable
import androidx.compose.ui.Alignment
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mdnotes.kotlin.ui.Tokens
import com.mdnotes.kotlin.ui.textStyle

private val BodyStyle get() = textStyle(17.sp, lineHeight = 24.sp)
private val QuoteStyle get() = textStyle(17.sp, color = Tokens.TextSecondary, lineHeight = 24.sp, italic = true)
private val CodeSpanStyle get() = SpanStyle(
    fontFamily = Tokens.Mono,
    fontSize = 15.sp,
    color = Tokens.Accent,
    background = Tokens.AccentSoft,
)

private val LocalTaskToggle = staticCompositionLocalOf<((Task) -> Unit)?> { null }

/** Renders Markdown per spec §4. Parsing is done by [MarkdownDocument]. */
@Composable
fun MarkdownView(source: String, modifier: Modifier = Modifier, onToggleTask: ((Task) -> Unit)? = null) {
    val blocks = remember(source) { MarkdownDocument.parse(source) }
    CompositionLocalProvider(LocalTaskToggle provides onToggleTask) {
        Column(modifier) { Blocks(blocks, BodyStyle, topLevel = true) }
    }
}

private fun Block.startsWithTask() = this is Block.ListBlock && items.firstOrNull()?.task != null
private fun Block.endsWithTask() = this is Block.ListBlock && items.lastOrNull()?.task != null

private fun Block.marginTop(): Dp = when (this) {
    is Block.Heading -> when (level) { 1 -> 0.dp; 2 -> 16.dp; else -> 12.dp }
    else -> 0.dp
}

private fun Block.marginBottom(): Dp = when (this) {
    is Block.Heading -> when (level) { 1 -> 12.dp; 2 -> 8.dp; else -> 6.dp }
    else -> 12.dp
}

@Composable
private fun Blocks(blocks: List<Block>, base: TextStyle, topLevel: Boolean) {
    blocks.forEachIndexed { index, block ->
        if (index > 0) {
            val prev = blocks[index - 1]
            val gap = when {
                // Consecutive tasks (even across lists with different bullets) form one group.
                prev.endsWithTask() && block.startsWithTask() -> 8.dp
                topLevel -> prev.marginBottom() + block.marginTop()
                else -> 4.dp
            }
            Spacer(Modifier.height(gap))
        }
        BlockView(block, base)
    }
}

@Composable
private fun BlockView(block: Block, base: TextStyle) {
    when (block) {
        is Block.Heading -> {
            val style = when (block.level) {
                1 -> base.merge(TextStyle(fontSize = 28.sp, lineHeight = 34.sp, fontWeight = FontWeight.Bold))
                2 -> base.merge(TextStyle(fontSize = 22.sp, lineHeight = 28.sp, fontWeight = FontWeight.Bold))
                else -> base.merge(TextStyle(fontSize = 18.sp, lineHeight = 24.sp, fontWeight = FontWeight.SemiBold))
            }
            BasicText(inlineText(block.content), style = style)
        }
        is Block.Paragraph -> BasicText(inlineText(block.content), style = base)
        is Block.ListBlock -> Column {
            block.items.forEachIndexed { i, item ->
                if (i > 0) Spacer(Modifier.height(if (item.task != null && block.items[i - 1].task != null) 8.dp else 4.dp))
                if (item.task != null) {
                    TaskRow(item.task, item.blocks, base)
                    return@forEachIndexed
                }
                Row {
                    BasicText(
                        item.marker,
                        style = base,
                        modifier = Modifier.widthIn(min = if (block.ordered) 18.dp else 0.dp),
                    )
                    Spacer(Modifier.width(8.dp))
                    Column(Modifier.weight(1f)) { Blocks(item.blocks, base, topLevel = false) }
                }
            }
        }
        is Block.Quote -> Row(Modifier.height(IntrinsicSize.Min)) {
            Box(Modifier.width(3.dp).fillMaxHeight().background(Tokens.Accent))
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) { Blocks(block.blocks, QuoteStyle, topLevel = false) }
        }
        is Block.CodeBlock -> Box(
            Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(10.dp))
                .background(Tokens.CodeBg)
                .padding(12.dp),
        ) {
            BasicText(
                block.code,
                style = textStyle(14.sp, color = Tokens.CodeText, lineHeight = 20.sp, family = Tokens.Mono),
            )
        }
        Block.Rule -> Box(Modifier.fillMaxWidth().height(1.dp).background(Tokens.Separator))
    }
}

@Composable
private fun TaskRow(task: Task, blocks: List<Block>, base: TextStyle) {
    val onToggle = LocalTaskToggle.current
    val rowStyle = if (task.checked) {
        base.merge(TextStyle(color = Tokens.TextTertiary, textDecoration = TextDecoration.LineThrough))
    } else base
    Row(
        Modifier
            .fillMaxWidth()
            .semantics { stateDescription = if (task.checked) "checked" else "unchecked" }
            .testTag("task-${task.index}")
            .toggleable(
                value = task.checked,
                enabled = onToggle != null,
                role = Role.Checkbox,
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onValueChange = { onToggle?.invoke(task) },
            ),
    ) {
        Box(
            Modifier
                .padding(top = 1.dp)
                .size(22.dp)
                .clearAndSetSemantics {}
                .clip(RoundedCornerShape(6.dp))
                .then(
                    if (task.checked) Modifier.background(Tokens.Accent)
                    else Modifier.border(2.dp, Tokens.TextTertiary, RoundedCornerShape(6.dp)),
                ),
            contentAlignment = Alignment.Center,
        ) {
            if (task.checked) {
                BasicText("\u2713", style = textStyle(14.sp, color = Color.White, weight = FontWeight.Bold))
            }
        }
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f)) {
            if (blocks.isEmpty()) BasicText("", style = rowStyle) else Blocks(blocks, rowStyle, topLevel = false)
        }
    }
}

private fun inlineText(content: List<Inline>): AnnotatedString = buildAnnotatedString {
    fun append(items: List<Inline>) {
        for (item in items) when (item) {
            is Inline.Text -> append(item.text)
            is Inline.Strong -> withStyle(SpanStyle(fontWeight = FontWeight.Bold)) { append(item.children) }
            is Inline.Emphasis -> withStyle(SpanStyle(fontStyle = FontStyle.Italic)) { append(item.children) }
            is Inline.Strike -> withStyle(SpanStyle(textDecoration = TextDecoration.LineThrough)) { append(item.children) }
            is Inline.Code -> withStyle(CodeSpanStyle) { append(" ${item.text} ") }
            is Inline.Tag -> withStyle(SpanStyle(color = Tokens.Accent, fontWeight = FontWeight.Medium)) { append(item.text) }
            Inline.LineBreak -> append("\n")
        }
    }
    append(content)
}.let { full ->
    val start = full.text.indexOfFirst { !it.isWhitespace() }
    if (start < 0) AnnotatedString("") else full.subSequence(start, full.text.indexOfLast { !it.isWhitespace() } + 1)
}
