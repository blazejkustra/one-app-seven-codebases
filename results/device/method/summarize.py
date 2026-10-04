#!/usr/bin/env python3
"""Parse results/device/<app>/*.log into summary.tsv / summary.json."""
import json, re, statistics as st, pathlib
D = pathlib.Path(__file__).resolve().parent.parent
APPS = ["swift", "react-native", "flutter", "kmp", "angular-native", "lynx"]
def xct(p):
    m = re.search(r"values: \[([^\]]+)\]", p.read_text())
    return [float(v) * 1000 for v in m.group(1).split(",")]
def mb(txt):
    m = re.search(r"App size: ([\d,\.]+) (KB|MB) compressed, ([\d,\.]+) (KB|MB) uncompressed", txt)
    f = lambda v, u: float(v.replace(",", ".")) * (1 if u == "MB" else 1 / 1000)
    return f(m.group(1), m.group(2)), f(m.group(3), m.group(4))
out = {}
for a in APPS:
    p = D / a
    ff, rs = xct(p / "testLaunchMetric.log"), xct(p / "testLaunchToResponsive.log")
    runs = [dict(re.findall(r"(\w+)=([\d\.\-]+|yes|NO)", l)) for l in (p / "testTimeToContent.log").read_text().splitlines() if l.startswith("TTC ") or " TTC com" in l]
    runs = [r for r in runs if int(r["run"]) > 0]
    hi = [float(r["ttc_ms"]) for r in runs]
    lo = [float(r["ttc_ms"]) - float(r["gap_before_content_ms"]) for r in runs]
    comp, unc = mb((p / "App Thinning Size Report.txt").read_text())
    s = lambda v: {"median": round(st.median(v)), "min": round(min(v)), "max": round(max(v)), "values": [round(x) for x in v]}
    out[a] = {"first_frame_ms": s(ff), "responsive_ms": s(rs), "ttc_upper_ms": s(hi), "ttc_lower_ms": s(lo),
              "ttc_frame_gap_ms": round(st.median(float(r["median_frame_gap_ms"]) for r in runs)),
              "thinned_download_mb": comp, "thinned_install_mb": unc, "cards_ok": all(r["cards"] == "yes" for r in runs)}
(D / "summary.json").write_text(json.dumps(out, indent=2))
rows = ["app\tfirst_frame_med\tmin-max\tresponsive_med\tmin-max\tttc_lower_med\tttc_upper_med\tttc_upper_min-max\tdownload_MB\tinstall_MB"]
for a, o in out.items():
    f = lambda k: f"{o[k]['min']}-{o[k]['max']}"
    rows.append(f"{a}\t{o['first_frame_ms']['median']}\t{f('first_frame_ms')}\t{o['responsive_ms']['median']}\t{f('responsive_ms')}\t{o['ttc_lower_ms']['median']}\t{o['ttc_upper_ms']['median']}\t{f('ttc_upper_ms')}\t{o['thinned_download_mb']}\t{o['thinned_install_mb']}")
(D / "summary.tsv").write_text("\n".join(rows) + "\n")
print("\n".join(rows))
