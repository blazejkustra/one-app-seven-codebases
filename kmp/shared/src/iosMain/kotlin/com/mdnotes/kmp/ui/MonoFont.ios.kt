package com.mdnotes.kmp.ui

import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.platform.Typeface
import org.jetbrains.skia.FontMgr
import org.jetbrains.skia.FontStyle

actual val MonoFontFamily: FontFamily by lazy {
    val typeface = FontMgr.default.matchFamilyStyle("Menlo", FontStyle.NORMAL)
    if (typeface != null) FontFamily(Typeface(typeface)) else FontFamily.Monospace
}
