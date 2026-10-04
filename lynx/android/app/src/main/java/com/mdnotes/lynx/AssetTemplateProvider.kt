package com.mdnotes.lynx

import android.content.Context
import com.lynx.tasm.provider.AbsTemplateProvider
import java.io.IOException

/** Loads Lynx bundles embedded in the APK's assets (no dev server). */
class AssetTemplateProvider(context: Context) : AbsTemplateProvider() {
    private val appContext = context.applicationContext

    override fun loadTemplate(uri: String, callback: Callback) {
        Thread {
            try {
                callback.onSuccess(appContext.assets.open(uri).use { it.readBytes() })
            } catch (e: IOException) {
                callback.onFailed(e.message ?: "Bundle $uri not found")
            }
        }.start()
    }
}
