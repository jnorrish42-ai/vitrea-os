#!/usr/bin/env python3
"""Generate Vitrea OS artwork: liquid-glass wallpapers (light + dark).

All artwork is original and procedurally generated.
Usage: make_art.py OUTPUT_DIR
"""
import sys, os
import numpy as np
from PIL import Image, ImageFilter

W, H = 3840, 2160
S = 4  # render at 1/S resolution then upscale (keeps it smooth and fast)
w, h = W // S, H // S

def hexrgb(h):
    h = h.lstrip('#')
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32) / 255.0

def liquid(bg, blobs, ribbons, seed):
    rng = np.random.default_rng(seed)
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    x /= w; y /= h
    # domain warp for a "liquid" flow
    wx = x + 0.06 * np.sin(6.0 * y + 1.3) + 0.03 * np.sin(13.0 * y + 4.0 * x)
    wy = y + 0.06 * np.sin(5.0 * x + 0.7) + 0.03 * np.sin(11.0 * x - 3.0 * y)
    img = np.ones((h, w, 3), np.float32) * hexrgb(bg)
    for (cx, cy, r, col, a) in blobs:
        d2 = ((wx - cx) * 1.78) ** 2 + (wy - cy) ** 2
        m = np.exp(-d2 / (2 * r * r))[..., None] * a
        img = img * (1 - m) + hexrgb(col) * m
    # glossy flowing ribbons (bright edges like refracted light)
    for (phase, amp, freq, yoff, width, col, a) in ribbons:
        curve = yoff + amp * np.sin(freq * wx * np.pi + phase) + 0.04 * np.sin(3.1 * wx * np.pi + phase * 2)
        d = (wy - curve) / width
        band = np.exp(-d * d)
        edge = np.exp(-((d - 0.9) ** 2) * 18) * 0.6   # bright specular rim
        m = np.clip(band * a + edge * a * 0.8, 0, 1)[..., None]
        img = img * (1 - m) + hexrgb(col) * m
        img += edge[..., None] * 0.10
    img = np.clip(img, 0, 1)
    im = Image.fromarray((img * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(3))
    im = im.resize((W, H), Image.BICUBIC)
    # fine grain to avoid banding
    arr = np.asarray(im).astype(np.float32)
    arr += rng.normal(0, 1.6, arr.shape)
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))

LIGHT = dict(
    bg='#dfe9ff',
    blobs=[(0.15, 0.20, 0.30, '#9cc4ff', 0.9), (0.85, 0.15, 0.28, '#f6c1ff', 0.85),
           (0.70, 0.85, 0.32, '#a8f0ff', 0.85), (0.20, 0.90, 0.26, '#c7b6ff', 0.8),
           (0.50, 0.50, 0.22, '#ffffff', 0.55)],
    ribbons=[(0.4, 0.16, 1.2, 0.55, 0.10, '#6aa3ff', 0.55),
             (2.1, 0.12, 1.6, 0.38, 0.07, '#c58cff', 0.45),
             (4.0, 0.10, 1.0, 0.72, 0.06, '#7fe3ff', 0.45)],
    seed=7)

DARK = dict(
    bg='#0a0f24',
    blobs=[(0.15, 0.25, 0.30, '#1d3fa8', 0.9), (0.85, 0.20, 0.27, '#5b1f8f', 0.85),
           (0.70, 0.85, 0.30, '#0d6b8a', 0.8), (0.25, 0.85, 0.24, '#3a2a8f', 0.8)],
    ribbons=[(0.4, 0.16, 1.2, 0.55, 0.10, '#3b7bff', 0.55),
             (2.1, 0.12, 1.6, 0.38, 0.07, '#a04dff', 0.45),
             (4.0, 0.10, 1.0, 0.72, 0.06, '#2fd0ff', 0.40)],
    seed=11)

if __name__ == '__main__':
    out = sys.argv[1]
    for name, spec in (('light', LIGHT), ('dark', DARK)):
        im = liquid(**spec)
        d = os.path.join(out, 'images' if name == 'light' else 'images_dark')
        os.makedirs(d, exist_ok=True)
        im.save(os.path.join(d, '3840x2160.png'), optimize=True)
        im.resize((1920, 1080), Image.LANCZOS).save(os.path.join(d, '1920x1080.png'), optimize=True)
        im.resize((640, 360), Image.LANCZOS).save(os.path.join(out, f'screenshot-{name}.png'))
    print('ok')
