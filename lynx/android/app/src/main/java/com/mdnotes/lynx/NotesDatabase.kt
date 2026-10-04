package com.mdnotes.lynx

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import androidx.sqlite.db.SupportSQLiteDatabase
import androidx.sqlite.db.SupportSQLiteOpenHelper
import androidx.sqlite.db.framework.FrameworkSQLiteOpenHelperFactory

/** SQLite-backed storage for notes and settings (androidx.sqlite), same schema as iOS. */
class NotesDatabase private constructor(context: Context) {
    data class NoteRecord(val id: String, val body: String, val starred: Boolean, val updatedAt: Double)

    private val helper: SupportSQLiteOpenHelper = FrameworkSQLiteOpenHelperFactory().create(
        SupportSQLiteOpenHelper.Configuration.builder(context)
            .name("notes.sqlite3")
            .callback(object : SupportSQLiteOpenHelper.Callback(1) {
                override fun onCreate(db: SupportSQLiteDatabase) {
                    db.execSQL(
                        "CREATE TABLE IF NOT EXISTS notes (id TEXT PRIMARY KEY NOT NULL, body TEXT NOT NULL, " +
                            "starred INTEGER NOT NULL DEFAULT 0, updated_at REAL NOT NULL)"
                    )
                    db.execSQL("CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY NOT NULL, value TEXT NOT NULL)")
                }

                override fun onUpgrade(db: SupportSQLiteDatabase, oldVersion: Int, newVersion: Int) {}
            })
            .build()
    )

    private val db: SupportSQLiteDatabase get() = helper.writableDatabase

    @Synchronized
    fun allNotes(): List<NoteRecord> {
        val out = ArrayList<NoteRecord>()
        db.query("SELECT id, body, starred, updated_at FROM notes").use { c ->
            while (c.moveToNext()) {
                out.add(NoteRecord(c.getString(0), c.getString(1), c.getInt(2) != 0, c.getDouble(3)))
            }
        }
        return out
    }

    @Synchronized
    fun upsert(note: NoteRecord) = upsertInto(db, note)

    private fun upsertInto(target: SupportSQLiteDatabase, note: NoteRecord) {
        val values = ContentValues().apply {
            put("id", note.id)
            put("body", note.body)
            put("starred", if (note.starred) 1 else 0)
            put("updated_at", note.updatedAt)
        }
        target.insert("notes", SQLiteDatabase.CONFLICT_REPLACE, values)
    }

    @Synchronized
    fun delete(id: String) {
        db.delete("notes", "id = ?", arrayOf(id))
    }

    @Synchronized
    fun replaceAll(records: List<NoteRecord>) {
        val d = db
        d.beginTransaction()
        try {
            d.delete("notes", null, null)
            records.forEach { upsertInto(d, it) }
            d.setTransactionSuccessful()
        } finally {
            d.endTransaction()
        }
    }

    @Synchronized
    fun allSettings(): Map<String, String> {
        val out = HashMap<String, String>()
        db.query("SELECT key, value FROM settings").use { c ->
            while (c.moveToNext()) out[c.getString(0)] = c.getString(1)
        }
        return out
    }

    @Synchronized
    fun setSetting(key: String, value: String) {
        val values = ContentValues().apply {
            put("key", key)
            put("value", value)
        }
        db.insert("settings", SQLiteDatabase.CONFLICT_REPLACE, values)
    }

    companion object {
        @Volatile private var instance: NotesDatabase? = null

        fun get(context: Context): NotesDatabase =
            instance ?: synchronized(this) {
                instance ?: NotesDatabase(context.applicationContext).also { instance = it }
            }
    }
}
