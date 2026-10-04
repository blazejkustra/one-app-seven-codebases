package com.mdnotes.kotlin.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Single-line row of `#tag` chips on a note card; overflow is clipped. */
@Composable
fun CardTags(tags: List<String>) {
    Box(Modifier.fillMaxWidth().height(22.dp).clipToBounds()) {
        Row(
            Modifier.wrapContentWidth(Alignment.Start, unbounded = true),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            tags.forEach { tag ->
                Box(
                    Modifier
                        .height(22.dp)
                        .clip(RoundedCornerShape(11.dp))
                        .background(Tokens.AccentSoft)
                        .padding(horizontal = 8.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Label("#$tag", textStyle(12.sp, color = Tokens.Accent, weight = FontWeight.Medium), maxLines = 1)
                }
            }
        }
    }
}

/** Notes-tab filter row: `All` followed by every tag A→Z. */
@Composable
fun TagFilterRow(tags: List<String>, selected: String?, onSelect: (String?) -> Unit) {
    LazyRow(
        Modifier.fillMaxWidth(),
        contentPadding = PaddingValues(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        item(key = "__all") {
            FilterChip("All", "tag-filter-all", selected == null) { onSelect(null) }
        }
        items(tags, key = { it }) { tag ->
            FilterChip("#$tag", "tag-filter-$tag", selected == tag) { onSelect(tag) }
        }
    }
}

@Composable
private fun FilterChip(label: String, tag: String, active: Boolean, onClick: () -> Unit) {
    Box(
        Modifier
            .height(32.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(if (active) Tokens.Accent else Tokens.Surface)
            .semantics { stateDescription = if (active) "selected" else "" }
            .testTag(tag)
            .tap(onClick = onClick)
            .padding(horizontal = 12.dp),
        contentAlignment = Alignment.Center,
    ) {
        Label(
            label,
            textStyle(
                15.sp,
                color = if (active) Color.White else Tokens.Text,
                weight = if (active) FontWeight.SemiBold else FontWeight.Medium,
            ),
            maxLines = 1,
        )
    }
}
