package com.mdnotes.kotlin.ui

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsBottomHeight
import androidx.compose.foundation.selection.toggleable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Clickable without Material ripple: a plain, chrome-free tap target. */
@Composable
fun Modifier.tap(role: Role = Role.Button, onClick: () -> Unit): Modifier =
    clickable(
        interactionSource = remember { MutableInteractionSource() },
        indication = null,
        role = role,
        onClick = onClick,
    )

/** §3.2 screen header: 52 tall, 20 side padding, 34 bold title, optional trailing content. */
@Composable
fun ScreenHeader(title: String, trailing: @Composable (() -> Unit)? = null) {
    Row(
        Modifier.fillMaxWidth().height(52.dp).padding(horizontal = 20.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Label(title, textStyle(34.sp, weight = FontWeight.Bold), Modifier.weight(1f), maxLines = 1)
        trailing?.invoke()
    }
}

@Composable
fun AddButton(onClick: () -> Unit) {
    Canvas(
        Modifier
            .size(36.dp)
            .clip(CircleShape)
            .background(Tokens.Accent)
            .semantics { contentDescription = "New note" }
            .testTag("add-note-button")
            .tap(onClick = onClick),
    ) {
        val half = 7.5.dp.toPx()
        val stroke = 2.dp.toPx()
        val c = center
        drawLine(Color.White, Offset(c.x - half, c.y), Offset(c.x + half, c.y), stroke, StrokeCap.Round)
        drawLine(Color.White, Offset(c.x, c.y - half), Offset(c.x, c.y + half), stroke, StrokeCap.Round)
    }
}

/** §3.1 tab bar. */
@Composable
fun TabBar(current: Tab, onSelect: (Tab) -> Unit) {
    Column(Modifier.fillMaxWidth().background(Tokens.Surface)) {
        Box(Modifier.fillMaxWidth().height(1.dp).background(Tokens.Separator))
        Row(Modifier.fillMaxWidth().height(56.dp)) {
            TabItem("Notes", "tab-notes", current == Tab.NOTES) { onSelect(Tab.NOTES) }
            TabItem("Starred", "tab-starred", current == Tab.STARRED) { onSelect(Tab.STARRED) }
            TabItem("Settings", "tab-settings", current == Tab.SETTINGS) { onSelect(Tab.SETTINGS) }
        }
        Spacer(Modifier.windowInsetsBottomHeight(WindowInsets.navigationBars))
    }
}

@Composable
private fun androidx.compose.foundation.layout.RowScope.TabItem(
    label: String,
    tag: String,
    active: Boolean,
    onClick: () -> Unit,
) {
    Box(
        Modifier
            .weight(1f)
            .height(56.dp)
            .semantics { stateDescription = if (active) "selected" else "" }
            .testTag(tag)
            .tap(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Label(
            label,
            textStyle(
                15.sp,
                color = if (active) Tokens.Accent else Tokens.TextTertiary,
                weight = if (active) FontWeight.SemiBold else FontWeight.Medium,
            ),
        )
    }
}

/** §3.5 custom switch: 51×31 pill, 27 knob, 2 inset. */
@Composable
fun PillSwitch(checked: Boolean, onChange: (Boolean) -> Unit, modifier: Modifier = Modifier) {
    val track by animateColorAsState(if (checked) Tokens.Accent else Tokens.Fill, label = "track")
    val knobX by animateDpAsState(if (checked) 22.dp else 2.dp, label = "knob")
    Box(
        modifier
            .size(width = 51.dp, height = 31.dp)
            .clip(RoundedCornerShape(50))
            .background(track)
            .toggleable(
                value = checked,
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                role = Role.Switch,
                onValueChange = onChange,
            ),
    ) {
        Box(
            Modifier
                .offset { IntOffset(knobX.roundToPx(), 2.dp.roundToPx()) }
                .size(27.dp)
                .clip(CircleShape)
                .background(Color.White),
        )
    }
}

/** §3.6 segmented control. */
@Composable
fun SegmentedControl(mode: EditorMode, onSelect: (EditorMode) -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier
            .fillMaxWidth()
            .height(36.dp)
            .clip(RoundedCornerShape(9.dp))
            .background(Tokens.Fill)
            .padding(2.dp),
        horizontalArrangement = Arrangement.spacedBy(0.dp),
    ) {
        Segment("Edit", "mode-edit", mode == EditorMode.EDIT) { onSelect(EditorMode.EDIT) }
        Segment("Preview", "mode-preview", mode == EditorMode.PREVIEW) { onSelect(EditorMode.PREVIEW) }
    }
}

@Composable
private fun androidx.compose.foundation.layout.RowScope.Segment(
    label: String,
    tag: String,
    active: Boolean,
    onClick: () -> Unit,
) {
    Box(
        Modifier
            .weight(1f)
            .height(32.dp)
            .clip(RoundedCornerShape(7.dp))
            .background(if (active) Tokens.Surface else Color.Transparent)
            .semantics { stateDescription = if (active) "selected" else "" }
            .testTag(tag)
            .tap(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Label(
            label,
            textStyle(
                15.sp,
                color = if (active) Tokens.Text else Tokens.TextSecondary,
                weight = if (active) FontWeight.SemiBold else FontWeight.Medium,
            ),
        )
    }
}

@Composable
fun HSpace(width: Int) = Spacer(Modifier.width(width.dp))

@Composable
fun VSpace(height: Int) = Spacer(Modifier.height(height.dp))
