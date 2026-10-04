#!/usr/bin/env python3
"""Average number of build agents running at the same time during each framework's work (from agent-stats.tsv)."""
import sys
from datetime import datetime
rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1])]
segs = [(r[0], datetime.fromisoformat(r[5]), datetime.fromisoformat(r[6])) for r in rows]
for fw in dict.fromkeys(r[0] for r in rows):
    total = busy = 0.0
    for f, a, b in segs:
        if f != fw:
            continue
        t, step = a, 5
        while t < b:
            busy += sum(1 for _, x, y in segs if x <= t < y)
            total += 1
            t = datetime.fromtimestamp(t.timestamp() + step, t.tzinfo)
    print(f"{fw}\t{busy / total:.2f}")
