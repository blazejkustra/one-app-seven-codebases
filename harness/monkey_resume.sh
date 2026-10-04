#!/usr/bin/env bash
# monkey_resume.sh <framework> [target=15000]
# XCUITest occasionally aborts a long monkey run when a system sheet (share sheet, keyboard) makes an
# accessibility query time out. This tops the run up in segments until <target> taps are done and
# writes the aggregate to results/<fw>/monkey.json (segments kept in results/<fw>/monkey-segments/).
cd "$(dirname "$0")/.."
FW=$1; TARGET=${2:-15000}
IFS=$'\t' read -r _ BUNDLE SIM DEV < <(awk -F'\t' -v f="$FW" '$1==f' harness/apps.tsv)
export UDID=${UDID:-$(awk -v f="$FW" '$1==f{print $2}' results/simulators.txt)}
SEGS=results/$FW/monkey-segments; mkdir -p "$SEGS"
# the first segment is the run bench.sh already made
[ -f "results/$FW/monkey.json" ] && [ ! -f "$SEGS/seg1.json" ] && cp "results/$FW/monkey.json" "$SEGS/seg1.json"
done_taps() { python3 -c "import json,glob,sys; print(sum(json.load(open(f)).get('taps',0) for f in glob.glob(sys.argv[1]+'/seg*.json')))" "$SEGS"; }
n=$(ls "$SEGS"/seg*.json 2>/dev/null | wc -l | tr -d ' ')
while [ "$(done_taps)" -lt "$TARGET" ]; do
  n=$((n + 1)); left=$((TARGET - $(done_taps)))
  echo "[$FW] segment $n: $left taps left"
  rm -f "results/$FW/monkey.json"
  SEED=$((42 + n)) MONKEY_TAPS=$left harness/run.sh "$FW" monkey > "$SEGS/seg$n.log" 2>&1
  if [ -f "results/$FW/monkey.json" ]; then cp "results/$FW/monkey.json" "$SEGS/seg$n.json"
  else echo '{"taps":0,"events":["segment wrote no result"]}' > "$SEGS/seg$n.json"; fi
  [ "$n" -gt 40 ] && { echo "too many segments, giving up"; break; }
done
python3 - "$SEGS" "results/$FW/monkey.json" "$BUNDLE" <<'EOF'
import glob, json, sys
segs = [json.load(open(f)) for f in sorted(glob.glob(sys.argv[1] + "/seg*.json"), key=lambda p: int(p.split("seg")[-1].split(".")[0]))]
out = {"bundle": sys.argv[3], "taps": sum(s.get("taps", 0) for s in segs), "typed": sum(s.get("typed", 0) for s in segs),
       "seconds": sum(s.get("seconds", 0) for s in segs), "crash_reports": sum(s.get("crash_reports", 0) for s in segs),
       "segments": len(segs), "events": [e for s in segs for e in s.get("events", [])]}
out["crashes"] = sum(1 for e in out["events"] if "app state 1" in e)
out["left_app"] = sum(1 for e in out["events"] if "app state 2" in e or "app state 3" in e)
json.dump(out, open(sys.argv[2], "w"), indent=2)
print(json.dumps({k: out[k] for k in ("taps", "crashes", "left_app", "crash_reports", "segments")}))
EOF
