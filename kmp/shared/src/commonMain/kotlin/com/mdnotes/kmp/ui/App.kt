package com.mdnotes.kmp.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.unit.dp
import com.mdnotes.kmp.data.Note
import com.mdnotes.kmp.data.Appearance
import androidx.compose.foundation.isSystemInDarkTheme
import kotlinx.coroutines.delay
import androidx.compose.ui.platform.LocalFocusManager
import com.mdnotes.kmp.data.NoteText
import com.mdnotes.kmp.data.NotesRepository
import com.mdnotes.kmp.data.SortOrder

private data class EditorRoute(val noteId: String, val startInEdit: Boolean)

private data class UndoState(val note: Note, val token: Long)

@Composable
fun App(repository: NotesRepository) {
    val allNotes by repository.notes.collectAsState()
    val settings by repository.settings.collectAsState()
    var tab by remember { mutableStateOf(Tab.Notes) }
    var editor by remember { mutableStateOf<EditorRoute?>(null) }
    var query by remember { mutableStateOf("") }
    var selectedTag by remember { mutableStateOf<String?>(null) }
    val focusManager = LocalFocusManager.current
    // Latest deletion that can still be undone; a new deletion replaces it (and restarts the timer).
    var undo by remember { mutableStateOf<UndoState?>(null) }
    undo?.let { current ->
        LaunchedEffect(current.token) {
            delay(4_000)
            if (undo?.token == current.token) undo = null
        }
    }

    // Theme: System follows the iOS appearance live; Light/Dark force it (incl. keyboard & status bar).
    val systemDark = isSystemInDarkTheme()
    val dark = when (settings.appearance) {
        Appearance.System -> systemDark
        Appearance.Light -> false
        Appearance.Dark -> true
    }
    Tokens.dark = dark
    LaunchedEffect(settings.appearance, dark) { applyInterfaceStyle(settings.appearance) }

    val sorted = remember(allNotes, settings.sortOrder) { NoteText.sorted(allNotes, settings.sortOrder) }

    Box(Modifier.fillMaxSize().background(Tokens.bg)) {
        val route = editor
        val note = route?.let { r -> allNotes.firstOrNull { it.id == r.noteId } }
        if (route != null && note != null) {
            EditorScreen(
                noteId = note.id,
                initialBody = note.body,
                starred = note.starred,
                startInEdit = route.startInEdit,
                onBodyChange = { repository.updateBody(note.id, it) },
                onToggleStar = { repository.setStarred(note.id, !note.starred) },
                onDelete = {
                    repository.delete(note.id)?.let { deleted ->
                        undo = UndoState(deleted, (undo?.token ?: 0L) + 1)
                    }
                    editor = null
                },
                onBack = { finalBody ->
                    if (finalBody.isBlank()) repository.delete(note.id)
                    editor = null
                },
                modifier = Modifier.windowInsetsPadding(WindowInsets.statusBars),
            )
        } else {
            Column(Modifier.fillMaxSize()) {
              Box(Modifier.weight(1f).fillMaxWidth()) {
                val content = Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.statusBars)
                val open = { id: String, edit: Boolean ->
                    focusManager.clearFocus()
                    editor = EditorRoute(id, edit)
                }
                when (tab) {
                    Tab.Notes -> NotesScreen(
                        notes = sorted,
                        settings = settings,
                        query = query,
                        onQueryChange = { query = it },
                        selectedTag = selectedTag,
                        onSelectTag = { selectedTag = it },
                        onAdd = { open(repository.createNote().id, true) },
                        onOpen = { open(it.id, false) },
                        modifier = content,
                    )
                    Tab.Starred -> StarredScreen(sorted, settings, { open(it.id, false) }, content)
                    Tab.Settings -> SettingsScreen(
                        settings = settings,
                        noteCount = allNotes.size,
                        onToggleSort = {
                            repository.setSortOrder(
                                if (settings.sortOrder == SortOrder.Updated) SortOrder.Title else SortOrder.Updated
                            )
                        },
                        onSnippetsChange = repository::setShowSnippets,
                        onCycleAppearance = { repository.setAppearance(settings.appearance.next()) },
                        onReset = repository::resetSampleNotes,
                        modifier = content,
                    )
                }
                undo?.let { current ->
                    UndoToast(
                        modifier = Modifier.align(Alignment.BottomCenter).padding(start = 16.dp, end = 16.dp, bottom = 12.dp),
                        onUndo = {
                            repository.restore(current.note)
                            undo = null
                        },
                    )
                }
              }
                TabBar(tab) {
                    focusManager.clearFocus()
                    tab = it
                }
            }
        }
    }
}
