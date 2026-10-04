package com.mdnotes.kmp

import android.content.Context
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import app.cash.sqldelight.driver.android.AndroidSqliteDriver
import com.mdnotes.kmp.data.NotesRepository
import com.mdnotes.kmp.db.NotesDatabase
import com.mdnotes.kmp.ui.App
import com.mdnotes.kmp.ui.AndroidHost

private var repository: NotesRepository? = null

private fun repository(context: Context): NotesRepository =
    repository ?: NotesRepository(
        AndroidSqliteDriver(NotesDatabase.Schema, context.applicationContext, "notes.db")
    ).also { repository = it }

/** Android counterpart of `MainViewController()`: hosts the shared Compose [App] in [this] activity. */
@OptIn(ExperimentalComposeUiApi::class)
fun ComponentActivity.setMarkdownNotesContent() {
    enableEdgeToEdge()
    AndroidHost.attach(this)
    val repo = repository(this)
    setContent {
        // Expose Modifier.testTag ids as Android resource-ids (the counterpart of iOS accessibilityIdentifier).
        Box(Modifier.semantics { testTagsAsResourceId = true }) { App(repo) }
    }
}
