package com.mdnotes.kotlin

import android.app.Application
import com.mdnotes.kotlin.data.AppDatabase
import com.mdnotes.kotlin.data.NotesRepository

class MarkdownNotesApp : Application() {
    val repository: NotesRepository by lazy { NotesRepository(AppDatabase.create(this)) }

    override fun onCreate() {
        super.onCreate()
        repository.initialize()
    }
}
