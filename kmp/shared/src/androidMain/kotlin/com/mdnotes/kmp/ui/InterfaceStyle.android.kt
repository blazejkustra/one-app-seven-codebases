package com.mdnotes.kmp.ui

import android.content.res.Configuration
import androidx.core.view.WindowCompat
import com.mdnotes.kmp.data.Appearance

/** Status / navigation bar icons: dark on light theme, light on dark theme. */
actual fun applyInterfaceStyle(appearance: Appearance) {
    val activity = AndroidHost.activity ?: return
    val dark = when (appearance) {
        Appearance.Light -> false
        Appearance.Dark -> true
        Appearance.System -> (activity.resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
    }
    WindowCompat.getInsetsController(activity.window, activity.window.decorView).apply {
        isAppearanceLightStatusBars = !dark
        isAppearanceLightNavigationBars = !dark
    }
}
