package com.mdnotes.lynx

import android.app.Activity
import android.content.res.Configuration
import android.graphics.Color
import android.os.Bundle
import android.util.Log
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.lynx.react.bridge.JavaOnlyArray
import com.lynx.tasm.LynxView
import com.lynx.tasm.LynxViewBuilder
import com.lynx.xelement.XElementBehaviors

/** Hosts a single full-screen LynxView rendering the embedded `main.lynx.bundle`. */
class MainActivity : Activity() {
    private lateinit var lynxView: LynxView
    private var rendered = false
    private var safeTop = 0f
    private var safeBottom = 0f
    private var lastSentScheme = "light"
    private var appearance = "system"
    @Volatile var editorOpen = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        appearance = NotesDatabase.get(this).allSettings()["appearance"] ?: "system"
        lastSentScheme = systemScheme()
        applyAppearance(appearance)

        val builder = LynxViewBuilder()
        builder.setTemplateProvider(AssetTemplateProvider(this))
        builder.addBehaviors(XElementBehaviors().create())
        builder.registerModule("NotesStore", NotesStoreModule::class.java, applicationContext)
        builder.registerModule("Appearance", AppearanceModule::class.java, this)
        builder.registerModule("Share", ShareModule::class.java, this)
        builder.registerModule("BackHandler", BackHandlerModule::class.java, this)
        builder.setFontScale(1.0f)
        lynxView = builder.build(this)
        setContentView(lynxView)

        // Safe-area insets are only known once the view is attached; the UI reads them
        // from global props during the first render, so render after the first callback.
        ViewCompat.setOnApplyWindowInsetsListener(lynxView) { _, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
            val density = resources.displayMetrics.density
            val top = bars.top / density
            val bottom = bars.bottom / density
            if (!rendered || top != safeTop || bottom != safeBottom) {
                safeTop = top
                safeBottom = bottom
                lynxView.updateGlobalProps(globalProps())
            }
            if (!rendered) {
                rendered = true
                lynxView.renderTemplateUrl("main.lynx.bundle", "")
            }
            insets
        }
    }

    fun systemScheme(): String {
        val night = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        return if (night == Configuration.UI_MODE_NIGHT_YES) "dark" else "light"
    }

    /** Status/navigation bar icon colours and window background follow the effective scheme. */
    fun applyAppearance(mode: String) {
        appearance = mode
        val dark = when (mode) {
            "light" -> false
            "dark" -> true
            else -> systemScheme() == "dark"
        }
        window.decorView.setBackgroundColor(if (dark) Color.BLACK else Color.rgb(0xF5, 0xF5, 0xF7))
        WindowInsetsControllerCompat(window, window.decorView).apply {
            isAppearanceLightStatusBars = !dark
            isAppearanceLightNavigationBars = !dark
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        val scheme = systemScheme()
        applyAppearance(appearance)
        if (scheme != lastSentScheme) {
            lastSentScheme = scheme
            lynxView.updateGlobalProps(globalProps())
            lynxView.sendGlobalEvent("systemColorSchemeChanged", JavaOnlyArray.of(scheme))
        }
    }

    private fun globalProps(): Map<String, Any> = mapOf(
        "safeAreaTop" to safeTop.toDouble(),
        "safeAreaBottom" to safeBottom.toDouble(),
        "systemColorScheme" to systemScheme(),
        "appearance" to appearance,
        "platform" to "android",
    )

    @Deprecated("Activity back handling; fine for this single-activity host")
    override fun onBackPressed() {
        if (editorOpen) {
            lynxView.sendGlobalEvent("androidBackPressed", JavaOnlyArray())
        } else {
            @Suppress("DEPRECATION")
            super.onBackPressed()
        }
    }

    override fun onResume() {
        super.onResume()
        if (::lynxView.isInitialized) lynxView.onEnterForeground()
    }

    override fun onPause() {
        super.onPause()
        if (::lynxView.isInitialized) lynxView.onEnterBackground()
    }

    override fun onDestroy() {
        if (::lynxView.isInitialized) lynxView.destroy()
        super.onDestroy()
    }

    companion object {
        @Suppress("unused") private const val TAG = "MarkdownNotes"
    }
}
