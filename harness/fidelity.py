#!/usr/bin/env python3
"""SSIM of each app screenshot vs the spec reference (status bar and home-indicator rows cropped)."""
import json, sys, pathlib
import numpy as np
from PIL import Image, ImageFilter
from skimage.metrics import structural_similarity as ssim

TOP, BOTTOM = 62 * 3, 34 * 3


def load(p, size=None):
    im = Image.open(p).convert("L")
    if size and im.size != size:
        im = im.resize(size, Image.LANCZOS)
    a = np.asarray(im, dtype=np.float64)
    return a[TOP:a.shape[0] - BOTTOM]


def layout(a):
    """Blur + downscale 4x: keeps positions, sizes and colours, drops text anti-aliasing differences."""
    im = Image.fromarray(a.astype(np.uint8)).filter(ImageFilter.GaussianBlur(4))
    im = im.resize((im.width // 4, im.height // 4), Image.BILINEAR)
    return np.asarray(im, dtype=np.float64)


def main(screens, ref):
    out = {}
    for r in sorted(pathlib.Path(ref).glob("*.png")):
        s = pathlib.Path(screens) / r.name
        if not s.exists():
            out[r.stem] = None
            continue
        ra = load(r)
        sa = load(s, Image.open(r).size)
        out[r.stem] = {"ssim": round(float(ssim(ra, sa, data_range=255)), 4),
                       "layout_ssim": round(float(ssim(layout(ra), layout(sa), data_range=255)), 4),
                       "mean_abs_diff": round(float(np.abs(ra - sa).mean()), 2)}
    screens_ = [v for v in out.values()]
    n = len(screens_)  # missing screens score 0
    out["mean_ssim"] = round(sum(v["ssim"] for v in screens_ if v) / n, 4)
    out["mean_layout_ssim"] = round(sum(v["layout_ssim"] for v in screens_ if v) / n, 4)
    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
