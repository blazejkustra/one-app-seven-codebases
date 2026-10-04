package com.mdnotes.kmp.ui

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsBottomHeight
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.selection.toggleable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.mdnotes.kmp.data.Note
import com.mdnotes.kmp.data.NoteText

/** Clickable without the Material ripple / highlight. */
@Composable
fun Modifier.plainClickable(role: Role = Role.Button, onClick: () -> Unit): Modifier =
    this.clickable(
        interactionSource = remember { MutableInteractionSource() },
        indication = null,
        role = role,
        onClick = onClick,
    )

enum class Tab(val label: String, val tag: String) {
    Notes("Notes", "tab-notes"),
    Starred("Starred", "tab-starred"),
    Settings("Settings", "tab-settings"),
}

@Composable
fun TabBar(selected: Tab, onSelect: (Tab) -> Unit) {
    Column(Modifier.fillMaxWidth().background(Tokens.surface)) {
        Box(Modifier.fillMaxWidth().height(1.dp).background(Tokens.separator))
        Row(Modifier.fillMaxWidth().height(55.dp)) {
            Tab.entries.forEach { tab ->
                val active = tab == selected
                Box(
                    Modifier
                        .weight(1f)
                        .height(55.dp)
                        .testTag(tab.tag)
                        .semantics { this.selected = active }
                        .plainClickable(Role.Tab) { onSelect(tab) },
                    contentAlignment = Alignment.Center,
                ) {
                    BasicText(
                        tab.label,
                        style = textStyle(
                            15f,
                            color = if (active) Tokens.accent else Tokens.textTertiary,
                            weight = if (active) FontWeight.SemiBold else FontWeight.Medium,
                        ),
                    )
                }
            }
        }
        Spacer(Modifier.windowInsetsBottomHeight(WindowInsets.navigationBars))
    }
}

