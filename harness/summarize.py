#!/usr/bin/env python3
"""Collects every metric into results/summary.json and prints the README tables.
Usage: summarize.py [agent-stats.tsv]"""
import json, pathlib, statistics, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
FWS = ["react-native", "swift", "flutter", "kmp", "angular-native", "lynx"]
NAMES = {"react-native": "React Native (Expo)", "swift": "Swift (SwiftUI)", "flutter": "Flutter",
         "kmp": "Compose Multiplatform", "angular-native": "Angular Native", "lynx": "Lynx"}
ITERS = ["v1", "v2-tags", "v3-checklists", "v4-delete-undo", "v5-dark-mode", "v6-share"]

# hand-written source files per implementation (git-tracked, generated/config files excluded)
PREFIX = __import__("os").environ.get("ROUND_PREFIX", "")
SOURCES = {
    "swift": ["swift/MarkdownNotes/*.swift"],
    "react-native": ["react-native/App.tsx", "react-native/src/*"],
    "flutter": ["flutter/lib/*.dart", "flutter/ios/Runner/AppDelegate.swift"],
    "kmp": ["kmp/shared/src/*.kt", "kmp/shared/src/*.sq", "kmp/iosApp/iosApp/*.swift"],
    "angular-native": ["angular-native/src/app/*.ts"],
    "lynx": ["lynx/src/*.ts", "lynx/src/*.tsx", "lynx/ios/*.m", "lynx/ios/*.h", "lynx/ios/*.swift"],
}
SOURCES = {k: [PREFIX + g for g in v] for k, v in SOURCES.items()}


def git(*a):
    return subprocess.run(["git", *a], cwd=ROOT, capture_output=True, text=True).stdout


def loc(fw):
    files = set()
    for g in SOURCES[fw]:
        files.update(f for f in git("ls-files", "--", g).splitlines() if ".test." not in f and "/Pods/" not in f and "/build/" not in f)
    n = sum(1 for f in files for line in open(ROOT / f, errors="ignore") if line.strip())
    return n, len(files)


def churn(fw):
    out = {}
    rev = __import__("os").environ.get("CHURN_REV", "HEAD")  # round 1: the commit before it was moved
    for line in git("log", "--reverse", "--format=%H %s", rev, "--", PREFIX + fw, fw).splitlines():
        h, subj = line.split(" ", 1)
        if not subj.startswith(f"{fw}: "):
            continue
        it = subj.split(": ", 1)[1].split(" ")[0]
        stat = git("show", "--shortstat", "--format=", h, "--", *SOURCES[fw], *[g[len(PREFIX):] for g in SOURCES[fw]]).strip()
        ins = int(stat.split(" insertion")[0].split(", ")[-1]) if "insertion" in stat else 0
        dele = int(stat.split(" deletion")[0].split(", ")[-1]) if "deletion" in stat else 0
        out[it] = ins + dele
    return out


def monkey(s):
    """(real crashes, app-switches): XCUIApplication.State 1 = not running (crash); 2/3 = backgrounded."""
    ev = s["monkey"].get("events", [])
    crashes = sum(1 for e in ev if "app state 1" in e)
    switches = sum(1 for e in ev if "app state 2" in e or "app state 3" in e)
    return max(crashes, s["monkey"].get("crash_reports", 0)), switches


def load(p):
    try:
        return json.loads((ROOT / p).read_text())
    except Exception:
        return None


def agent_stats(path):
    stats = {}
    if not path:
        return stats
    for line in open(path):
        r = line.rstrip("\n").split("\t")
        fw, idx, sec, tools, turns = r[:5]
        tok = [int(x) for x in r[7:11]] if len(r) >= 11 else [0, 0, 0, 0]
        stats.setdefault(fw, {})[ITERS[int(idx) - 1]] = {"sec": int(sec), "tools": int(tools), "turns": int(turns),
                                                         "tokens": tok[0], "fresh": tok[1], "cached": tok[2], "out_est": tok[3]}
    return stats


def qa(fw):
    p = ROOT / f"{PREFIX}results/{fw}/qa.tsv"
    if not p.exists():
        return None
    rows = [l.rstrip("\n").split("\t") for l in p.read_text().splitlines() if l.strip()]
    return {"total": len(rows), "fail": [r[0] for r in rows if r[1] != "PASS"]}


