#!/usr/bin/env python3
"""Cold start = time from the first changed frame (launch animation begins) to the first
frame from which the screen stays equal to its settled state (taken 3.5 s after start).
Frame-based, so it works identically for every UI stack. Status bar / home indicator rows
are ignored."""
import json, subprocess, sys
import numpy as np

W, H = 134, 291           # 1/9-scale grayscale is plenty for change detection
BODY = (slice(21, H - 12), slice(None))
SETTLE_S, THRESH = 3.5, 1.0


def frames(path):
    pts = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
                          "frame=pts_time", "-of", "csv=p=0", path], capture_output=True, text=True).stdout.split()
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-fps_mode", "passthrough", "-vf",
                          f"scale={W}:{H},format=gray", "-f", "rawvideo", "-"], capture_output=True).stdout
    arr = np.frombuffer(raw, np.uint8).reshape(-1, H, W).astype(np.int16)
    n = min(len(arr), len(pts))
    return [float(p.strip(",")) for p in pts[:n]], arr[:n]


def analyze(path):
    t, f = frames(path)
    diff = lambda a, b: float(np.abs(a[BODY] - b[BODY]).mean())
    # baseline = home screen ~1 s into the recording (launch is issued at ~2 s; frame 0 can be stale)
    base = max(i for i in range(len(f)) if t[i] <= 1.0)
    start = next(i for i in range(base, len(f)) if diff(f[i], f[base]) > THRESH)
    final = max(i for i in range(len(f)) if t[i] <= t[start] + SETTLE_S)
    end = final
    while end > start and diff(f[end - 1], f[final]) <= THRESH:
        end -= 1
    return {"ms": round((t[end] - t[start]) * 1000), "start": t[start], "end": t[end], "frames": len(f)}


if __name__ == "__main__":
    print(json.dumps(analyze(sys.argv[1])))
