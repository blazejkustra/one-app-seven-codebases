package com.mdnotes.lynx

import android.content.Context
import com.lynx.jsbridge.LynxMethod
import com.lynx.jsbridge.LynxModule

/**
 * `NativeModules.Appearance` — applies the in-app appearance override to the
 * system bars and returns the current *system* scheme ("light" | "dark").
 */
class AppearanceModule(context: Context, param: Any?) : LynxModule(context, param) {
    private val activity = param as MainActivity

    @LynxMethod
    fun setAppearance(mode: String): String {
        activity.runOnUiThread { activity.applyAppearance(mode) }
        return activity.systemScheme()
    }
}
