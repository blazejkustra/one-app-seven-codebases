package com.mdnotes.lynx

import android.app.Application
import android.graphics.Typeface
import com.lynx.service.log.LynxLogService
import com.lynx.tasm.LynxEnv
import com.lynx.tasm.behavior.shadow.text.TypefaceCache
import com.lynx.tasm.service.LynxServiceCenter

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Lynx must be initialised before any other Lynx API is used.
        LynxServiceCenter.inst().registerService(LynxLogService)
        LynxEnv.inst().init(this, null, null, null)
        // The UI uses `font-family: Menlo` (iOS). Android has no Menlo, so map the
        // name to the system monospace typeface for every style.
        for (style in intArrayOf(Typeface.NORMAL, Typeface.BOLD, Typeface.ITALIC, Typeface.BOLD_ITALIC)) {
            TypefaceCache.cacheTypeface("Menlo", style, Typeface.create(Typeface.MONOSPACE, style))
        }
    }
}
