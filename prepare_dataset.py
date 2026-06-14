"""
prepare_dataset.py

Processes a folder of masked images into a YOLO-ready dataset.

Expected input structure:
    input_dir/
        <name>_OG.png    original image
        <name>_RED.png   mask: visible portion of object (red pixels)
        <name>_BLUE.png  mask: full object extent (blue pixels)

Output structure:
    output_dir/
        images/   original images
        labels/   YOLO .txt labels (empty or with bounding box)

Visibility = red_area / blue_area
    < 20%   → copy image + empty label  (object not present)
    20-60%  → skip                      (ambiguous, not used)
    > 60%   → copy image + YOLO label   (bounding box from RED mask)
"""

import os
import shutil
import numpy as np
from pathlib import Path
from PIL import Image


# ── Configuration ─────────────────────────────────────────────────────────────

INPUT_DIR  = Path("input")       # folder with OG / RED / BLUE images
OUTPUT_DIR = Path("output")      # destination

VISIBILITY_LOW  = 0.20           # below → empty label
VISIBILITY_HIGH = 0.60           # above → yolo label  (between → skip)

YOLO_CLASS = 0

# ── Helpers ───────────────────────────────────────────────────────────────────

def red_pixels(img_array: np.ndarray) -> np.ndarray:
    """Boolean mask of pixels that are 'red' in an RGB image."""
    r, g, b = img_array[..., 0], img_array[..., 1], img_array[..., 2]
    return (r > 127) & (g < 80) & (b < 80)


def blue_pixels(img_array: np.ndarray) -> np.ndarray:
    """Boolean mask of pixels that are 'blue' in an RGB image."""
    r, g, b = img_array[..., 0], img_array[..., 1], img_array[..., 2]
    return (b > 127) & (r < 80) & (g < 80)


def bounding_box_yolo(mask: np.ndarray, img_h: int, img_w: int) -> tuple:
    """
    Returns YOLO-format bounding box (x_center, y_center, width, height)
    normalised to [0, 1] from a boolean pixel mask.
    """
    rows = np.any(mask, axis=1)
    cols = np.any(mask, axis=0)
    y_min, y_max = np.where(rows)[0][[0, -1]]
    x_min, x_max = np.where(cols)[0][[0, -1]]

    x_center = ((x_min + x_max) / 2) / img_w
    y_center = ((y_min + y_max) / 2) / img_h
    width    = (x_max - x_min) / img_w
    height   = (y_max - y_min) / img_h

    return x_center, y_center, width, height


def ensure_dirs(output: Path):
    (output / "images").mkdir(parents=True, exist_ok=True)
    (output / "labels").mkdir(parents=True, exist_ok=True)


# ── Main ──────────────────────────────────────────────────────────────────────

def process(input_dir: Path, output_dir: Path):
    ensure_dirs(output_dir)

    og_files = sorted(input_dir.glob("*_OG.png"))

    if not og_files:
        print(f"No *_OG.png files found in {input_dir}")
        return

    stats = {"copied_empty": 0, "copied_label": 0, "skipped": 0, "errors": 0}

    for og_path in og_files:
        stem = og_path.stem[: -len("_OG")]          # strip trailing _OG
        red_path  = input_dir / f"{stem}_RED.png"
        blue_path = input_dir / f"{stem}_BLUE.png"

        # ── Validate all three files exist ────────────────────────────────────
        missing = [p for p in (red_path, blue_path) if not p.exists()]
        if missing:
            print(f"[WARN] {stem}: missing {[p.name for p in missing]}, skipping.")
            stats["errors"] += 1
            continue

        # ── Load masks ────────────────────────────────────────────────────────
        try:
            og_img   = Image.open(og_path).convert("RGB")
            red_img  = Image.open(red_path).convert("RGB")
            blue_img = Image.open(blue_path).convert("RGB")
        except Exception as e:
            print(f"[ERROR] {stem}: {e}")
            stats["errors"] += 1
            continue

        img_h, img_w = og_img.size[1], og_img.size[0]

        red_arr  = np.array(red_img)
        blue_arr = np.array(blue_img)

        red_mask  = red_pixels(red_arr)
        blue_mask = blue_pixels(blue_arr)

        red_area  = int(red_mask.sum())
        blue_area = int(blue_mask.sum())

        # ── Visibility ────────────────────────────────────────────────────────
        if blue_area == 0:
            # No object in blue mask at all → treat as not present
            visibility = 0.0
        else:
            visibility = red_area / blue_area

        dest_image = output_dir / "images" / og_path.name
        dest_label = output_dir / "labels" / f"{stem}_OG.txt"

        # ── Routing logic ─────────────────────────────────────────────────────
        if visibility < VISIBILITY_LOW:
            # Object not meaningfully visible → copy with empty label
            shutil.copy2(og_path, dest_image)
            dest_label.write_text("")
            stats["copied_empty"] += 1
            print(f"[EMPTY ] {stem}  vis={visibility:.2%}  red={red_area}px  blue={blue_area}px")

        elif visibility > VISIBILITY_HIGH:
            # Object clearly visible → copy with YOLO bounding box from RED mask
            if red_mask.sum() == 0:
                print(f"[WARN] {stem}: visibility={visibility:.2%} but red mask is empty, skipping.")
                stats["errors"] += 1
                continue

            x_c, y_c, w, h = bounding_box_yolo(red_mask, img_h, img_w)
            shutil.copy2(og_path, dest_image)
            dest_label.write_text(f"{YOLO_CLASS} {x_c:.6f} {y_c:.6f} {w:.6f} {h:.6f}\n")
            stats["copied_label"] += 1
            print(f"[LABEL ] {stem}  vis={visibility:.2%}  bbox=({x_c:.3f},{y_c:.3f},{w:.3f},{h:.3f})")

        else:
            # Ambiguous visibility → skip
            stats["skipped"] += 1
            print(f"[SKIP  ] {stem}  vis={visibility:.2%}  (between {VISIBILITY_LOW:.0%}–{VISIBILITY_HIGH:.0%})")

    # ── Summary ───────────────────────────────────────────────────────────────
    total     = sum(stats.values())
    processed = total - stats["errors"]

    def bar(count, width=40) -> str:
        filled = round((count / total) * width) if total else 0
        return "█" * filled + "░" * (width - filled)

    def pct(count) -> str:
        return f"{count / total * 100:5.1f}%" if total else "  0.0%"

    print(f"""
╔══════════════════════════════════════════════════════╗
║           Dataset Distribution — {total:>4} triplets        ║
╠══════════════════════════════════════════════════════╣
║  Class 0  (vis > {VISIBILITY_HIGH:.0%})  {bar(stats['copied_label'])}  {pct(stats['copied_label'])}  ({stats['copied_label']})
║  Empty    (vis < {VISIBILITY_LOW:.0%})  {bar(stats['copied_empty'])}  {pct(stats['copied_empty'])}  ({stats['copied_empty']})
║  Ignored  ({VISIBILITY_LOW:.0%}–{VISIBILITY_HIGH:.0%})    {bar(stats['skipped'])}  {pct(stats['skipped'])}  ({stats['skipped']})
║  Errors               {bar(stats['errors'])}  {pct(stats['errors'])}  ({stats['errors']})
╠══════════════════════════════════════════════════════╣
║  Copied to output: {stats['copied_label'] + stats['copied_empty']:>4}  │  Discarded: {stats['skipped']:>4}  │  Errors: {stats['errors']:>3}  ║
╚══════════════════════════════════════════════════════╝""")


if __name__ == "__main__":
    process(INPUT_DIR, OUTPUT_DIR)
