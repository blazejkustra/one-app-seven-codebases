package com.mdnotes.lynx

import android.content.Context
import android.util.Log
import com.lynx.jsbridge.LynxMethod
import com.lynx.jsbridge.LynxModule
import com.lynx.react.bridge.ReadableArray
import com.lynx.react.bridge.ReadableMap
import org.json.JSONArray
import org.json.JSONObject

/**
 * `NativeModules.NotesStore` — the SQLite note store exposed to JS. All calls are
 * synchronous so every edit is committed before control returns to JS.
 */
class NotesStoreModule(context: Context, param: Any?) : LynxModule(context, param) {
    private val store = NotesDatabase.get((param as? Context) ?: context)

    /** JSON array of notes, or `null` JSON if the store was never seeded. */
    @LynxMethod
    fun loadNotes(): String = try {
        if (store.allSettings()["seeded"] != "1") "null"
        else JSONArray().apply {
            store.allNotes().forEach { n ->
                put(JSONObject().apply {
                    put("id", n.id)
                    put("body", n.body)
                    put("starred", n.starred)
                    put("updatedAt", n.updatedAt.toLong())
                })
            }
        }.toString()
    } catch (e: Exception) {
        Log.e(TAG, "loadNotes failed", e)
        "null"
    }

    @LynxMethod
    fun loadSettings(): String = try {
        JSONObject(store.allSettings() as Map<*, *>).toString()
    } catch (e: Exception) {
        "{}"
    }

    @LynxMethod
    fun upsertNote(note: ReadableMap): Boolean {
        val record = record(note) ?: return false
        return try {
            store.upsert(record); true
        } catch (e: Exception) {
            Log.e(TAG, "upsertNote failed", e); false
        }
    }

    @LynxMethod
    fun deleteNote(id: String): Boolean = try {
        store.delete(id); true
    } catch (e: Exception) {
        false
    }

    @LynxMethod
    fun replaceAllNotes(list: ReadableArray): Boolean = try {
        val records = (0 until list.size()).mapNotNull { i -> list.getMap(i)?.let(::record) }
        store.replaceAll(records)
        store.setSetting("seeded", "1")
        true
    } catch (e: Exception) {
        Log.e(TAG, "replaceAllNotes failed", e); false
    }

    @LynxMethod
    fun setSetting(key: String, value: String): Boolean = try {
        store.setSetting(key, value); true
    } catch (e: Exception) {
        false
    }

    private fun record(map: ReadableMap): NotesDatabase.NoteRecord? {
        if (!map.hasKey("id") || !map.hasKey("body")) return null
        val starred = map.hasKey("starred") && !map.isNull("starred") && map.getBoolean("starred")
        val updatedAt = if (map.hasKey("updatedAt") && !map.isNull("updatedAt")) map.getDouble("updatedAt")
        else System.currentTimeMillis().toDouble()
        return NotesDatabase.NoteRecord(map.getString("id"), map.getString("body"), starred, updatedAt)
    }

    companion object {
        private const val TAG = "NotesStore"
    }
}
