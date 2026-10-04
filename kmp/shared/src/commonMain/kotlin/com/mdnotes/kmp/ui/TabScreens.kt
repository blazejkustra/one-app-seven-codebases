package com.mdnotes.kmp.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.mdnotes.kmp.data.Note
import com.mdnotes.kmp.data.Settings
import com.mdnotes.kmp.data.SortOrder

@Composable
private fun NoteList(
    notes: List<Note>,
    showSnippets: Boolean,
    emptyText: String,
    onOpen: (Note) -> Unit,
    modifier: Modifier = Modifier,
) {
    if (notes.isEmpty()) {
        EmptyState(emptyText, modifier.fillMaxSize())
    } else {
        LazyColumn(
            modifier.fillMaxSize(),
            contentPadding = PaddingValues(top = 12.dp, bottom = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            items(notes, key = { it.id }) { note ->
                NoteCard(note, showSnippets) { onOpen(note) }
            }
        }
    }
}

@Composable
fun NotesScreen(
    notes: List<Note>,
    settings: Settings,
    query: String,
    onQueryChange: (String) -> Unit,
    selectedTag: String?,
    onSelectTag: (String?) -> Unit,
    onAdd: () -> Unit,
    onOpen: (Note) -> Unit,
    modifier: Modifier = Modifier,
) {
    val allTags = notes.flatMap { it.tags }.distinct().sorted()
    // A selected tag that no longer exists on any note falls back to "All".
    val activeTag = selectedTag?.takeIf { it in allTags }
    if (selectedTag != null && activeTag == null) SideEffect { onSelectTag(null) }
    val filtered = notes
        .filter { query.isEmpty() || it.body.contains(query, ignoreCase = true) }
        .filter { activeTag == null || activeTag in it.tags }
    val focusManager = LocalFocusManager.current
    Column(modifier) {
        ScreenHeader("Notes") { AddButton(onAdd) }
        Spacer(Modifier.height(4.dp))
        SearchField(query, onQueryChange)
        Spacer(Modifier.height(12.dp))
        TagFilterRow(allTags, activeTag, onSelectTag)
        NoteList(
            filtered,
            settings.showSnippets,
            if (notes.isEmpty()) "No notes yet" else "No notes found",
            onOpen,
            Modifier.weight(1f).pointerInput(Unit) {
                // Tapping or dragging the list area dismisses the search keyboard.
                awaitEachGesture {
                    awaitFirstDown(requireUnconsumed = false)
                    focusManager.clearFocus()
                }
            },
        )
    }
}

@Composable
private fun SearchField(query: String, onQueryChange: (String) -> Unit) {
    val focusManager = LocalFocusManager.current
    val style = textStyle(17f, lineHeight = 22f.spx())
    BasicTextField(
        value = query,
        onValueChange = onQueryChange,
        singleLine = true,
        textStyle = style,
        cursorBrush = SolidColor(Tokens.accent),
        keyboardOptions = KeyboardOptions(
            capitalization = KeyboardCapitalization.None,
            autoCorrectEnabled = false,
            imeAction = ImeAction.Search,
        ),
        keyboardActions = KeyboardActions(onSearch = { focusManager.clearFocus() }),
        modifier = Modifier
            .padding(horizontal = 16.dp)
            .fillMaxWidth()
            .height(40.dp)
            .testTag("search-input"),
        decorationBox = { inner ->
            Box(
                Modifier
                    .fillMaxSize()
                    .clip(RoundedCornerShape(10.dp))
                    .background(Tokens.fill)
                    .padding(start = 12.dp, end = 12.dp),
                contentAlignment = Alignment.CenterStart,
            ) {
                if (query.isEmpty()) BasicText("Search notes", style = style.copy(color = Tokens.textTertiary))
                inner()
            }
        },
    )
}

@Composable
fun StarredScreen(notes: List<Note>, settings: Settings, onOpen: (Note) -> Unit, modifier: Modifier = Modifier) {
    Column(modifier) {
        ScreenHeader("Starred")
        NoteList(notes.filter { it.starred }, settings.showSnippets, "No starred notes", onOpen, Modifier.weight(1f))
    }
}

@Composable
fun SettingsScreen(
    settings: Settings,
    noteCount: Int,
    onToggleSort: () -> Unit,
    onSnippetsChange: (Boolean) -> Unit,
    onCycleAppearance: () -> Unit,
    onReset: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val label = textStyle(17f, lineHeight = 22f.spx())
    Column(modifier) {
        ScreenHeader("Settings")
        Spacer(Modifier.height(12.dp))
        Group {
            Row(
                rowModifier(inner = Modifier.testTag("sort-row").plainClickable(onClick = onToggleSort)),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                BasicText("Sort by", style = label)
                Spacer(Modifier.weight(1f))
                BasicText(
                    if (settings.sortOrder == SortOrder.Updated) "Updated" else "Title",
                    style = label.copy(color = Tokens.accent),
                )
            }
            Row(rowModifier(separator = true), verticalAlignment = Alignment.CenterVertically) {
                BasicText("Show snippets", style = label)
                Spacer(Modifier.weight(1f))
                PillSwitch(settings.showSnippets, onSnippetsChange, Modifier.testTag("snippets-switch"))
            }
            Row(
                rowModifier(separator = true, Modifier.testTag("appearance-row").plainClickable(onClick = onCycleAppearance)),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                BasicText("Appearance", style = label)
                Spacer(Modifier.weight(1f))
                BasicText(settings.appearance.label, style = label.copy(color = Tokens.accent))
            }
            Row(rowModifier(separator = true), verticalAlignment = Alignment.CenterVertically) {
                BasicText("Notes", style = label)
                Spacer(Modifier.weight(1f))
                BasicText(
                    noteCount.toString(),
                    style = label.copy(color = Tokens.textTertiary),
                    modifier = Modifier.testTag("notes-count"),
                )
            }
        }
        Spacer(Modifier.height(24.dp))
        Group {
            Box(
                rowModifier(inner = Modifier.testTag("reset-button").plainClickable(onClick = onReset)),
                contentAlignment = Alignment.Center,
            ) {
                BasicText("Reset sample notes", style = label.copy(color = Tokens.danger))
            }
        }
        Spacer(Modifier.height(16.dp))
        BasicText(
            "Markdown Notes · v1.0",
            style = textStyle(13f, color = Tokens.textTertiary).copy(textAlign = TextAlign.Center),
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

@Composable
private fun Group(content: @Composable () -> Unit) {
    Column(
        Modifier
            .padding(horizontal = 16.dp)
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(Tokens.surface),
    ) { content() }
}

/** A 52 pt settings row; [separator] draws the 1 pt inset line along its top edge. */
private fun rowModifier(separator: Boolean = false, inner: Modifier = Modifier): Modifier {
    val base = Modifier.fillMaxWidth().height(52.dp)
    val withLine = if (!separator) base else base.drawBehind {
        val inset = 16.dp.toPx()
        val h = 1.dp.toPx()
        drawRect(Tokens.separator, topLeft = Offset(inset, 0f), size = Size(size.width - inset, h))
    }
    return withLine.then(inner).padding(horizontal = 16.dp)
}

