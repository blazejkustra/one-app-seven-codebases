#!/usr/bin/env bash
# demo.sh <framework> — fresh install on the framework's own simulator, then the scripted walkthrough (Demo test).
# The video itself is captured around this with argent's screen-recording tools.
cd "$(dirname "$0")/.."
FW=$1
IFS=$'\t' read -r _ BUNDLE SIM DEV < <(awk -F'\t' -v f="$FW" '$1==f' harness/apps.tsv)
export UDID=${UDID:-$(awk -v f="$FW" '$1==f{print $2}' results/simulators.txt)}
source <(sed -n '/^log()/,/^step_size/p' harness/bench.sh | sed '$d')
H=$PWD/harness; XCTESTRUN=$(ls "$H"/xcui/build/Build/Products/*.xctestrun | head -1); SIM_APP=$PWD/$SIM; OUT_DIR=/tmp/mdnotes-demo
prep; reinstall; xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null; sleep 4; xcrun simctl terminate "$UDID" "$BUNDLE"
mkdir -p "results/$FW"
xctest Demo/testDemo "results/$FW/demo.log" 400 && echo "DEMO PASS" || { echo "DEMO FAIL"; grep "error:" "results/$FW/demo.log"; }
