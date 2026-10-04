package com.mdnotes.kotlin.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mdnotes.kotlin.data.AppSettings
import com.mdnotes.kotlin.data.SortOrder

@Composable
fun NotesScreen(
    notes: List<NoteItem>,
    settings: AppSettings,
    query: String,
    onQuery: (String) -> Unit,
    selectedTag: String?,
    onSelectTag: (String?) -> Unit,
    listState: LazyListState,
    onAdd: () -> Unit,
    onOpen: (NoteItem) -> Unit,
) {
    Column(Modifier.fillMaxSize()) {
        ScreenHeader("Notes") { AddButton(onAdd) }
        SearchField(query, onQuery, Modifier.padding(start = 16.dp, end = 16.dp, top = 4.dp))
        val allTags = remember(notes) { notes.flatMap { it.tags }.distinct().sorted() }
        // A selection whose tag disappeared from every note falls back to All.
        val activeTag = selectedTag?.takeIf { it in allTags }
        LaunchedEffect(activeTag, selectedTag) { if (selectedTag != null && activeTag == null) onSelectTag(null) }
        VSpace(12)
        TagFilterRow(allTags, activeTag, onSelectTag)
        val filtered = notes.filter { note ->
            (activeTag == null || activeTag in note.tags) &&
                (query.isEmpty() || note.body.contains(query, ignoreCase = true))
        }
        NoteList(
            notes = filtered,
            showSnippets = settings.showSnippets,
            emptyText = if (notes.isEmpty()) "No notes yet" else "No notes found",
            listState = listState,
            onOpen = onOpen,
            modifier = Modifier.weight(1f),
        )
    }
}

@Composable
private fun SearchField(query: String, onQuery: (String) -> Unit, modifier: Modifier = Modifier) {
    val focus = LocalFocusManager.current
    BasicTextField(
        value = query,
        onValueChange = onQuery,
        singleLine = true,
        textStyle = textStyle(17.sp),
        cursorBrush = SolidColor(Tokens.Accent),
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
        keyboardActions = KeyboardActions(onSearch = { focus.clearFocus() }),
        modifier = modifier
            .fillMaxWidth()
            .height(40.dp)
            .clip(RoundedCornerShape(10.dp))
            .background(Tokens.Fill)
            .testTag("search-input"),
        decorationBox = { inner ->
            Box(Modifier.fillMaxSize().padding(start = 12.dp, end = 12.dp), contentAlignment = Alignment.CenterStart) {
                if (query.isEmpty()) Label("Search notes", textStyle(17.sp, color = Tokens.TextTertiary), maxLines = 1)
                inner()
            }
        },
    )
}

@Composable
fun StarredScreen(
    notes: List<NoteItem>,
    settings: AppSettings,
    listState: LazyListState,
    onOpen: (NoteItem) -> Unit,
) {
    Column(Modifier.fillMaxSize()) {
        ScreenHeader("Starred")
        NoteList(
            notes = notes.filter { it.starred },
            showSnippets = settings.showSnippets,
            emptyText = "No starred notes",
            listState = listState,
            onOpen = onOpen,
            modifier = Modifier.weight(1f),
        )
    }
}

@Composable
fun SettingsScreen(
    settings: AppSettings,
    noteCount: Int,
    onToggleSort: () -> Unit,
    onShowSnippets: (Boolean) -> Unit,
    onCycleAppearance: () -> Unit,
    onReset: () -> Unit,
) {
    Column(Modifier.fillMaxSize()) {
        ScreenHeader("Settings")
        VSpace(12)
        Group {
            SettingsRow("Sort by", Modifier.testTag("sort-row").tap(onClick = onToggleSort)) {
                Label(
                    if (settings.sortOrder == SortOrder.TITLE) "Title" else "Updated",
                    textStyle(17.sp, color = Tokens.Accent),
                )
            }
            RowSeparator()
            SettingsRow("Show snippets") {
                PillSwitch(settings.showSnippets, onShowSnippets, Modifier.testTag("snippets-switch"))
            }
            RowSeparator()
            SettingsRow("Appearance", Modifier.testTag("appearance-row").tap(onClick = onCycleAppearance)) {
                Label(settings.appearance.label, textStyle(17.sp, color = Tokens.Accent))
            }
            RowSeparator()
            SettingsRow("Notes") {
                Label(noteCount.toString(), textStyle(17.sp, color = Tokens.TextTertiary), Modifier.testTag("notes-count"))
            }
        }
        VSpace(24)
        Group {
            Box(
                Modifier.fillMaxWidth().height(52.dp).testTag("reset-button").tap(onClick = onReset),
                contentAlignment = Alignment.Center,
            ) {
                Label("Reset sample notes", textStyle(17.sp, color = Tokens.Danger))
            }
        }
        VSpace(16)
        Label(
            "Markdown Notes · v1.0",
            textStyle(13.sp, color = Tokens.TextTertiary, align = TextAlign.Center),
            Modifier.fillMaxWidth(),
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
            .background(Tokens.Surface),
    ) { content() }
}

@Composable
private fun SettingsRow(label: String, modifier: Modifier = Modifier, trailing: @Composable () -> Unit) {
    Row(
        modifier.fillMaxWidth().height(52.dp).padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Label(label, textStyle(17.sp), Modifier.weight(1f))
        trailing()
    }
}

@Composable
private fun RowSeparator() {
    Box(Modifier.padding(start = 16.dp).fillMaxWidth().height(1.dp).background(Tokens.Separator))
}
