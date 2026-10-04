package com.mdnotes.kmp.data

import app.cash.sqldelight.db.SqlDriver
import com.mdnotes.kmp.db.NotesDatabase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlin.random.Random
import kotlin.time.Clock

/**
 * SQLite-backed store for notes and settings. All writes are synchronous so that
 * nothing is lost if the app is killed right after an edit.
 */
class NotesRepository(driver: SqlDriver) {
    private val db = NotesDatabase(driver)
    private val q = db.notesQueries

    private val _notes = MutableStateFlow<List<Note>>(emptyList())
    val notes: StateFlow<List<Note>> = _notes.asStateFlow()

    private val _settings = MutableStateFlow(Settings())
    val settings: StateFlow<Settings> = _settings.asStateFlow()

    init {
        if (q.selectSetting(KEY_SEEDED).executeAsOneOrNull() == null) {
            db.transaction {
                SeedNotes.create().forEach { insert(it) }
                q.putSetting(KEY_SEEDED, "1")
                q.putSetting(KEY_SEED_VERSION, SeedNotes.VERSION.toString())
            }
        }
        upgradeSeeds()
        _settings.value = Settings(
            sortOrder = if (q.selectSetting(KEY_SORT).executeAsOneOrNull() == "title") SortOrder.Title else SortOrder.Updated,
            showSnippets = q.selectSetting(KEY_SNIPPETS).executeAsOneOrNull() != "0",
            appearance = Appearance.entries.firstOrNull {
                it.name == q.selectSetting(KEY_APPEARANCE).executeAsOneOrNull()
            } ?: Appearance.System,
        )
        reload()
        // A note left empty when the app was killed inside the editor is discarded, like on "back".
        _notes.value.filter { it.body.isBlank() }.forEach { q.deleteById(it.id) }
        reload()
    }

    /** Seeds still exactly as shipped by an older version get the current seed body; edited notes are left alone. */
    private fun upgradeSeeds() {
        val version = q.selectSetting(KEY_SEED_VERSION).executeAsOneOrNull()?.toIntOrNull() ?: 1
        if (version >= SeedNotes.VERSION) return
        val legacy = SeedNotes.legacyBodies()
        db.transaction {
            SeedNotes.create().forEach { seed ->
                val old = legacy[seed.id] ?: return@forEach
                val current = q.selectById(seed.id).executeAsOneOrNull() ?: return@forEach
                if (current.body in old) {
                    q.upsert(current.id, seed.body, current.starred, current.updated_at)
                }
            }
            q.putSetting(KEY_SEED_VERSION, SeedNotes.VERSION.toString())
        }
    }

    private fun insert(n: Note) = q.upsert(n.id, n.body, if (n.starred) 1L else 0L, n.updatedAt)

    private fun reload() {
        _notes.value = q.selectAll { id, body, starred, updatedAt ->
            Note(id, body, starred != 0L, updatedAt)
        }.executeAsList()
    }

    fun get(id: String): Note? = _notes.value.firstOrNull { it.id == id }

    fun createNote(): Note {
        val note = Note(
            id = "note-" + Clock.System.now().toEpochMilliseconds().toString(36) + "-" + Random.nextInt(0, Int.MAX_VALUE).toString(36),
            body = "# New note\n\n",
            starred = false,
            updatedAt = Clock.System.now().toEpochMilliseconds(),
        )
        insert(note)
        reload()
        return note
    }

    fun updateBody(id: String, body: String) {
        q.updateBody(body, Clock.System.now().toEpochMilliseconds(), id)
        reload()
    }

    fun setStarred(id: String, starred: Boolean) {
        q.updateStarred(if (starred) 1L else 0L, id)
        reload()
    }

    /** Deletes a note and returns it as it was, so it can be restored exactly. */
    fun delete(id: String): Note? {
        val note = get(id)
        q.deleteById(id)
        reload()
        return note
    }

    /** Re-inserts a deleted note unchanged (id, body, star, updatedAt). */
    fun restore(note: Note) {
        insert(note)
        reload()
    }

    fun resetSampleNotes() {
        db.transaction {
            q.deleteAll()
            SeedNotes.create().forEach { insert(it) }
        }
        reload()
    }

    fun setSortOrder(order: SortOrder) {
        q.putSetting(KEY_SORT, if (order == SortOrder.Title) "title" else "updated")
        _settings.value = _settings.value.copy(sortOrder = order)
    }

    fun setAppearance(appearance: Appearance) {
        q.putSetting(KEY_APPEARANCE, appearance.name)
        _settings.value = _settings.value.copy(appearance = appearance)
    }

    fun setShowSnippets(show: Boolean) {
        q.putSetting(KEY_SNIPPETS, if (show) "1" else "0")
        _settings.value = _settings.value.copy(showSnippets = show)
    }

    private companion object {
        const val KEY_SEEDED = "seeded"
        const val KEY_SEED_VERSION = "seedVersion"
        const val KEY_SORT = "sortOrder"
        const val KEY_SNIPPETS = "showSnippets"
        const val KEY_APPEARANCE = "appearance"
    }
}
