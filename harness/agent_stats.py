#!/usr/bin/env python3
"""Per-iteration stats from a Claude Code subagent transcript (JSONL).
A segment starts at each plain-text user prompt (initial build or iteration request) and ends
at the last transcript entry before the next prompt. Reports wall-clock minutes, tool calls,
model turns and output tokens per segment."""
import json, sys
from datetime import datetime

def ts(e):
    return datetime.fromisoformat(e["timestamp"].replace("Z", "+00:00")) if e.get("timestamp") else None

def main(path, label):
    rows = [json.loads(l) for l in open(path)]
    segs, cur = [], None
    for e in rows:
        m = e.get("message") or {}
        c = m.get("content")
        if e.get("type") == "user" and isinstance(c, str) and (not e.get("isMeta") or "Next product iteration" in c):
            cur = {"prompt": c.split("Next product iteration: implement the change request in ")[-1][:40].replace("\n", " "), "start": ts(e), "end": ts(e),
                   "tools": 0, "turns": 0, "out_tokens": 0, "usage": {}, "out_chars": 0}
            segs.append(cur)
            continue
        if cur is None:
            continue
        if ts(e) and not cur.get("done"):
            cur["end"] = ts(e)
        if e.get("type") == "assistant" and "SubagentHandback" in json.dumps(m.get("content", "")):
            cur["done"] = True
        if e.get("type") == "assistant" and not cur.get("done_counted"):
            cur["turns"] += 1
            cur["tools"] += sum(1 for c in m.get("content", []) if isinstance(c, dict) and c.get("type") == "tool_use")
            u = m.get("usage") or {}
            if m.get("id"):  # one usage record per model call (entries repeat per content block)
                cur["usage"][m["id"]] = u.get("input_tokens", 0) + u.get("cache_creation_input_tokens", 0), u.get("cache_read_input_tokens", 0)
            for c in m.get("content", []):
                if not isinstance(c, dict):
                    continue
                if c.get("type") == "tool_use":
                    cur["out_chars"] += len(json.dumps(c.get("input", {})))
                elif c.get("type") in ("text", "thinking"):
                    cur["out_chars"] += len(c.get("text") or c.get("thinking") or "")
    for i, s in enumerate(segs):
        sec = (s["end"] - s["start"]).total_seconds()
        fresh = sum(a for a, _ in s["usage"].values())
        cached = sum(b for _, b in s["usage"].values())
        out_est = s["out_chars"] // 4
        print(f"{label}\t{i + 1}\t{sec:.0f}\t{s['tools']}\t{s['turns']}\t{s['start'].isoformat()}\t{s['end'].isoformat()}"
              f"\t{fresh + cached + out_est}\t{fresh}\t{cached}\t{out_est}")

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
