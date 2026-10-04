package com.mdnotes.kmp.ui

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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mdnotes.kmp.markdown.InlineRun
import com.mdnotes.kmp.markdown.MdBlock
import com.mdnotes.kmp.markdown.TaskItem
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.size
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.style.TextDecoration

private val bodyStyle get() = textStyle(17f, lineHeight = 24f.spx())

private fun List<InlineRun>.toAnnotated(): AnnotatedString = buildAnnotatedString {
    for (run in this@toAnnotated) {
        val style = when {
            run.code -> SpanStyle(
                fontFamily = MonoFontFamily,
                fontSize = 15.sp,
                color = Tokens.accent,
                background = Tokens.accentSoft,
            )
            run.tag -> SpanStyle(
                color = Tokens.accent,
                fontWeight = if (run.bold) FontWeight.Bold else FontWeight.Medium,
                fontStyle = if (run.italic) FontStyle.Italic else null,
            )
            else -> SpanStyle(
                fontWeight = if (run.bold) FontWeight.Bold else null,
                fontStyle = if (run.italic) FontStyle.Italic else null,
            )
        }
        if (run.code) {
            // Narrow padding around inline code, drawn in the body font so it stays thin.
            withStyle(SpanStyle(background = Tokens.accentSoft)) { append("\u2009") }
            withStyle(style) { append(run.text) }
            withStyle(SpanStyle(background = Tokens.accentSoft)) { append("\u2009") }
        } else {
            withStyle(style) { append(run.text) }
        }
    }
}

private data class Spacing(val above: Int, val below: Int)

private fun MdBlock.spacing(): Spacing = when (this) {
    is MdBlock.Heading -> when (level) {
        1 -> Spacing(0, 12)
        2 -> Spacing(16, 8)
        else -> Spacing(12, 6)
    }
    else -> Spacing(0, 12)
}

/** Renders parsed Markdown blocks per spec §4 (margins collapse like CSS). */
@Composable
fun MarkdownBlocks(blocks: List<MdBlock>, onToggleTask: (TaskItem) -> Unit = {}) {
    Column(Modifier.fillMaxWidth()) {
        var prevBelow = 0
        blocks.forEachIndexed { index, block ->
            val s = block.spacing()
            val gap = if (index == 0) 0 else maxOf(prevBelow, s.above)
            if (gap > 0) Spacer(Modifier.height(gap.dp))
            MarkdownBlock(block, onToggleTask)
            prevBelow = s.below
        }
    }
}

@Composable
private fun MarkdownBlock(block: MdBlock, onToggleTask: (TaskItem) -> Unit) {
    when (block) {
        is MdBlock.Heading -> {
            val style: TextStyle = when (block.level) {
                1 -> textStyle(28f, weight = FontWeight.Bold, lineHeight = 34f.spx())
                2 -> textStyle(22f, weight = FontWeight.Bold, lineHeight = 28f.spx())
                else -> textStyle(18f, weight = FontWeight.SemiBold, lineHeight = 24f.spx())
            }
            BasicText(block.content.toAnnotated(), style = style)
        }
        is MdBlock.Paragraph -> BasicText(block.content.toAnnotated(), style = bodyStyle)
        is MdBlock.ListBlock -> Column {
            block.items.forEachIndexed { i, item ->
                if (i > 0) Spacer(Modifier.height(4.dp))
                Row {
                    // Tabular figures keep "1." / "2." markers the same width so item text aligns.
                    BasicText(item.marker, style = bodyStyle.copy(fontFeatureSettings = "tnum"))
                    Spacer(Modifier.width(8.dp))
                    BasicText(item.content.toAnnotated(), style = bodyStyle, modifier = Modifier.weight(1f))
                }
            }
        }
        is MdBlock.Quote -> Row(Modifier.height(IntrinsicSize.Min)) {
            Box(Modifier.width(3.dp).fillMaxHeight().background(Tokens.accent))
            Spacer(Modifier.width(12.dp))
            BasicText(
                block.content.toAnnotated(),
                style = textStyle(17f, color = Tokens.textSecondary, lineHeight = 24f.spx(), italic = true),
                modifier = Modifier.weight(1f),
            )
        }
        is MdBlock.TaskList -> Column {
            block.items.forEachIndexed { i, item ->
                if (i > 0) Spacer(Modifier.height(8.dp))
                TaskRow(item) { onToggleTask(item) }
            }
        }
        is MdBlock.Code -> Box(
            Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(10.dp))
                .background(Tokens.codeBg)
                .padding(12.dp),
        ) {
            BasicText(
                block.text,
                style = textStyle(14f, color = Tokens.codeText, lineHeight = 20f.spx(), family = MonoFontFamily),
                softWrap = true,
            )
        }
    }
}

/** One checklist row: 22×22 checkbox, 10 pt gap, 17 pt text. The whole row toggles. */
@Composable
private fun TaskRow(item: TaskItem, onToggle: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .testTag("task-${item.index}")
            .semantics { stateDescription = if (item.checked) "checked" else "unchecked" }
            .plainClickable(Role.Checkbox, onClick = onToggle),
        verticalAlignment = Alignment.Top,
    ) {
        Box(Modifier.height(24.dp), contentAlignment = Alignment.Center) {
            val shape = RoundedCornerShape(6.dp)
            Box(
                Modifier
                    .size(22.dp)
                    .clip(shape)
                    .then(
                        if (item.checked) Modifier.background(Tokens.accent)
                        else Modifier.border(2.dp, Tokens.textTertiary, shape)
                    ),
                contentAlignment = Alignment.Center,
            ) {
                if (item.checked) {
                    BasicText("✓", modifier = Modifier.clearAndSetSemantics {}, style = textStyle(14f, color = Tokens.onAccent, weight = FontWeight.Bold, lineHeight = 16f.spx()))
                }
            }
        }
        Spacer(Modifier.width(10.dp))
        val text = item.content.toAnnotated()
        BasicText(
            text,
            modifier = Modifier.weight(1f),
            style = if (item.checked) {
                bodyStyle.copy(color = Tokens.textTertiary, textDecoration = TextDecoration.LineThrough)
            } else bodyStyle,
        )
    }
}
