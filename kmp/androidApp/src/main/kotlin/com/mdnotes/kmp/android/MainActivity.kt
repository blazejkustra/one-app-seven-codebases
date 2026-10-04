package com.mdnotes.kmp.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import com.mdnotes.kmp.setMarkdownNotesContent

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setMarkdownNotesContent()
    }
}
