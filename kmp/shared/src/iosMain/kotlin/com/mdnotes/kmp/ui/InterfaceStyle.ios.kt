package com.mdnotes.kmp.ui

import com.mdnotes.kmp.data.Appearance
import platform.UIKit.UIApplication
import platform.UIKit.UIUserInterfaceStyle
import platform.UIKit.UIWindow
import platform.UIKit.UIWindowScene

actual fun applyInterfaceStyle(appearance: Appearance) {
    val style = when (appearance) {
        Appearance.System -> UIUserInterfaceStyle.UIUserInterfaceStyleUnspecified
        Appearance.Light -> UIUserInterfaceStyle.UIUserInterfaceStyleLight
        Appearance.Dark -> UIUserInterfaceStyle.UIUserInterfaceStyleDark
    }
    UIApplication.sharedApplication.connectedScenes.forEach { scene ->
        (scene as? UIWindowScene)?.windows?.forEach { window ->
            (window as? UIWindow)?.overrideUserInterfaceStyle = style
        }
    }
}
