#!/usr/bin/env python3
"""Cut Yumeka Kuroha's poses out of her character sheet (4 x 3 grid, lavender background)
into transparent PNG sprites.  Usage: cut_yumeka.py SHEET.jpg OUT_DIR"""
import os, sys
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

POSES = {  # (row, col) -> name; the sitting/lying poses are left out
    (0, 0): 'idle', (0, 1): 'peace', (0, 2): 'lookup', (0, 3): 'pout',
    (1, 2): 'surprised', (1, 3): 'heart',
    (2, 0): 'cheer', (2, 1): 'sleepy', (2, 3): 'curious',
}
ROWS = [(6, 421), (434, 810), (822, 1248)]
COLS = [(6, 310), (320, 624), (634, 937), (947, 1249)]

sheet = Image.open(sys.argv[1]).convert('RGB')
out = sys.argv[2]
os.makedirs(out, exist_ok=True)
for (r, c), name in POSES.items():
    (y0, y1), (x0, x1) = ROWS[r], COLS[c]
    cell = np.asarray(sheet.crop((x0, y0, x1, y1))).astype(np.float32)
    h, w, _ = cell.shape
    # background colour: median of the cell's outer frame
    frame = np.concatenate([cell[:4].reshape(-1, 3), cell[-4:].reshape(-1, 3), cell[:, :4].reshape(-1, 3), cell[:, -4:].reshape(-1, 3)])
    bg = np.median(frame, axis=0)
    dist = np.abs(cell - bg).max(axis=2)
    # the soft floor shadow is a desaturated lavender a bit darker than the paper
    sat = cell.max(axis=2) - cell.min(axis=2)
    lum = cell.mean(axis=2)
    shadowish = (sat < 40) & (lum > 150) & (lum < bg.mean() - 4) & (cell[..., 2] >= cell[..., 0])
    shadowish[: int(h * 0.75)] = False
    cand = (dist < 16) | shadowish
    lab, _ = ndimage.label(cand)
    edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    shadow_lab = set(np.unique(lab[shadowish])) - {0}
    bgmask = np.isin(lab, list(edge | shadow_lab))
    # enclosed paper islands (between hair strands, arms and body) are background too
    islands = (dist < 14) & ~bgmask
    il, n = ndimage.label(islands)
    if n:
        sizes = ndimage.sum(islands, il, range(1, n + 1))
        for i, s in enumerate(sizes, 1):
            if s > 25:
                bgmask |= il == i
    # thin paper slivers between hair strands: bright, colourless, paper-like pixels
    paperish = (dist < 34) & (sat < 22) & (lum > 200) & ~bgmask
    pl, n = ndimage.label(paperish)
    if n:
        sizes = ndimage.sum(paperish, pl, range(1, n + 1))
        for i, s in enumerate(sizes, 1):
            if s > 6:          # keep tiny specks (eye highlights)
                bgmask |= pl == i
    # leftover grid-border lines at the cell edges
    m = 7
    bgmask[:, :m] = True; bgmask[:, -m:] = True; bgmask[:m] = True; bgmask[-m:] = True
    # alpha: solid inside; in a 3px band at the edge, by how far the colour is from the paper
    d_bg = ndimage.distance_transform_edt(~bgmask)
    alpha = np.where(bgmask, 0.0, 1.0)
    band = (~bgmask) & (d_bg <= 3)
    alpha[band] = np.clip(dist[band] / 55.0, 0, 1)
    # un-blend the paper out of the edge pixels so no pale halo is left on dark desktops
    am = np.maximum(alpha, 1e-3)[..., None]
    cell = np.clip((cell - (1 - alpha[..., None]) * bg) / am, 0, 255)
    alpha[alpha < 0.08] = 0
    rgba = np.dstack([cell, alpha * 255]).astype(np.uint8)
    im = Image.fromarray(rgba, 'RGBA')
    bbox = im.getchannel('A').point(lambda v: 255 if v > 20 else 0).getbbox()
    im = im.crop(bbox)
    im.save(os.path.join(out, f'{name}.png'), optimize=True)
    print(name, im.size)
