#!/usr/bin/env bash
# Renders every reference PNG from the HTML mockups (headless Chrome, 402x874pt @3x).
cd "$(dirname "$0")"
C="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
r() { mkdir -p "$(dirname "$1")"; "$C" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
  --window-size=1206,2622 --screenshot="$PWD/$1" "file://$PWD/mockups/$2&zoom=1" 2>/dev/null; }
i=1; for s in notes editor-preview editor-edit starred settings; do r "$(printf 'reference/%02d-%s.png' $i $s)" "index.html?screen=$s"; i=$((i+1)); done
r iterations/ref/02-notes.png "iterations.html?v=2&screen=notes"
r iterations/ref/02-editor-preview.png "iterations.html?v=2&screen=editor-preview"
r iterations/ref/03-notes.png "iterations.html?v=3&screen=notes"
r iterations/ref/03-checklist-preview.png "iterations.html?v=3&screen=checklist-preview"
r iterations/ref/04-editor-preview.png "iterations.html?v=4&screen=editor-preview"
r iterations/ref/04-notes-toast.png "iterations.html?v=4&screen=notes-toast"
r iterations/ref/05-settings.png "iterations.html?v=5&screen=settings"
r iterations/ref/05-notes-dark.png "iterations.html?v=5&screen=notes&dark=1"
r iterations/ref/05-checklist-preview-dark.png "iterations.html?v=5&screen=checklist-preview&dark=1"
r iterations/ref/06-editor-preview.png "iterations.html?v=6&screen=editor-preview"
i=1; for s in notes editor-preview editor-edit starred settings checklist-preview "notes&dark=1"; do
  r "$(printf 'reference-final/%02d-%s.png' $i "$(echo "$s" | sed 's/&dark=1/-dark/')")" "iterations.html?v=6&screen=$s"; i=$((i+1)); done