def main():
    ag = agent_stats(sys.argv[1] if len(sys.argv) > 1 else None)
    summary = {}
    for fw in FWS:
        s = {"name": NAMES[fw], "agent": ag.get(fw, {}), "loc": loc(fw), "churn": churn(fw),
             "size": load(f"{PREFIX}results/{fw}/size.json"), "fidelity": load(f"{PREFIX}results/{fw}/fidelity.json"),
             "coldstart": load(f"{PREFIX}results/{fw}/coldstart.json"), "monkey": load(f"{PREFIX}results/{fw}/monkey.json"),
             "qa": qa(fw), "review": (load(f"{PREFIX}results/qa-review.json") or {}).get(fw)}
        a = s["agent"]
        s["minutes_v1"] = round(a["v1"]["sec"] / 60, 1) if "v1" in a else None
        later = [a[i]["sec"] for i in ITERS[1:] if i in a]
        s["minutes_iterations"] = round(sum(later) / 60, 1) if len(later) == 5 else None
        s["minutes_total"] = round(sum(v["sec"] for v in a.values()) / 60, 1) if len(a) == 6 else None
        s["tools_total"] = sum(v["tools"] for v in a.values()) if len(a) == 6 else None
        s["tokens_total"] = sum(v["tokens"] for v in a.values()) if len(a) == 6 else None
        s["tokens_fresh"] = sum(v["fresh"] for v in a.values()) if len(a) == 6 else None
        s["tokens_out_est"] = sum(v["out_est"] for v in a.values()) if len(a) == 6 else None
        summary[fw] = s
    (ROOT / f"{PREFIX}results/summary.json").write_text(json.dumps(summary, indent=2, default=str))

    def cell(v, fmt="{}"):
        return "—" if v is None else fmt.format(v)

    print("| | " + " | ".join(NAMES[f] for f in FWS) + " |")
    print("|---|" + "---|" * len(FWS))
    rows = [
        ("Agent minutes, v1 (first build)", lambda s: cell(s["minutes_v1"])),
        ("Agent minutes, 5 iterations", lambda s: cell(s["minutes_iterations"])),
        ("**Agent minutes, total**", lambda s: cell(s["minutes_total"], "**{}**")),
        ("Agent tool calls, total", lambda s: cell(s["tools_total"])),
        ("Tokens processed, total (M, incl. cached context)", lambda s: cell(s["tokens_total"] and s["tokens_total"] / 1e6, "{:.1f}")),
        ("Fresh input tokens (k, non-cached)", lambda s: cell(s["tokens_fresh"] and round(s["tokens_fresh"] / 1e3))),
        ("Output tokens (k, estimated)", lambda s: cell(s["tokens_out_est"] and round(s["tokens_out_est"] / 1e3))),
        ("Hidden QA checks passed (of 32)", lambda s: cell(s["qa"] and s["qa"]["total"] - len(s["qa"]["fail"]))),
        ("→ functional bugs after manual review", lambda s: cell(s.get("review") and s["review"]["functional_bugs"])),
        ("→ accessibility defects (VoiceOver can't read / type)", lambda s: cell(s.get("review") and s["review"]["accessibility_defects"])),
        ("Visual fidelity, layout SSIM vs spec (7 screens)", lambda s: cell(s["fidelity"] and s["fidelity"]["mean_layout_ssim"], "{:.3f}")),
        ("Visual fidelity, pixel SSIM vs spec", lambda s: cell(s["fidelity"] and s["fidelity"]["mean_ssim"], "{:.3f}")),
        ("Cold start, median of 10 (ms)", lambda s: cell(s["coldstart"] and s["coldstart"]["median_ms"], "{:.0f}") + ("\\*" if s["name"] == "Flutter" else "")),
        ("Crashes in random taps", lambda s: cell(s["monkey"] and f'{monkey(s)[0]} in {s["monkey"].get("taps", 0):,}')),
        ("Random taps that left the app (share sheet etc.)", lambda s: cell(s["monkey"] and monkey(s)[1])),
        ("App size, device IPA zipped (MB)", lambda s: cell(s["size"] and s["size"]["device_ipa_zip_kb"] and round(s["size"]["device_ipa_zip_kb"] / 1024, 1))),
        ("App size, device .app unzipped (MB)", lambda s: cell(s["size"] and round(s["size"]["device_app_kb"] / 1024, 1))),
        ("Hand-written source lines", lambda s: cell(s["loc"][0])),
    ]
    for label, f in rows:
        print(f"| {label} | " + " | ".join(f(summary[fw]) for fw in FWS) + " |")

    print("\nPer-iteration agent minutes (tool calls) · tokens processed (M) · source lines changed:\n")
    print("| Iteration | " + " | ".join(NAMES[f] for f in FWS) + " |")
    print("|---|" + "---|" * len(FWS))
    for it in ITERS:
        cells = []
        for fw in FWS:
            a = summary[fw]["agent"].get(it)
            c = summary[fw]["churn"].get(it)
            cells.append("—" if not a else f"{a['sec'] / 60:.1f} ({a['tools']}) · {a['tokens'] / 1e6:.1f}M · ±{c if c is not None else '?'}")
        print(f"| {it} | " + " | ".join(cells) + " |")


if __name__ == "__main__":
    main()
