package com.mdnotes.kmp.ui

import androidx.activity.ComponentActivity
import java.lang.ref.WeakReference

/** The activity currently hosting the Compose UI (needed by share sheet / system bar actuals). */
internal object AndroidHost {
    private var ref: WeakReference<ComponentActivity>? = null
    val activity: ComponentActivity? get() = ref?.get()
    fun attach(activity: ComponentActivity) { ref = WeakReference(activity) }
}
