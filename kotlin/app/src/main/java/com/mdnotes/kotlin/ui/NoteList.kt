package com.mdnotes.kotlin.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun NoteList(
    notes: List<NoteItem>,
    showSnippets: Boolean,
    emptyText: String,
    listState: LazyListState,
    onOpen: (NoteItem) -> Unit,
    modifier: Modifier = Modifier,
) {
    if (notes.isEmpty()) {
        Box(modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Label(emptyText, textStyle(17.sp, color = Tokens.TextTertiary), Modifier.testTag("empty-state"))
        }
        return
    }
    LazyColumn(
        modifier.fillMaxSize(),
        state = listState,
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 12.dp, bottom = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        items(notes, key = { it.id }) { note ->
            NoteCard(note, showSnippets) { onOpen(note) }
        }
    }
}

@Composable
fun NoteCard(note: NoteItem, showSnippet: Boolean, onClick: () -> Unit) {
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(Tokens.Surface)
            .testTag("note-card")
            .tap(onClick = onClick)
            .padding(16.dp),
    ) {
        Label(note.title, textStyle(17.sp, weight = FontWeight.SemiBold, lineHeight = 22.sp), maxLines = 1)
        if (showSnippet && note.snippet.isNotEmpty()) {
            VSpace(4)
            Label(note.snippet, textStyle(15.sp, color = Tokens.TextSecondary, lineHeight = 20.sp), maxLines = 2)
        }
        if (note.tags.isNotEmpty()) {
            VSpace(8)
            CardTags(note.tags)
        }
        VSpace(8)
        // Fixed-height footer so the star glyph never changes the card height.
        Row(Modifier.fillMaxWidth().height(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Label(note.dateLabel, textStyle(13.sp, color = Tokens.TextTertiary, lineHeight = 16.sp))
            if (note.tasksTotal > 0) {
                HSpace(12)
                Label(
                    "${note.tasksDone}/${note.tasksTotal} done",
                    textStyle(13.sp, color = Tokens.TextSecondary, lineHeight = 16.sp),
                )
            }
            Spacer(Modifier.weight(1f))
            if (note.starred) StarGlyph(filled = true, size = 16, modifier = Modifier.wrapContentHeight(unbounded = true))
        }
    }
}
