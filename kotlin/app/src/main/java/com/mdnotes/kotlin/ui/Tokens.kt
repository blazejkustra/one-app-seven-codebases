package com.mdnotes.kotlin.ui

import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.sp

/** One full set of colour tokens (spec §1 and iteration 5). */
data class Palette(
    val bg: Color,
    val surface: Color,
    val text: Color,
    val textSecondary: Color,
    val textTertiary: Color,
    val fill: Color,
    val separator: Color,
    val accent: Color,
    val accentSoft: Color,
    val star: Color,
    val danger: Color,
    val codeBg: Color,
    val codeText: Color,
    val toastBg: Color,
    val isDark: Boolean,
)

val LightPalette = Palette(
    bg = Color(0xFFF5F5F7), surface = Color(0xFFFFFFFF), text = Color(0xFF1C1C1E),
    textSecondary = Color(0xFF6E6E73), textTertiary = Color(0xFF8E8E93), fill = Color(0xFFE9E9EE),
    separator = Color(0xFFE5E5EA), accent = Color(0xFF5B4FE9), accentSoft = Color(0xFFECEBFF),
    star = Color(0xFFF5A623), danger = Color(0xFFE5484D), codeBg = Color(0xFF1C1C1E),
    codeText = Color(0xFFF5F5F7), toastBg = Color(0xFF1C1C1E), isDark = false,
)

val DarkPalette = Palette(
    bg = Color(0xFF000000), surface = Color(0xFF1C1C1E), text = Color(0xFFF5F5F7),
    textSecondary = Color(0xFFA1A1A6), textTertiary = Color(0xFF8E8E93), fill = Color(0xFF2C2C2E),
    separator = Color(0xFF38383A), accent = Color(0xFF7D74FF), accentSoft = Color(0xFF2A2650),
    star = Color(0xFFFFB340), danger = Color(0xFFFF6369), codeBg = Color(0xFF2C2C2E),
    codeText = Color(0xFFF5F5F7), toastBg = Color(0xFF3A3A3C), isDark = true,
)

/**
 * Design tokens. The active [palette] is snapshot state, so any composition that reads a
 * token recomposes when the theme switches (System / Light / Dark).
 */
object Tokens {
    var palette by mutableStateOf(LightPalette)

    val Bg get() = palette.bg
    val Surface get() = palette.surface
    val Text get() = palette.text
    val TextSecondary get() = palette.textSecondary
    val TextTertiary get() = palette.textTertiary
    val Fill get() = palette.fill
    val Separator get() = palette.separator
    val Accent get() = palette.accent
    val AccentSoft get() = palette.accentSoft
    val Star get() = palette.star
    val Danger get() = palette.danger
    val CodeBg get() = palette.codeBg
    val CodeText get() = palette.codeText
    val ToastBg get() = palette.toastBg

    /** Android has no SF Pro / Menlo; the system sans (Roboto) and monospace stand in. */
    val Sans: FontFamily = FontFamily.Default
    val Mono: FontFamily = FontFamily.Monospace
}

fun textStyle(
    size: TextUnit,
    color: Color = Tokens.Text,
    weight: FontWeight = FontWeight.Normal,
    lineHeight: TextUnit = TextUnit.Unspecified,
    family: FontFamily = Tokens.Sans,
    italic: Boolean = false,
    align: TextAlign = TextAlign.Unspecified,
) = TextStyle(
    fontSize = size,
    color = color,
    fontWeight = weight,
    lineHeight = lineHeight,
    fontFamily = family,
    fontStyle = if (italic) FontStyle.Italic else FontStyle.Normal,
    textAlign = align,
)

@Composable
fun Label(
    text: String,
    style: TextStyle,
    modifier: Modifier = Modifier,
    maxLines: Int = Int.MAX_VALUE,
) {
    BasicText(
        text = text,
        modifier = modifier,
        style = style,
        maxLines = maxLines,
        overflow = if (maxLines == Int.MAX_VALUE) TextOverflow.Clip else TextOverflow.Ellipsis,
    )
}

