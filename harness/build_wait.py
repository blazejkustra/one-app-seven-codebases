#!/usr/bin/env python3
"""Time each agent spent waiting on build/install commands (Bash tool calls whose command builds,
installs dependencies or generates native projects), from tool_use -> tool_result timestamps."""
import json, re, sys
from datetime import datetime

BUILD = re.compile(r"xcodebuild|xcodegen|gradlew|gradle |flutter (build|pub|run|install)|pod install|expo prebuild|expo run:ios|npm (ci|install)|rspeedy build|npm run build")

def ts(e):
    return datetime.fromisoformat(e["timestamp"].replace("Z", "+00:00"))

for fw, path in (l.split() for l in open(sys.argv[1])):
    rows = [json.loads(l) for l in open(path)]
    starts, total, n, toolsec = {}, 0.0, 0, 0.0
    for e in rows:
        m = e.get("message") or {}
        for c in m.get("content", []) if isinstance(m.get("content"), list) else []:
            if c.get("type") == "tool_use":
                starts[c["id"]] = (ts(e), c.get("name") == "Bash" and bool(BUILD.search(json.dumps(c.get("input", {})))))
            elif c.get("type") == "tool_result" and c.get("tool_use_id") in starts:
                t0, is_build = starts.pop(c["tool_use_id"])
                d = (ts(e) - t0).total_seconds()
                toolsec += d
                if is_build:
                    total += d; n += 1
    print(f"{fw}\t{total / 60:.1f}\t{n}\t{toolsec / 60:.1f}")
