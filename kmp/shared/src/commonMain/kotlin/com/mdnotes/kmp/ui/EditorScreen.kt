package com.mdnotes.kmp.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsBottomHeight
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import com.mdnotes.kmp.data.NoteText
import com.mdnotes.kmp.markdown.MarkdownParser
import androidx.compose.runtime.withFrameNanos

@Composable
fun EditorScreen(
    noteId: String,
    initialBody: String,
    starred: Boolean,
    startInEdit: Boolean,
    onBodyChange: (String) -> Unit,
    onToggleStar: () -> Unit,
    onDelete: () -> Unit,
    onBack: (finalBody: String) -> Unit,
    modifier: Modifier = Modifier,
) {
    // Cursor starts at the end of the text.
    var field by remember(noteId) { mutableStateOf(TextFieldValue(initialBody, TextRange(initialBody.length))) }
    val body = field.text
    var editMode by rememberSaveable(noteId) { mutableStateOf(startInEdit) }
    val focusRequester = remember { FocusRequester() }
    val focusManager = LocalFocusManager.current

    LaunchedEffect(noteId) {
        if (startInEdit) {
            withFrameNanos { }
            focusRequester.requestFocus()
        }
    }

    // Android system back behaves like the `‹ Notes` button (instead of closing the app).
    PlatformBackHandler {
        focusManager.clearFocus()
        onBack(body)
    }

    Column(modifier.fillMaxSize().background(Tokens.bg)) {
        // Navigation row
        Row(Modifier.fillMaxWidth().height(44.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier
                    .fillMaxHeight()
                    .testTag("back-button")
                    .plainClickable {
                        focusManager.clearFocus()
                        onBack(body)
                    }
                    .padding(start = 16.dp, end = 12.dp),
                contentAlignment = Alignment.CenterStart,
            ) {
                BasicText("‹ Notes", style = textStyle(17f, color = Tokens.accent, lineHeight = 22f.spx()))
            }
            Spacer(Modifier.weight(1f))
            Box(
                Modifier
                    .fillMaxHeight()
                    .testTag("share-button")
                    .plainClickable {
                        focusManager.clearFocus()
                        shareText(field.text)
                    },
                contentAlignment = Alignment.Center,
            ) {
                BasicText("Share", style = textStyle(17f, color = Tokens.accent, lineHeight = 22f.spx()))
            }
            Spacer(Modifier.width(12.dp))
            Box(
                Modifier
                    .fillMaxHeight()
                    .testTag("delete-button")
                    .plainClickable {
                        focusManager.clearFocus()
                        onDelete()
                    },
                contentAlignment = Alignment.Center,
            ) {
                BasicText("Delete", style = textStyle(17f, color = Tokens.danger, lineHeight = 22f.spx()))
            }
            Spacer(Modifier.width(12.dp))
            Box(
                Modifier
                    .padding(end = 16.dp)
                    .size(44.dp)
                    .testTag("star-button")
                    .semantics {
                        selected = starred
                        stateDescription = if (starred) "starred" else "not starred"
                    }
                    .plainClickable(onClick = onToggleStar),
                contentAlignment = Alignment.Center,
            ) {
                BasicText(
                    if (starred) "★" else "☆",
                    style = textStyle(22f, color = if (starred) Tokens.star else Tokens.textTertiary, lineHeight = 26f.spx()),
                )
            }
        }
        Spacer(Modifier.height(4.dp))
        SegmentedControl(editMode) { edit ->
            if (!edit) focusManager.clearFocus()
            editMode = edit
        }
        Spacer(Modifier.height(12.dp))
        if (editMode) {
            BasicTextField(
                value = field,
                onValueChange = {
                    val changed = it.text != field.text
                    field = it
                    if (changed) onBodyChange(it.text)
                },
                textStyle = textStyle(15f, lineHeight = 22f.spx(), family = MonoFontFamily),
                cursorBrush = SolidColor(Tokens.accent),
                keyboardOptions = KeyboardOptions(
                    capitalization = KeyboardCapitalization.Sentences,
                    autoCorrectEnabled = false,
                ),
                modifier = Modifier
                    .weight(1f)
                    .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Bottom))
                    .padding(start = 16.dp, end = 16.dp, bottom = 16.dp)
                    .fillMaxSize()
                    .testTag("editor-input")
                    .focusRequester(focusRequester),
                decorationBox = { inner ->
                    Box(
                        Modifier
                            .fillMaxSize()
                            .clip(RoundedCornerShape(14.dp))
                            .background(Tokens.surface)
                            .padding(16.dp),
                    ) { inner() }
                },
            )
        } else {
            val blocks = remember(body) { MarkdownParser.parse(body) }
            Column(
                Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .testTag("preview-view")
                    // One accessibility element (label = rendered text) so the id is discoverable.
                    .semantics(mergeDescendants = true) {}
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp),
            ) {
                MarkdownBlocks(blocks) { task ->
                    val updated = NoteText.toggleTask(field.text, task.boxOffset)
                    if (updated != field.text) {
                        field = field.copy(text = updated)
                        onBodyChange(updated)
                    }
                }
                Spacer(Modifier.height(16.dp))
                Spacer(Modifier.windowInsetsBottomHeight(WindowInsets.safeDrawing))
            }
        }
    }
}
