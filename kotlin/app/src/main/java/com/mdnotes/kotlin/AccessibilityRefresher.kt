package com.mdnotes.kotlin

import android.view.View
import android.view.ViewTreeObserver
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityManager

/**
 * Compose only emits semantics-change events when a "real" accessibility service is
 * enabled, so UI-automation clients (UiAutomator, test harnesses) that cache the node
 * tree can see a stale hierarchy after in-app navigation. While any accessibility client
 * is connected, this sends a throttled WINDOW_CONTENT_CHANGED event after the UI redraws
 * so those caches are invalidated.
 */
class AccessibilityRefresher private constructor(private val view: View) : ViewTreeObserver.OnDrawListener {
    private val manager = view.context.getSystemService(AccessibilityManager::class.java)
    private var scheduled = false

    private val dispatch = Runnable {
        scheduled = false
        val parent = view.parent ?: return@Runnable
        @Suppress("DEPRECATION") // the constructor replacing obtain() is API 30+
        val event = AccessibilityEvent.obtain(AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED).apply {
            contentChangeTypes = AccessibilityEvent.CONTENT_CHANGE_TYPE_SUBTREE
            setSource(view)
            packageName = view.context.packageName
        }
        parent.requestSendAccessibilityEvent(view, event)
    }

    override fun onDraw() {
        if (scheduled || manager?.isEnabled != true) return
        scheduled = true
        view.postDelayed(dispatch, THROTTLE_MS)
    }

    companion object {
        private const val THROTTLE_MS = 120L

        fun install(view: View) {
            view.viewTreeObserver.addOnDrawListener(AccessibilityRefresher(view))
        }
    }
}
