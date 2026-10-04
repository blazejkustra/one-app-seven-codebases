package com.mdnotes.kmp

import androidx.compose.ui.uikit.OnFocusBehavior
import androidx.compose.ui.window.ComposeUIViewController
import app.cash.sqldelight.driver.native.NativeSqliteDriver
import com.mdnotes.kmp.data.NotesRepository
import com.mdnotes.kmp.db.NotesDatabase
import com.mdnotes.kmp.ui.App

private val repository by lazy {
    NotesRepository(NativeSqliteDriver(NotesDatabase.Schema, "notes.db"))
}

fun MainViewController() = ComposeUIViewController(
    configure = {
        // The editor handles the keyboard itself via ime insets.
        onFocusBehavior = OnFocusBehavior.DoNothing
    }
) { App(repository) }
