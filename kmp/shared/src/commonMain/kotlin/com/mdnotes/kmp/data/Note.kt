package com.mdnotes.kmp.data

data class Note(
    val id: String,
    val body: String,
    val starred: Boolean,
    /** Epoch milliseconds. */
    val updatedAt: Long,
) {
    /** Lower-cased, de-duplicated tags (title line excluded). */
    val tags: List<String> by lazy { Tags.extract(body) }
}

enum class SortOrder { Updated, Title }

/** Appearance setting; tapping cycles System → Light → Dark → System. */
enum class Appearance(val label: String) {
    System("System"), Light("Light"), Dark("Dark");

    fun next(): Appearance = entries[(ordinal + 1) % entries.size]
}

data class Settings(
    val sortOrder: SortOrder = SortOrder.Updated,
    val showSnippets: Boolean = true,
    val appearance: Appearance = Appearance.System,
)
