#!/usr/bin/env python3
"""Vitrea Liquid wallpapers (original, procedurally generated):
  dusk  - a lone tree on a hill against a glowing rose sun at dusk; the wind strips its
          pale blossoms and carries them up across the sky
  neon  - the same tree as a silhouette rimmed in electric cyan, on a dark teal night
Usage: make_scenes.py OUTDIR    (writes OUTDIR/VitreaDusk and OUTDIR/VitreaNeon wallpaper packages)"""
import json, math, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_tree as T  # noqa: E402

W, H = T.W, T.H


def stars(img, rng, n, ymax, tint=(255, 255, 255)):
    st = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ds = ImageDraw.Draw(st)
    for _ in range(n):
        x, y = rng.uniform(0, W), rng.uniform(0, ymax)
        r = rng.choice([0.8, 1.0, 1.3, 1.8, 2.6], p=[0.42, 0.3, 0.16, 0.09, 0.03])
        ds.ellipse([x - r, y - r, x + r, y + r], fill=tint + (int(rng.uniform(70, 240)),))
    return Image.alpha_composite(img.convert('RGBA'), st)


def hill(img, color, rim, rim_alpha, peak_x, peak_y, light_dir):
    """Big foreground hill rising from the bottom-left to a rounded crest."""
    layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    xs = np.arange(-200, W + 200, 6)
    # asymmetric crest: long gentle slope to the right, steeper fall to the left
    left = peak_y + (peak_x - xs) ** 2 / (2 * (W * 0.20) ** 2) * 900
    right = peak_y + (xs - peak_x) ** 2 / (2 * (W * 0.42) ** 2) * 900
    ys = np.where(xs < peak_x, left, right)
    ys += 14 * np.sin(xs / 140.0) + 7 * np.sin(xs / 47.0)
    pts = [(int(x), int(y)) for x, y in zip(xs, ys)]
    d.polygon([(-200, H + 10)] + pts + [(W + 200, H + 10)], fill=color + (255,))
    # rim light along the crest facing the sun
    rl = Image.new('RGBA', img.size, (0, 0, 0, 0))
    dr = ImageDraw.Draw(rl)
    for (x1, y1), (x2, y2) in zip(pts, pts[1:]):
        fall = (x1 - peak_x) * light_dir
        a = rim_alpha * max(0.0, 1 - abs(fall) / (W * 0.5))
        if a > 2:
            dr.line([(x1, y1 + 2), (x2, y2 + 2)], fill=rim + (int(a),), width=5)
    out = Image.alpha_composite(img.convert('RGBA'), rl.filter(ImageFilter.GaussianBlur(6)))
    out = Image.alpha_composite(out, layer)
    # grass tufts on the crest
    g = Image.new('RGBA', img.size, (0, 0, 0, 0))
    dg = ImageDraw.Draw(g)
    rng = np.random.default_rng(5)
    for (x, y) in pts[::2]:
        for _ in range(3):
            h = rng.uniform(6, 22)
            lean = rng.uniform(-6, 6)
            dg.line([(x, y + 4), (x + lean, y + 4 - h)], fill=color + (255,), width=2)
    return Image.alpha_composite(out, g), np.interp


def wind_petals(img, rng, origin, n, cols, spread_to, scale=1.0, glow=None):
    """Blossoms torn off by the wind: dense at the canopy, thinning out along a rising arc."""
    layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
    gl = Image.new('RGBA', img.size, (0, 0, 0, 0))
    d, dg = ImageDraw.Draw(layer), ImageDraw.Draw(gl)
    ox, oy = origin
    tx, ty = spread_to
    for _ in range(n):
        t = rng.beta(1.2, 2.6)                       # most petals stay near the tree
        x = ox + (tx - ox) * t + rng.normal(0, 90 + 520 * t)
        y = oy + (ty - oy) * t - 260 * math.sin(t * math.pi) + rng.normal(0, 70 + 380 * t)
        r = rng.uniform(2.5, 10) * scale * (1.15 - 0.55 * t)
        ang = rng.uniform(0, math.pi)
        c = cols[rng.integers(len(cols))]
        a = int(rng.uniform(110, 235) * (1 - 0.45 * t))
        # a little rotated ellipse = a petal in flight
        w, h = r * 1.7, r
        pts = [(x + math.cos(ang) * w * math.cos(s) - math.sin(ang) * h * math.sin(s),
                y + math.sin(ang) * w * math.cos(s) + math.cos(ang) * h * math.sin(s)) for s in np.linspace(0, 2 * math.pi, 10)]
        d.polygon(pts, fill=c + (a,))
        if glow is not None and rng.random() < 0.35:
            g = r * 3
            dg.ellipse([x - g, y - g, x + g, y + g], fill=glow + (60,))
    out = img.convert('RGBA')
    if glow is not None:
        out = Image.alpha_composite(out, gl.filter(ImageFilter.GaussianBlur(10)))
    return Image.alpha_composite(out, layer.filter(ImageFilter.GaussianBlur(0.8)))


