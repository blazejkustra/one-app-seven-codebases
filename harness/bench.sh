#!/usr/bin/env bash
# Usage: harness/bench.sh <framework-dir> <bundle-id> <simulator .app> [device .app] [steps...]
# steps: size screens qa coldstart monkey   (default: all)
# Env: UDID (default: the "bench" simulator), MONKEY_TAPS (default 2000), COLD_RUNS (default 10)
set -uo pipefail

FW=$1; BUNDLE=$2; SIM_APP=$3; DEV_APP=${4:-}
shift $(( $# < 4 ? $# : 4 ))
STEPS=${*:-size screens qa coldstart monkey}

ROOT=$(cd "$(dirname "$0")/.." && pwd)
H=$ROOT/harness
PY=$H/.venv/bin/python
UDID=${UDID:-$(awk '$1=="bench"{print $2}' "$ROOT/results/simulators.txt")}
OUT=$ROOT/results/$FW
XCTESTRUN=$(ls "$H"/xcui/build/Build/Products/*.xctestrun | head -1)
mkdir -p "$OUT"

log() { echo "[$(date +%H:%M:%S)] [$FW] $*"; }

prep() {
  xcrun simctl boot "$UDID" 2>/dev/null
  xcrun simctl bootstatus "$UDID" -b >/dev/null
  xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 \
    --cellularMode active --cellularBars 4 --wifiBars 3 --dataNetwork wifi
}

reinstall() {
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null
  xcrun simctl uninstall "$UDID" "$BUNDLE" 2>/dev/null
  xcrun simctl install "$UDID" "$SIM_APP"
}

xctest() { # $1 = -only-testing target, $2 = log file, $3 = timeout seconds (default 300)
  TEST_RUNNER_TARGET_BUNDLE=$BUNDLE TEST_RUNNER_OUT_DIR=$OUT_DIR \
  TEST_RUNNER_MONKEY_TAPS=${MONKEY_TAPS:-2000} TEST_RUNNER_SEED=${SEED:-42} \
    xcodebuild test-without-building -xctestrun "$XCTESTRUN" -destination "id=$UDID" \
    -only-testing:"HarnessUITests/$1" > "$2" 2>&1 &
  local pid=$! limit=${3:-300} waited=0
  while kill -0 $pid 2>/dev/null; do
    sleep 2; waited=$((waited + 2))
    # xcodebuild sometimes hangs after the test finished: stop waiting once the suite reported
    if grep -q "^Test Suite 'Selected tests' \(passed\|failed\)" "$2" 2>/dev/null; then sleep 5; kill $pid 2>/dev/null; break; fi
    if [ $waited -ge "$limit" ]; then echo "TIMEOUT after ${limit}s" >> "$2"; kill $pid 2>/dev/null; break; fi
  done
  wait $pid 2>/dev/null
  grep -q "^Test Suite 'Selected tests' passed" "$2"
}

step_size() {
  log "size"
  local sim_kb dev_kb zip_kb=""
  sim_kb=$(du -sk "$SIM_APP" | cut -f1)
  if [ -n "$DEV_APP" ] && [ -d "$DEV_APP" ]; then
    dev_kb=$(du -sk "$DEV_APP" | cut -f1)
    local tmp; tmp=$(mktemp -d)
    mkdir -p "$tmp/Payload" && cp -R "$DEV_APP" "$tmp/Payload/"
    (cd "$tmp" && zip -qr -9 app.ipa Payload)
    zip_kb=$(( $(stat -f%z "$tmp/app.ipa") / 1024 ))
    rm -rf "$tmp"
  fi
  printf '{"simulator_app_kb": %s, "device_app_kb": %s, "device_ipa_zip_kb": %s}\n' \
    "$sim_kb" "${dev_kb:-null}" "${zip_kb:-null}" | tee "$OUT/size.json"
}

step_screens() {
  log "screens"
  reinstall
  OUT_DIR=$OUT/screens; rm -rf "$OUT_DIR"; mkdir -p "$OUT_DIR"
  if [ "${SCREENS:-final}" = v1 ]; then t=Screens; ref=reference; else t=ScreensFinal; ref=reference-final; fi
  xctest "$t" "$OUT/screens.log" || log "screens test reported a failure (see screens.log)"
  "$PY" "$H/fidelity.py" "$OUT_DIR" "$ROOT/spec/$ref" | tee "$OUT/fidelity.json"
}

step_qa() {
  log "qa"
  OUT_DIR=$OUT/qa; rm -rf "$OUT_DIR"; mkdir -p "$OUT_DIR"
  : > "$OUT/qa.tsv"
  for t in $(grep -oE 'func (test[0-9]{2}_[A-Za-z]+)' "$H/xcui/UITests/Harness.swift" | awk '{print $2}'); do
    reinstall
    if xctest "QA/$t" "$OUT_DIR/$t.log"; then r=PASS; msg=""; else
      r=FAIL; msg=$(grep -E "error: -\[|XCTAssert|failed -" "$OUT_DIR/$t.log" | grep -v "^Testing failed" | head -2 | sed -E 's/.*error: -\[[^]]*\] : //' | tr '\t\n' '  ')
    fi
    printf '%s\t%s\t%s\n' "$t" "$r" "$msg" | tee -a "$OUT/qa.tsv"
  done
  log "qa: $(grep -c PASS "$OUT/qa.tsv") pass / $(grep -c FAIL "$OUT/qa.tsv") fail"
}

step_coldstart() {
  log "coldstart"
  local dir=$OUT/coldstart; rm -rf "$dir"; mkdir -p "$dir"
  reinstall
  xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null; sleep 6   # first launch seeds data
  for i in $(seq 1 "${COLD_RUNS:-10}"); do
    xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null; sleep 2
    xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$dir/run$i.mp4" 2>/dev/null &
    local rec=$!; sleep 2
    xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null
    sleep 5
    kill -INT $rec; wait $rec 2>/dev/null
    "$PY" "$H/coldstart_analyze.py" "$dir/run$i.mp4" | tee -a "$dir/runs.jsonl"
  done
  "$PY" - "$dir/runs.jsonl" <<'EOF' | tee "$OUT/coldstart.json"
import json, statistics, sys
ms = [json.loads(l)["ms"] for l in open(sys.argv[1])]
print(json.dumps({"runs_ms": ms, "median_ms": statistics.median(ms), "min_ms": min(ms), "max_ms": max(ms)}))
EOF
  rm -f "$dir"/*.mp4
}

step_monkey() {
  log "monkey (${MONKEY_TAPS:-2000} taps)"
  reinstall
  OUT_DIR=$OUT/monkey; rm -rf "$OUT_DIR"; mkdir -p "$OUT_DIR"
  local exe; exe=$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$SIM_APP/Info.plist")
  local marker; marker=$(mktemp); sleep 1
  xctest Monkey/testMonkey "$OUT_DIR/monkey.log" 32400 || log "monkey test reported a failure (see monkey.log)"
  local reports; reports=$(find ~/Library/Logs/DiagnosticReports -newer "$marker" -name "${exe}*" 2>/dev/null | wc -l | tr -d ' ')
  "$PY" - "$OUT_DIR/monkey.json" "$reports" <<'EOF' | tee "$OUT/monkey.json"
import json, sys
try: r = json.load(open(sys.argv[1]))
except Exception: r = {"error": "monkey.json not written"}
r["crash_reports"] = int(sys.argv[2])
print(json.dumps(r))
EOF
}

prep
for s in $STEPS; do "step_$s"; done
log "done"
