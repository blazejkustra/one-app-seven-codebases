#!/usr/bin/env bash
# run.sh <framework> [steps...] — bench one app using harness/apps.tsv; UDID defaults to the bench sim
cd "$(dirname "$0")/.."
FW=$1; shift
IFS=$'\t' read -r _ BUNDLE SIM DEV < <(awk -F'\t' -v f="$FW" '$1==f' harness/apps.tsv)
[ -z "$BUNDLE" ] && { echo "unknown framework $FW"; exit 1; }
exec harness/bench.sh "$FW" "$BUNDLE" "$PWD/$SIM" "$PWD/$DEV" "$@"