def dusk():
    rng = np.random.default_rng(31)
    sky = T.vgrad([(0, '#181a2a'), (0.30, '#24273d'), (0.52, '#383a55'), (0.66, '#5a5470'), (0.74, '#77708a'), (1, '#77708a')], H, W)
    sun = (int(W * 0.30), int(H * 0.60))
    sky += T.radial(*sun, 760, H, W)[..., None] * np.array([90, 30, 40], np.float32)
    sky += T.radial(*sun, 300, H, W)[..., None] * np.array([150, 70, 70], np.float32)
    img = T.to_img(sky).convert('RGBA')
    img = stars(img, rng, 900, H * 0.55)
    # small rose moon high up, like a second light
    m = Image.new('RGBA', img.size, (0, 0, 0, 0)); dm = ImageDraw.Draw(m)
    mx, my = int(W * 0.18), int(H * 0.30)
    dm.ellipse([mx - 120, my - 120, mx + 120, my + 120], fill=(255, 150, 140, 70))
    dm.ellipse([mx - 34, my - 34, mx + 34, my + 34], fill=(255, 196, 178, 255))
    img = Image.alpha_composite(img, m.filter(ImageFilter.GaussianBlur(10)))
    # the low sun: soft disc + bloom, partly behind the hill
    s = Image.new('RGBA', img.size, (0, 0, 0, 0)); dsun = ImageDraw.Draw(s)
    for r, a in ((430, 40), (300, 70), (220, 120)):
        dsun.ellipse([sun[0] - r, sun[1] - r, sun[0] + r, sun[1] + r], fill=(255, 128, 140, a))
    img = Image.alpha_composite(img, s.filter(ImageFilter.GaussianBlur(60)))
    sd = Image.new('RGBA', img.size, (0, 0, 0, 0)); ImageDraw.Draw(sd).ellipse([sun[0] - 210, sun[1] - 210, sun[0] + 210, sun[1] + 210], fill=(255, 168, 160, 235))
    img = Image.alpha_composite(img, sd.filter(ImageFilter.GaussianBlur(14)))
    # distant sea of mist
    for i, (c, a) in enumerate([('#4b4a66', 170), ('#3a3a55', 200)]):
        img = Image.alpha_composite(img, T.hills(rng, int(H * 0.69) + 40 * i, 50 + 40 * i, T.hexrgb(c), a, i * 2.1).filter(ImageFilter.GaussianBlur(10 - 4 * i)))
    peak = (int(W * 0.50), int(H * 0.645))
    img, _ = hill(img, T.hexrgb('#16172a'), T.hexrgb('#ff9aa8'), 120, peak[0], peak[1], -1)
    pal = dict(wood=T.hexrgb('#141526'), rim=T.hexrgb('#ffb2b8'),
               petals=[T.hexrgb(c) for c in ('#8e9bd0', '#b3bde8', '#6f7cb8', '#d8b3cf', '#9aa6dc', '#c6cff5')],
               petal_hi=T.hexrgb('#e9edff'), glow=T.hexrgb('#7d8fd8'))
    T.DRIFT_N = 120
    img = T.draw_tree(img, rng, peak[0] - 10, peak[1] + 8, 0.80, pal, -1, 0.40)
    img = wind_petals(img, rng, (peak[0] + 120, int(H * 0.44)), 2200, pal['petals'], (int(W * 0.98), int(H * 0.04)), 1.1)
    return T.finish(img, rng, 0.40)


