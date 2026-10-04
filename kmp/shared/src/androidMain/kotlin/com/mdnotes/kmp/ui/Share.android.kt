package com.mdnotes.kmp.ui

import android.content.Intent

/** Opens Android's share sheet (ACTION_SEND chooser) with [text] as plain text. */
actual fun shareText(text: String) {
    val activity = AndroidHost.activity ?: return
    val send = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, text)
    }
    activity.startActivity(Intent.createChooser(send, null))
}
