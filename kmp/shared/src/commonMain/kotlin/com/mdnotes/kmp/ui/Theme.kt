package com.mdnotes.kmp.ui

import androidx.compose.ui.graphics.Color
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.LineHeightStyle
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.sp

/**
 * Design tokens (spec §1, dark values from iteration 5). Backed by snapshot state, so every
 * composable / draw block that reads a token is invalidated when the theme flips.
 */
object Tokens {
    var dark by mutableStateOf(false)

    private fun pick(light: Long, darkValue: Long) = Color(if (dark) darkValue else light)

    val bg get() = pick(0xFFF5F5F7, 0xFF000000)
    val surface get() = pick(0xFFFFFFFF, 0xFF1C1C1E)
    val text get() = pick(0xFF1C1C1E, 0xFFF5F5F7)
    val textSecondary get() = pick(0xFF6E6E73, 0xFFA1A1A6)
    val textTertiary get() = pick(0xFF8E8E93, 0xFF8E8E93)
    val fill get() = pick(0xFFE9E9EE, 0xFF2C2C2E)
    val separator get() = pick(0xFFE5E5EA, 0xFF38383A)
    val accent get() = pick(0xFF5B4FE9, 0xFF7D74FF)
    val accentSoft get() = pick(0xFFECEBFF, 0xFF2A2650)
    val star get() = pick(0xFFF5A623, 0xFFFFB340)
    val danger get() = pick(0xFFE5484D, 0xFFFF6369)
    val codeBg get() = pick(0xFF1C1C1E, 0xFF2C2C2E)
    val codeText get() = pick(0xFFF5F5F7, 0xFFF5F5F7)
    val toastBg get() = pick(0xFF1C1C1E, 0xFF3A3A3C)
    /** Content drawn on `accent` (plus sign, selected chip, switch knob, checkmark). */
    val onAccent get() = Color.White
}

/** Applies the appearance to the native window (status bar, keyboard, system chrome). */
expect fun applyInterfaceStyle(appearance: com.mdnotes.kmp.data.Appearance)

/** Opens the platform share sheet with plain text. */
expect fun shareText(text: String)

/** Menlo, resolved from the system font manager on iOS. */
expect val MonoFontFamily: FontFamily

private val centered = LineHeightStyle(LineHeightStyle.Alignment.Center, LineHeightStyle.Trim.None)

fun textStyle(
    size: Float,
    color: Color = Tokens.text,
    weight: FontWeight = FontWeight.Normal,
    lineHeight: TextUnit = TextUnit.Unspecified,
    family: FontFamily = FontFamily.Default,
    italic: Boolean = false,
): TextStyle = TextStyle(
    fontSize = size.sp,
    color = color,
    fontWeight = weight,
    fontFamily = family,
    fontStyle = if (italic) FontStyle.Italic else FontStyle.Normal,
    lineHeight = if (lineHeight == TextUnit.Unspecified) (size * 1.2f).sp else lineHeight,
    lineHeightStyle = centered,
)

/** System back (Android back button / gesture). No-op on iOS, which has no system back. */
@androidx.compose.runtime.Composable
expect fun PlatformBackHandler(onBack: () -> Unit)