def neon():
    rng = np.random.default_rng(44)
    sky = T.vgrad([(0, '#03080c'), (0.35, '#061218'), (0.6, '#0a2028'), (0.72, '#0d2a33'), (1, '#071419')], H, W)
    glow_c = (int(W * 0.66), int(H * 0.50))
    sky += T.radial(*glow_c, 900, H, W)[..., None] * np.array([0, 45, 55], np.float32)
    sky += T.radial(*glow_c, 260, H, W)[..., None] * np.array([10, 90, 105], np.float32)
    img = T.to_img(sky).convert('RGBA')
    img = stars(img, rng, 500, H * 0.6, (180, 255, 255))
    # neon ring (a moon outline) behind the tree
    ring = Image.new('RGBA', img.size, (0, 0, 0, 0)); dr = ImageDraw.Draw(ring)
    cx, cy, r = glow_c[0], glow_c[1] - 120, 380
    dr.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(80, 240, 255, 255), width=10)
    img = Image.alpha_composite(img, ring.filter(ImageFilter.GaussianBlur(26)))
    img = Image.alpha_composite(img, ring.filter(ImageFilter.GaussianBlur(3)))
    for i, (c, a) in enumerate([('#0b2730', 200), ('#081c23', 230)]):
        img = Image.alpha_composite(img, T.hills(rng, int(H * 0.72) + 50 * i, 70 + 50 * i, T.hexrgb(c), a, i * 1.3).filter(ImageFilter.GaussianBlur(6 - 2 * i)))
    peak = (int(W * 0.62), int(H * 0.675))
    img, _ = hill(img, T.hexrgb('#02080a'), T.hexrgb('#34e7ff'), 200, peak[0], peak[1], 1)
    pal = dict(wood=T.hexrgb('#020709'), rim=T.hexrgb('#5ff3ff'),
               petals=[T.hexrgb(c) for c in ('#22d3ee', '#06b6d4', '#67e8f9', '#0e7490', '#22d3ee', '#0891b2')],
               petal_hi=T.hexrgb('#a5f3fc'), glow=T.hexrgb('#20d8ff'))
    T.DRIFT_N = 80
    img = T.draw_tree(img, rng, peak[0], peak[1] + 8, 0.82, pal, 1, 0.9)
    img = wind_petals(img, rng, (peak[0] - 160, int(H * 0.42)), 1500, pal['petals'], (int(W * 0.04), int(H * 0.10)), 1.0,
                      glow=T.hexrgb('#20d8ff'))
    # cyan haze line on the horizon
    haze = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ImageDraw.Draw(haze).rectangle([0, int(H * 0.715), W, int(H * 0.73)], fill=(40, 220, 255, 60))
    img = Image.alpha_composite(img, haze.filter(ImageFilter.GaussianBlur(30)))
    return T.finish(img, rng, 0.45)


def save(im, out, pkg, name):
    d = os.path.join(out, pkg, 'contents', 'images')
    os.makedirs(d, exist_ok=True)
    im = im.convert('RGB')
    im.save(os.path.join(d, '3840x2160.png'), optimize=True)
    im.resize((2560, 1440), Image.LANCZOS).save(os.path.join(d, '2560x1440.png'), optimize=True)
    im.resize((1920, 1080), Image.LANCZOS).save(os.path.join(d, '1920x1080.png'), optimize=True)
    im.resize((640, 360), Image.LANCZOS).save(os.path.join(out, pkg, 'contents', 'screenshot.png'))
    json.dump({'KPlugin': {'Id': pkg, 'Name': name, 'Authors': [{'Name': 'Vitrea OS'}], 'License': 'CC-BY-SA-4.0'}},
              open(os.path.join(out, pkg, 'metadata.json'), 'w'), indent=2)
    print('wrote', pkg)


if __name__ == '__main__':
    out = sys.argv[1]
    which = sys.argv[2:] or ['dusk', 'neon']
    if 'dusk' in which:
        save(dusk(), out, 'VitreaDusk', 'Vitrea Dusk')
    if 'neon' in which:
        save(neon(), out, 'VitreaNeon', 'Vitrea Neon')