@Composable
fun ScreenHeader(title: String, trailing: @Composable (() -> Unit)? = null) {
    Row(
        Modifier.fillMaxWidth().height(52.dp).padding(horizontal = 20.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        BasicText(title, style = textStyle(34f, weight = FontWeight.Bold, lineHeight = 41f.spx()))
        Spacer(Modifier.weight(1f))
        trailing?.invoke()
    }
}

@Composable
fun AddButton(onClick: () -> Unit) {
    Box(
        Modifier
            .size(36.dp)
            .testTag("add-note-button")
            .clip(CircleShape)
            .background(Tokens.accent)
            .plainClickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        BasicText(
            "+",
            modifier = Modifier.offset(y = (-1).dp),
            style = textStyle(24f, color = Tokens.onAccent, lineHeight = 28f.spx()),
        )
    }
}

@Composable
fun NoteCard(note: Note, showSnippet: Boolean, onClick: () -> Unit) {
    val title = remember(note.body) { NoteText.title(note.body) }
    val snippet = remember(note.body) { NoteText.snippet(note.body) }
    Column(
        Modifier
            .padding(horizontal = 16.dp)
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(Tokens.surface)
            .testTag("note-card")
            .plainClickable(onClick = onClick)
            .padding(16.dp),
    ) {
        BasicText(
            title,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            style = textStyle(17f, weight = FontWeight.SemiBold, lineHeight = 22f.spx()),
        )
        if (showSnippet && snippet.isNotEmpty()) {
            Spacer(Modifier.height(4.dp))
            BasicText(
                snippet,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                style = textStyle(15f, color = Tokens.textSecondary, lineHeight = 20f.spx()),
            )
        }
        if (note.tags.isNotEmpty()) {
            Spacer(Modifier.height(8.dp))
            // Single line of chips; anything that does not fit is clipped.
            Row(
                Modifier
                    .fillMaxWidth()
                    .clipToBounds()
                    .wrapContentWidth(Alignment.Start, unbounded = true),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                note.tags.forEach { TagChip(it) }
            }
        }
        Spacer(Modifier.height(8.dp))
        Row(Modifier.fillMaxWidth().height(18.dp), verticalAlignment = Alignment.CenterVertically) {
            BasicText(
                NoteText.dateLabel(note.updatedAt),
                style = textStyle(13f, color = Tokens.textTertiary, lineHeight = 18f.spx()),
            )
            val (done, total) = remember(note.body) { NoteText.taskProgress(note.body) }
            if (total > 0) {
                Spacer(Modifier.width(12.dp))
                BasicText(
                    "$done/$total done",
                    style = textStyle(13f, color = Tokens.textSecondary, lineHeight = 18f.spx()),
                )
            }
            Spacer(Modifier.weight(1f))
            if (note.starred) {
                BasicText("★", style = textStyle(16f, color = Tokens.star, lineHeight = 18f.spx()))
            }
        }
    }
}

@Composable
fun TagChip(tag: String) {
    Box(
        Modifier
            .height(22.dp)
            .clip(RoundedCornerShape(11.dp))
            .background(Tokens.accentSoft)
            .padding(horizontal = 8.dp),
        contentAlignment = Alignment.Center,
    ) {
        BasicText(
            "#$tag",
            maxLines = 1,
            softWrap = false,
            style = textStyle(12f, color = Tokens.accent, weight = FontWeight.Medium, lineHeight = 16f.spx()),
        )
    }
}

/** Horizontally scrolling tag filter for the Notes tab (`All` + every tag A→Z). */
@Composable
fun TagFilterRow(tags: List<String>, selected: String?, onSelect: (String?) -> Unit) {
    LazyRow(
        Modifier.fillMaxWidth().height(32.dp),
        contentPadding = PaddingValues(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        item(key = "__all") { FilterChip("All", "tag-filter-all", selected == null) { onSelect(null) } }
        items(tags, key = { it }) { tag ->
            FilterChip("#$tag", "tag-filter-$tag", selected == tag) { onSelect(tag) }
        }
    }
}

@Composable
private fun FilterChip(label: String, tag: String, active: Boolean, onClick: () -> Unit) {
    Box(
        Modifier
            .height(32.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(if (active) Tokens.accent else Tokens.surface)
            .testTag(tag)
            .semantics { selected = active }
            .plainClickable(onClick = onClick)
            .padding(horizontal = 12.dp),
        contentAlignment = Alignment.Center,
    ) {
        BasicText(
            label,
            maxLines = 1,
            softWrap = false,
            style = textStyle(
                15f,
                color = if (active) Tokens.onAccent else Tokens.text,
                weight = if (active) FontWeight.SemiBold else FontWeight.Medium,
            ),
        )
    }
}

/** "Note deleted · Undo" toast shown above the tab bar. */
@Composable
fun UndoToast(onUndo: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier
            .fillMaxWidth()
            .height(48.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(Tokens.toastBg)
            .testTag("toast")
            .semantics(mergeDescendants = true) {}
            .padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        BasicText("Note deleted", style = textStyle(15f, color = Color.White, lineHeight = 20f.spx()))
        Spacer(Modifier.weight(1f))
        Box(
            Modifier.fillMaxHeight().testTag("undo-button").plainClickable(onClick = onUndo),
            contentAlignment = Alignment.Center,
        ) {
            BasicText(
                "Undo",
                style = textStyle(15f, color = Color(0xFFA79FFF), weight = FontWeight.SemiBold, lineHeight = 20f.spx()),
            )
        }
    }
}

@Composable
fun EmptyState(text: String, modifier: Modifier = Modifier) {
    Box(modifier, contentAlignment = Alignment.Center) {
        BasicText(
            text,
            modifier = Modifier.testTag("empty-state"),
            style = textStyle(17f, color = Tokens.textTertiary).copy(textAlign = TextAlign.Center),
        )
    }
}

@Composable
fun PillSwitch(checked: Boolean, onCheckedChange: (Boolean) -> Unit, modifier: Modifier = Modifier) {
    val knobX by animateDpAsState(if (checked) 22.dp else 2.dp)
    val track by animateColorAsState(if (checked) Tokens.accent else Tokens.fill)
    Box(
        modifier
            .size(width = 51.dp, height = 31.dp)
            .clip(RoundedCornerShape(15.5.dp))
            .background(track)
            .semantics {
                contentDescription = "Show snippets"
                stateDescription = if (checked) "1" else "0"
            }
            .toggleable(
                value = checked,
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                role = Role.Switch,
                onValueChange = onCheckedChange,
            ),
    ) {
        Box(
            Modifier
                .offset(x = knobX, y = 2.dp)
                .size(27.dp)
                .clip(CircleShape)
                .background(Tokens.onAccent),
        )
    }
}

@Composable
fun SegmentedControl(editMode: Boolean, onSelect: (edit: Boolean) -> Unit) {
    Row(
        Modifier
            .padding(horizontal = 16.dp)
            .fillMaxWidth()
            .height(36.dp)
            .clip(RoundedCornerShape(9.dp))
            .background(Tokens.fill)
            .padding(2.dp),
    ) {
        listOf(true to "Edit", false to "Preview").forEach { (isEdit, label) ->
            val active = isEdit == editMode
            Box(
                Modifier
                    .weight(1f)
                    .height(32.dp)
                    .clip(RoundedCornerShape(7.dp))
                    .background(if (active) Tokens.surface else Tokens.fill)
                    .testTag(if (isEdit) "mode-edit" else "mode-preview")
                    .semantics { selected = active }
                    .plainClickable(Role.Tab) { onSelect(isEdit) },
                contentAlignment = Alignment.Center,
            ) {
                BasicText(
                    label,
                    style = textStyle(
                        15f,
                        color = if (active) Tokens.text else Tokens.textSecondary,
                        weight = if (active) FontWeight.SemiBold else FontWeight.Medium,
                    ),
                )
            }
        }
    }
}

fun Float.spx() = androidx.compose.ui.unit.TextUnit(this, androidx.compose.ui.unit.TextUnitType.Sp)
