package com.mdnotes.lynx

import android.content.Context
import com.lynx.jsbridge.LynxMethod
import com.lynx.jsbridge.LynxModule

/**
 * `NativeModules.BackHandler` (Android only) — the UI reports whether the editor
 * is open so system Back closes the editor instead of leaving the app.
 */
class BackHandlerModule(context: Context, param: Any?) : LynxModule(context, param) {
    private val activity = param as MainActivity

    @LynxMethod
    fun setEditorOpen(open: Boolean) {
        activity.editorOpen = open
    }
}
