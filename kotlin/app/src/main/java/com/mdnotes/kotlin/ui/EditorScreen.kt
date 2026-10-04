package com.mdnotes.kotlin.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.ime
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.union
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalContext
import android.content.Context
import android.content.Intent
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mdnotes.kotlin.markdown.MarkdownView
import kotlinx.coroutines.android.awaitFrame

/** Opens the Android share sheet with the note's raw markdown as plain text. */
private fun shareText(context: Context, body: String) {
    val send = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, body)
    }
    context.startActivity(Intent.createChooser(send, null))
}

@Composable
fun EditorScreen(
    state: EditorState,
    onBack: () -> Unit,
    onToggleStar: () -> Unit,
    onDelete: () -> Unit,
    onToggleTask: (com.mdnotes.kotlin.markdown.Task) -> Unit,
    onEdit: (androidx.compose.ui.text.input.TextFieldValue) -> Unit,
) {
    val focusManager = LocalFocusManager.current
    val keyboard = LocalSoftwareKeyboardController.current
    Column(Modifier.fillMaxSize()) {
        // Navigation row (44)
        Row(Modifier.fillMaxWidth().height(44.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier
                    .fillMaxHeight()
                    .testTag("back-button")
                    .tap(onClick = onBack)
                    .padding(start = 16.dp, end = 12.dp),
                contentAlignment = Alignment.CenterStart,
            ) {
                Label("‹ Notes", textStyle(17.sp, color = Tokens.Accent))
            }
            Spacer(Modifier.weight(1f))
            val context = LocalContext.current
            Box(
                Modifier
                    .fillMaxHeight()
                    .testTag("share-button")
                    .tap { shareText(context, state.value.text) },
                contentAlignment = Alignment.Center,
            ) {
                Label("Share", textStyle(17.sp, color = Tokens.Accent))
            }
            Spacer(Modifier.width(12.dp))
            Box(
                Modifier
                    .fillMaxHeight()
                    .testTag("delete-button")
                    .tap(onClick = onDelete),
                contentAlignment = Alignment.Center,
            ) {
                Label("Delete", textStyle(17.sp, color = Tokens.Danger))
            }
            Spacer(Modifier.width(12.dp))
            Box(
                Modifier
                    .padding(end = 16.dp)
                    .size(44.dp)
                    .semantics {
                        contentDescription = if (state.starred) "★" else "☆"
                        stateDescription = if (state.starred) "starred" else "not starred"
                    }
                    .testTag("star-button")
                    .tap(onClick = onToggleStar),
                contentAlignment = Alignment.Center,
            ) {
                StarGlyph(filled = state.starred, size = 22)
            }
        }
        SegmentedControl(
            mode = state.mode,
            onSelect = { mode ->
                if (mode == EditorMode.PREVIEW) {
                    focusManager.clearFocus()
                    keyboard?.hide()
                }
                state.mode = mode
            },
            modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 4.dp),
        )
        Spacer(Modifier.height(12.dp))
        when (state.mode) {
            EditorMode.EDIT -> EditPane(state, onEdit, Modifier.weight(1f))
            EditorMode.PREVIEW -> Column(
                Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .testTag("preview-view")
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp)
                    .windowInsetsPadding(WindowInsets.navigationBars)
                    .padding(bottom = 16.dp),
            ) {
                MarkdownView(state.value.text, onToggleTask = onToggleTask)
            }
        }
    }
}

@Composable
private fun EditPane(
    state: EditorState,
    onEdit: (androidx.compose.ui.text.input.TextFieldValue) -> Unit,
    modifier: Modifier,
) {
    val focusRequester = remember { FocusRequester() }
    val keyboard = LocalSoftwareKeyboardController.current
    Box(
        modifier
            .fillMaxWidth()
            .windowInsetsPadding(WindowInsets.navigationBars.union(WindowInsets.ime))
            .padding(start = 16.dp, end = 16.dp, bottom = 16.dp)
            .clip(RoundedCornerShape(14.dp))
            .background(Tokens.Surface),
    ) {
        BasicTextField(
            value = state.value,
            onValueChange = onEdit,
            textStyle = textStyle(15.sp, lineHeight = 22.sp, family = Tokens.Mono),
            cursorBrush = SolidColor(Tokens.Accent),
            modifier = Modifier
                .fillMaxSize()
                .focusRequester(focusRequester)
                .testTag("editor-input")
                .padding(16.dp),
        )
    }
    LaunchedEffect(state.noteId) {
        if (state.focusOnOpen) {
            awaitFrame()
            focusRequester.requestFocus()
            keyboard?.show()
        }
    }
}
