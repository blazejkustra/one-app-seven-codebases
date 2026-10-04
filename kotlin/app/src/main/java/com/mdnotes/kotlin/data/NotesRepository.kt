package com.mdnotes.kotlin.data

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import java.util.UUID

enum class SortOrder(val key: String) { UPDATED("updated"), TITLE("title") }

enum class Appearance(val key: String, val label: String) {
    SYSTEM("system", "System"), LIGHT("light", "Light"), DARK("dark", "Dark");

    fun next(): Appearance = entries[(ordinal + 1) % entries.size]
}

data class AppSettings(
    val sortOrder: SortOrder = SortOrder.UPDATED,
    val showSnippets: Boolean = true,
    val appearance: Appearance = Appearance.SYSTEM,
)

/**
 * Single source of truth for notes and settings. All writes go through one
 * serial, application-scoped dispatcher so they keep their order and are not
 * cancelled when a screen goes away.
 */
class NotesRepository(private val db: AppDatabase) {
    private val dao = db.noteDao()

    @OptIn(ExperimentalCoroutinesApi::class)
    private val writes = CoroutineScope(SupervisorJob() + Dispatchers.IO.limitedParallelism(1))

    val notes: Flow<List<NoteEntity>> = dao.observeAll()

    val settings: Flow<AppSettings> = dao.observeSettings().map { rows ->
        val map = rows.associate { it.key to it.value }
        AppSettings(
            sortOrder = if (map[KEY_SORT] == SortOrder.TITLE.key) SortOrder.TITLE else SortOrder.UPDATED,
            showSnippets = map[KEY_SNIPPETS]?.toBooleanStrictOrNull() ?: true,
            appearance = Appearance.entries.firstOrNull { it.key == map[KEY_APPEARANCE] } ?: Appearance.SYSTEM,
        )
    }

    /** Seeds sample notes on first launch and removes notes left blank by a killed editor. */
    fun initialize(): Job = writes.launch {
        if (dao.getSetting(KEY_SEEDED) == null) {
            dao.replaceAll(SeedNotes.all())
            dao.putSetting(SettingEntity(KEY_SEEDED, "true"))
        } else {
            dao.deleteBlank()
            migrateSeeds()
        }
        dao.putSetting(SettingEntity(KEY_SEED_VERSION, SeedNotes.VERSION.toString()))
    }

    /** Seed notes the user never edited are upgraded to the current seed bodies (v2 added tags, v3 checklists). */
    private suspend fun migrateSeeds() {
        val version = dao.getSetting(KEY_SEED_VERSION)?.toIntOrNull() ?: 1
        if (version >= SeedNotes.VERSION) return
        val legacy = SeedNotes.legacyBodies()
        for (seed in SeedNotes.all()) {
            val current = dao.get(seed.id) ?: continue
            if (current.body in legacy[seed.id].orEmpty()) dao.upsert(current.copy(body = seed.body))
        }
    }

    suspend fun get(id: String): NoteEntity? = dao.get(id)

    fun create(body: String): NoteEntity {
        val note = NoteEntity(UUID.randomUUID().toString(), body, starred = false, updatedAt = System.currentTimeMillis())
        writes.launch { dao.upsert(note) }
        return note
    }

    fun updateBody(id: String, body: String) {
        val now = System.currentTimeMillis()
        writes.launch { dao.updateBody(id, body, now) }
    }

    fun setStarred(id: String, starred: Boolean) {
        writes.launch { dao.updateStarred(id, starred) }
    }

    fun delete(id: String) {
        writes.launch { dao.delete(id) }
    }

    /** Deletes a note and yields exactly what was stored (for undo). Ordered after pending edits. */
    fun deleteForUndo(id: String): Deferred<NoteEntity?> = writes.async {
        dao.get(id)?.also { dao.delete(id) }
    }

    /** Puts a previously deleted note back unchanged (same id, body, star and updatedAt). */
    fun restore(snapshot: Deferred<NoteEntity?>) {
        writes.launch { snapshot.await()?.let { dao.upsert(it) } }
    }

    fun resetSamples() {
        writes.launch { dao.replaceAll(SeedNotes.all()) }
    }

    fun setSortOrder(order: SortOrder) {
        writes.launch { dao.putSetting(SettingEntity(KEY_SORT, order.key)) }
    }

    fun setAppearance(appearance: Appearance) {
        writes.launch { dao.putSetting(SettingEntity(KEY_APPEARANCE, appearance.key)) }
    }

    fun setShowSnippets(show: Boolean) {
        writes.launch { dao.putSetting(SettingEntity(KEY_SNIPPETS, show.toString())) }
    }

    private companion object {
        const val KEY_SEEDED = "seeded"
        const val KEY_SEED_VERSION = "seed_version"
        const val KEY_APPEARANCE = "appearance"
        const val KEY_SORT = "sort_order"
        const val KEY_SNIPPETS = "show_snippets"
    }
}
