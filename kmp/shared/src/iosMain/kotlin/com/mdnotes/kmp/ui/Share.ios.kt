package com.mdnotes.kmp.ui

import platform.UIKit.UIActivityViewController
import platform.UIKit.UIApplication
import platform.UIKit.UIViewController
import platform.UIKit.UIWindow
import platform.UIKit.UIWindowScene

/** Presents the native share sheet (UIActivityViewController) with [text] as plain text. */
actual fun shareText(text: String) {
    val window = UIApplication.sharedApplication.connectedScenes
        .mapNotNull { it as? UIWindowScene }
        .flatMap { scene -> scene.windows.mapNotNull { it as? UIWindow } }
        .firstOrNull { it.isKeyWindow() } ?: return
    var top: UIViewController = window.rootViewController ?: return
    while (true) top = top.presentedViewController ?: break
    val sheet = UIActivityViewController(activityItems = listOf(text), applicationActivities = null)
    top.presentViewController(sheet, animated = true, completion = null)
}
