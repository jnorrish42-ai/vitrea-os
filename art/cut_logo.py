#!/usr/bin/env python3
"""Cut the Vitrea glass-V logo out of its white background with soft anti-aliased edges.
Usage: cut_logo.py SOURCE.jpg OUT.png"""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

src, out = sys.argv[1], sys.argv[2]
a = np.asarray(Image.open(src).convert('RGB')).astype(np.float32)
d = (255 - a).max(axis=2)                       # distance from white
near_white = d < 14
# background = near-white region connected to the image border
lab, _ = ndimage.label(near_white)
border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
bg = np.isin(lab, list(border))
# alpha: solid inside, ramped by "distance from white" in a thin band at the outer edge
dist_to_bg = ndimage.distance_transform_edt(~bg)
alpha = np.where(bg, 0.0, 1.0)
band = (~bg) & (dist_to_bg <= 4)
alpha[band] = np.clip(d[band] / 110.0, 0, 1)
alpha[bg] = np.clip(d[bg] / 110.0, 0, 1) * (ndimage.distance_transform_edt(bg)[bg] <= 1.5)
# un-blend the white out of edge pixels so they don't leave a halo
am = np.maximum(alpha, 1e-3)[..., None]
rgb = np.clip((a - (1 - alpha[..., None]) * 255) / am, 0, 255)
rgba = np.dstack([rgb, alpha * 255]).astype(np.uint8)
im = Image.fromarray(rgba, 'RGBA')
bbox = im.getchannel('A').point(lambda v: 255 if v > 8 else 0).getbbox()
im = im.crop(bbox)
side = int(max(im.size) * 1.06)
canvas = Image.new('RGBA', (side, side), (0, 0, 0, 0))
canvas.paste(im, ((side - im.size[0]) // 2, (side - im.size[1]) // 2))
canvas.save(out)
print('wrote', out, canvas.size)
