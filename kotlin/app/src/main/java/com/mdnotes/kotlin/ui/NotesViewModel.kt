package com.mdnotes.kotlin.ui

import android.app.Application
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.input.TextFieldValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.mdnotes.kotlin.MarkdownNotesApp
import com.mdnotes.kotlin.data.AppSettings
import com.mdnotes.kotlin.data.Appearance
import com.mdnotes.kotlin.data.NoteEntity
import com.mdnotes.kotlin.data.NoteText
import com.mdnotes.kotlin.data.SortOrder
import com.mdnotes.kotlin.markdown.MarkdownDocument
import com.mdnotes.kotlin.markdown.Task
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn

enum class Tab { NOTES, STARRED, SETTINGS }
enum class EditorMode { EDIT, PREVIEW }

/** A note prepared for display in a list. */
data class NoteItem(
    val id: String,
    val body: String,
    val starred: Boolean,
    val updatedAt: Long,
    val title: String,
    val snippet: String,
    val tags: List<String>,
    val tasksDone: Int,
    val tasksTotal: Int,
    val dateLabel: String,
)

private fun NoteEntity.toItem(): NoteItem {
    val tasks = MarkdownDocument.tasks(body)
    return NoteItem(
    id = id,
    body = body,
    starred = starred,
    updatedAt = updatedAt,
    title = NoteText.title(body),
    snippet = NoteText.snippet(body),
    tags = NoteText.tags(body),
    tasksDone = tasks.count { it.checked },
    tasksTotal = tasks.size,
    dateLabel = NoteText.dateLabel(updatedAt),
)
}

class EditorState(
    val noteId: String,
    body: String,
    starred: Boolean,
    mode: EditorMode,
    val focusOnOpen: Boolean,
) {
    var value by mutableStateOf(TextFieldValue(body, TextRange(body.length)))
    var starred by mutableStateOf(starred)
    var mode by mutableStateOf(mode)
}

/** The "Note deleted" toast; [key] distinguishes successive deletions. */
class DeleteToast(val key: Long, val snapshot: Deferred<NoteEntity?>)

class NotesViewModel(app: Application) : AndroidViewModel(app) {
    private val repo = (app as MarkdownNotesApp).repository

    /** `null` until the first database emission. */
    val notes: StateFlow<List<NoteItem>?> = repo.notes
        .map { list -> list.map { it.toItem() } }
        .stateIn(viewModelScope, SharingStarted.Eagerly, null)

    val settings: StateFlow<AppSettings?> = repo.settings
        .stateIn(viewModelScope, SharingStarted.Eagerly, null)

    var tab by mutableStateOf(Tab.NOTES)
    var query by mutableStateOf("")

    /** Selected tag filter on the Notes tab; `null` = All. Not persisted. */
    var selectedTag by mutableStateOf<String?>(null)
    var editor by mutableStateOf<EditorState?>(null)
        private set

    var toast by mutableStateOf<DeleteToast?>(null)
        private set
    private var toastCounter = 0L

    /** Deletes the open note, returns to the originating tab and offers undo. */
    fun deleteCurrent() {
        val state = editor ?: return
        val snapshot = repo.deleteForUndo(state.noteId)
        editor = null
        // A newer deletion replaces the toast; only the latest one can be undone.
        toast = DeleteToast(++toastCounter, snapshot)
    }

    fun undoDelete() {
        val current = toast ?: return
        toast = null
        repo.restore(current.snapshot)
    }

    fun dismissToast(key: Long) {
        if (toast?.key == key) toast = null
    }

    fun sorted(items: List<NoteItem>, order: SortOrder): List<NoteItem> = when (order) {
        SortOrder.UPDATED -> items.sortedByDescending { it.updatedAt }
        SortOrder.TITLE -> items.sortedWith(compareBy(String.CASE_INSENSITIVE_ORDER) { it.title })
    }

    fun open(note: NoteItem) {
        editor = EditorState(note.id, note.body, note.starred, EditorMode.PREVIEW, focusOnOpen = false)
    }

    fun createNote() {
        val note = repo.create(NEW_NOTE_BODY)
        editor = EditorState(note.id, note.body, note.starred, EditorMode.EDIT, focusOnOpen = true)
    }

    fun onEdit(value: TextFieldValue) {
        val state = editor ?: return
        val changed = value.text != state.value.text
        state.value = value
        if (changed) repo.updateBody(state.noteId, value.text)
    }

    /** Flips a checklist item from Preview; saved like any other edit (updatedAt = now). */
    fun toggleTask(task: Task) {
        val state = editor ?: return
        val text = MarkdownDocument.toggle(state.value.text, task)
        if (text != state.value.text) onEdit(state.value.copy(text = text))
    }

    fun toggleStar() {
        val state = editor ?: return
        state.starred = !state.starred
        repo.setStarred(state.noteId, state.starred)
    }

    fun closeEditor() {
        val state = editor ?: return
        if (state.value.text.isBlank()) repo.delete(state.noteId)
        editor = null
    }

    fun toggleSort() {
        val current = settings.value?.sortOrder ?: SortOrder.UPDATED
        repo.setSortOrder(if (current == SortOrder.UPDATED) SortOrder.TITLE else SortOrder.UPDATED)
    }

    fun setShowSnippets(show: Boolean) = repo.setShowSnippets(show)

    fun cycleAppearance() {
        repo.setAppearance((settings.value?.appearance ?: Appearance.SYSTEM).next())
    }

    fun resetSamples() = repo.resetSamples()

    private companion object {
        const val NEW_NOTE_BODY = "# New note\n\n"
    }
}
