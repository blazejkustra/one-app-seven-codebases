package com.mdnotes.kotlin.ui

import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.sp

/** The ★ / ☆ glyph used on cards and in the editor. */
@Composable
fun StarGlyph(filled: Boolean, size: Int, modifier: Modifier = Modifier) {
    BasicText(
        if (filled) "★" else "☆",
        modifier = modifier,
        style = textStyle(size.sp, color = if (filled) Tokens.Star else Tokens.TextTertiary),
    )
}
