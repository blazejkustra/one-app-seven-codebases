package com.mdnotes.lynx

import android.app.Activity
import android.content.Context
import android.content.Intent
import com.lynx.jsbridge.LynxMethod
import com.lynx.jsbridge.LynxModule

/** `NativeModules.Share` — opens the Android share sheet with plain text. */
class ShareModule(context: Context, param: Any?) : LynxModule(context, param) {
    private val activity = param as Activity

    @LynxMethod
    fun shareText(text: String) {
        activity.runOnUiThread {
            val send = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
            }
            activity.startActivity(Intent.createChooser(send, null))
        }
    }
}
