package com.mdnotes.kotlin.ui

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.runtime.Composable
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.LocalActivity
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.ui.graphics.toArgb
import com.mdnotes.kotlin.data.Appearance
import androidx.compose.ui.Alignment
import androidx.compose.foundation.layout.padding
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.lifecycle.compose.collectAsStateWithLifecycle

@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun AppRoot(vm: NotesViewModel) {
    val notes by vm.notes.collectAsStateWithLifecycle()
    val settings by vm.settings.collectAsStateWithLifecycle()
    val systemDark = isSystemInDarkTheme()
    val dark = when (settings?.appearance) {
        Appearance.LIGHT -> false
        Appearance.DARK -> true
        else -> systemDark
    }
    // Apply before children read any token in this composition.
    Tokens.palette = if (dark) DarkPalette else LightPalette
    val activity = LocalActivity.current as? ComponentActivity
    LaunchedEffect(dark, activity) {
        // Status/navigation bar icons: light on dark, dark on light.
        val style = if (dark) {
            SystemBarStyle.dark(android.graphics.Color.TRANSPARENT)
        } else {
            SystemBarStyle.light(android.graphics.Color.TRANSPARENT, android.graphics.Color.TRANSPARENT)
        }
        activity?.enableEdgeToEdge(statusBarStyle = style, navigationBarStyle = style)
        activity?.window?.setBackgroundDrawable(android.graphics.drawable.ColorDrawable(Tokens.Bg.toArgb()))
    }
    val notesListState = rememberLazyListState()
    val starredListState = rememberLazyListState()

    Box(
        Modifier
            .fillMaxSize()
            .background(Tokens.Bg)
            .semantics { testTagsAsResourceId = true }
            .windowInsetsPadding(WindowInsets.statusBars),
    ) {
        val loadedNotes = notes
        val loadedSettings = settings
        if (loadedNotes == null || loadedSettings == null) return@Box

        val editor = vm.editor
        if (editor != null) {
            BackHandler { vm.closeEditor() }
            EditorScreen(
                state = editor,
                onBack = vm::closeEditor,
                onToggleStar = vm::toggleStar,
                onDelete = vm::deleteCurrent,
                onToggleTask = vm::toggleTask,
                onEdit = vm::onEdit,
            )
            return@Box
        }

        val sorted = vm.sorted(loadedNotes, loadedSettings.sortOrder)
        // A note that moves to the top (new or just edited) should be visible, not hidden above the fold.
        val topId = sorted.firstOrNull()?.id
        LaunchedEffect(topId) {
            if (notesListState.firstVisibleItemIndex <= 1) notesListState.scrollToItem(0)
            if (starredListState.firstVisibleItemIndex <= 1) starredListState.scrollToItem(0)
        }
        Column(Modifier.fillMaxSize()) {
            Box(Modifier.weight(1f)) {
                when (vm.tab) {
                    Tab.NOTES -> NotesScreen(
                        notes = sorted,
                        settings = loadedSettings,
                        query = vm.query,
                        onQuery = { vm.query = it },
                        selectedTag = vm.selectedTag,
                        onSelectTag = { vm.selectedTag = it },
                        listState = notesListState,
                        onAdd = vm::createNote,
                        onOpen = vm::open,
                    )
                    Tab.STARRED -> StarredScreen(sorted, loadedSettings, starredListState, vm::open)
                    Tab.SETTINGS -> SettingsScreen(
                        settings = loadedSettings,
                        noteCount = loadedNotes.size,
                        onToggleSort = vm::toggleSort,
                        onShowSnippets = vm::setShowSnippets,
                        onCycleAppearance = vm::cycleAppearance,
                        onReset = vm::resetSamples,
                    )
                }
                vm.toast?.let { toast ->
                    LaunchedEffect(toast.key) {
                        delay(4_000)
                        vm.dismissToast(toast.key)
                    }
                    DeleteToastBar(
                        onUndo = vm::undoDelete,
                        modifier = Modifier.align(Alignment.BottomCenter).padding(start = 16.dp, end = 16.dp, bottom = 12.dp),
                    )
                }
            }
            TabBar(vm.tab) { vm.tab = it }
        }
    }
}
