#!/usr/bin/env bash
# Side-by-side grids: spec reference + every implementation, per screen -> results/compare/*.png
cd "$(dirname "$0")/.."
mkdir -p results/compare
FWS=(react-native swift flutter kmp angular-native lynx)
for s in 01-notes 02-editor-preview 03-editor-edit 04-starred 05-settings 06-checklist-preview 07-notes-dark; do
  args=(-i "spec/reference-final/$s.png"); chain=""; labels=""
  for f in "${FWS[@]}"; do args+=(-i "results/$f/screens/$s.png"); done
  for i in $(seq 0 6); do chain+="[$i]scale=402:874[v$i];"; labels+="[v$i]"; done
  ffmpeg -loglevel error -y "${args[@]}" -filter_complex "${chain}${labels}hstack=7" "results/compare/$s.png"
done
