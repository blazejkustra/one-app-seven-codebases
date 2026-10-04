# Room and Compose ship their own consumer rules.
# org.jetbrains:markdown uses no reflection; keep element types for safety.
-keep class org.intellij.markdown.** { *; }
