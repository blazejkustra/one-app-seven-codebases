package com.mdnotes.kotlin.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

private val UndoColor = Color(0xFFA79FFF)

/** "Note deleted · Undo" toast shown above the tab bar. */
@Composable
fun DeleteToastBar(onUndo: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier
            .fillMaxWidth()
            .height(48.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(Tokens.ToastBg)
            .semantics(mergeDescendants = true) { liveRegion = LiveRegionMode.Polite }
            .testTag("toast")
            .padding(start = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Label("Note deleted", textStyle(15.sp, color = Color.White), Modifier.weight(1f))
        Box(
            Modifier
                .fillMaxHeight()
                .testTag("undo-button")
                .tap(onClick = onUndo)
                .padding(horizontal = 16.dp),
            contentAlignment = Alignment.Center,
        ) {
            Label("Undo", textStyle(15.sp, color = UndoColor, weight = FontWeight.SemiBold))
        }
    }
}
