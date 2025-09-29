#!/usr/bin/env python3
"""
convert_monster_sprites.py

Scan PNGs in assets/monster_sprites/, detect background color from border pixels,
and produce transparent-background copies in assets/monster_sprites_transparent/.

This script is conservative: it writes new files to a separate folder so originals
are not overwritten. It uses Pillow (PIL).
"""
import os
from pathlib import Path
from collections import Counter

try:
    from PIL import Image
except Exception as e:
    print("Pillow is not installed. Install with: python -m pip install pillow")
    raise

SRC_DIR = Path("assets/monster_sprites")
OUT_DIR = Path("assets/monster_sprites_transparent")
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Tolerance (0-255). Pixels within squared distance tol*tol of bg color will be cleared.
TOLERANCE = 30
TOL2 = TOLERANCE * TOLERANCE


def color_dist2(c1, c2):
    return (c1[0]-c2[0])**2 + (c1[1]-c2[1])**2 + (c1[2]-c2[2])**2


def detect_background_color(img):
    # img is an RGBA or RGB Image
    w, h = img.size
    pixels = img.load()
    samples = []

    # sample border pixels (top/bottom rows and left/right cols)
    for x in range(w):
        r = pixels[x, 0]
        samples.append(r[:3] if len(r) > 3 else r)
        r = pixels[x, h-1]
        samples.append(r[:3] if len(r) > 3 else r)
    for y in range(h):
        r = pixels[0, y]
        samples.append(r[:3] if len(r) > 3 else r)
        r = pixels[w-1, y]
        samples.append(r[:3] if len(r) > 3 else r)

    # find the most common color among samples
    cnt = Counter(samples)
    most_common, _ = cnt.most_common(1)[0]
    return tuple(most_common)


def make_transparent(src_path: Path, out_path: Path):
    img = Image.open(src_path).convert("RGBA")
    w, h = img.size
    bg = detect_background_color(img)

    pixels = img.load()
    changed = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            if color_dist2((r, g, b), bg) <= TOL2:
                pixels[x, y] = (r, g, b, 0)
                changed += 1

    img.save(out_path, optimize=True)
    return changed


def main():
    pngs = sorted(SRC_DIR.glob("*.png"))
    if not pngs:
        print("No PNGs found in", SRC_DIR)
        return

    report = []
    for p in pngs:
        out = OUT_DIR / p.name
        try:
            changed = make_transparent(p, out)
            report.append((p.name, True, changed))
            print(f"Processed {p.name}: changed_pixels={changed} -> {out}")
        except Exception as e:
            report.append((p.name, False, str(e)))
            print(f"Failed {p.name}: {e}")

    # summary
    success = sum(1 for r in report if r[1])
    fail = len(report) - success
    print(f"\nSummary: {success} succeeded, {fail} failed. Output dir: {OUT_DIR}")


if __name__ == '__main__':
    main()
