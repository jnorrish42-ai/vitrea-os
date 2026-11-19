#!/usr/bin/env python3
"""Vitrea OS "Glass Blossom" wallpapers: a blossom tree on a small island, mirrored in a lake.
Light = dawn, Dark = moonlit night. Original, procedurally generated artwork.
Usage: make_tree.py OUTDIR   (writes images/ and images_dark/ like a Plasma wallpaper package)"""
import math, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

W, H = 3840, 2160
HORIZON = int(H * 0.665)


def hexrgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def vgrad(stops, h, w):
    """Vertical gradient from [(pos, '#hex'), ...]."""
    ys = np.linspace(0, 1, h)
    out = np.zeros((h, 3), np.float32)
    pos = [p for p, _ in stops]
    cols = np.array([hexrgb(c) for _, c in stops], np.float32)
    for ch in range(3):
        out[:, ch] = np.interp(ys, pos, cols[:, ch])
    return np.repeat(out[:, None, :], w, axis=1)


def radial(cx, cy, r, h, w):
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.sqrt((x - cx) ** 2 + (y - cy) ** 2) / r
    return np.exp(-d * d)


def to_img(a):
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def screen(base, layer, amount=1.0):
    b = np.asarray(base).astype(np.float32) / 255
    l = np.asarray(layer).astype(np.float32) / 255 * amount
    return to_img((1 - (1 - b) * (1 - l)) * 255)


def hills(rng, y_base, amp, color, alpha, seed_shift, w=W, h=H):
    """Soft distant hill silhouette as RGBA layer."""
    xs = np.arange(w)
    prof = np.zeros(w)
    for k, a in ((1.3, 1.0), (2.9, 0.45), (6.1, 0.2), (13.0, 0.08)):
        ph = rng.uniform(0, 6.28)
        prof += a * np.sin(xs / w * k * math.pi + ph + seed_shift)
    prof = y_base - amp * (prof - prof.min()) / (prof.max() - prof.min())
    layer = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    pts = [(0, h)] + [(int(x), int(prof[x])) for x in range(0, w, 8)] + [(w, h)]
    d.polygon(pts, fill=color + (alpha,))
    return layer


def build_tree(rng, x0, y0, scale):
    segs, tips = [], []

    def branch(x, y, ang, length, width, depth):
        x2 = x + math.cos(ang) * length
        y2 = y + math.sin(ang) * length
        segs.append((x, y, x2, y2, width))
        if depth == 0 or width < 1.6:
            tips.append((x2, y2, ang))
            return
        if depth <= 5:
            tips.append((x2, y2, ang))
        n = 3 if rng.random() < 0.35 else 2
        spread = rng.uniform(0.42, 0.72)
        for i in range(n):
            t = (i - (n - 1) / 2) / ((n - 1) / 2)
            a = ang + spread * t + rng.uniform(-0.16, 0.16)
            # umbrella crown: nudge limbs outward/sideways, gently droop the outer twigs
            a += 0.05 * math.copysign(1, math.cos(a)) * (1 if depth < 6 else 0.3)
            # keep limbs reaching up/out (no drooping hooks): angle within (-pi+0.25, -0.25)
            a = min(max(a, -math.pi + 0.25), -0.25)
            branch(x2, y2, a, length * rng.uniform(0.70, 0.84), width * rng.uniform(0.62, 0.72), depth - 1)

    trunk_len = 230 * scale
    segs.append((x0, y0, x0 + 6 * scale, y0 - trunk_len, 112 * scale))
    segs.append((x0 - 46 * scale, y0, x0 + 46 * scale, y0, 52 * scale))
    tx, ty = x0 + 6 * scale, y0 - trunk_len
    for a, l in ((-math.pi / 2 - 0.58, 250), (-math.pi / 2 - 0.08, 240), (-math.pi / 2 + 0.50, 255), (-math.pi / 2 + 0.15, 200)):
        branch(tx, ty, a, l * scale, 64 * scale, 8)
    return segs, tips


def draw_tree(base, rng, x0, y0, scale, pal, light_dir, glow_amt):
    segs, tips = build_tree(rng, x0, y0, scale)
    wood = Image.new('RGBA', base.size, (0, 0, 0, 0))
    dw = ImageDraw.Draw(wood)
    for (x1, y1, x2, y2, w) in segs:
        dw.line([(x1, y1), (x2, y2)], fill=pal['wood'] + (255,), width=max(1, int(w)))
        r = w / 2
        dw.ellipse([x2 - r, y2 - r, x2 + r, y2 + r], fill=pal['wood'] + (255,))
    # rim light on the sun-facing side of the wood
    rim = Image.new('RGBA', base.size, (0, 0, 0, 0))
    dr = ImageDraw.Draw(rim)
    for (x1, y1, x2, y2, w) in segs:
        if w < 3:
            continue
        off = w * 0.28
        dr.line([(x1 + off * light_dir, y1), (x2 + off * light_dir, y2)], fill=pal['rim'] + (55,),
                width=max(1, int(w * 0.14)))
    wood = Image.alpha_composite(wood, rim.filter(ImageFilter.GaussianBlur(2)))

    # glass blossoms: translucent discs + soft glow, lighter toward the light
    petals = Image.new('RGBA', base.size, (0, 0, 0, 0))
    glow = Image.new('RGBA', base.size, (0, 0, 0, 0))
    dp, dg = ImageDraw.Draw(petals), ImageDraw.Draw(glow)
    xs = [t[0] for t in tips]
    xmin, xmax = min(xs), max(xs)
    for (tx, ty, ang) in tips:
        n = rng.integers(7, 13)
        for _ in range(n):
            rr = rng.uniform(5, 21) * scale
            px = tx + rng.normal(0, 24 * scale)
            py = ty + rng.normal(0, 18 * scale)
            lit = (px - xmin) / max(1, (xmax - xmin))
            lit = lit if light_dir > 0 else 1 - lit
            c = pal['petals'][rng.integers(len(pal['petals']))]
            c = tuple(int(c[i] + (pal['petal_hi'][i] - c[i]) * lit * 0.55) for i in range(3))
            a = int(rng.uniform(70, 170))
            dp.ellipse([px - rr, py - rr, px + rr, py + rr], fill=c + (a,))
            # glassy highlight on some discs
            if rr > 14 * scale and rng.random() < 0.5:
                hr = rr * 0.35
                hx, hy = px - rr * 0.35 * light_dir * -1, py - rr * 0.35
                dp.ellipse([hx - hr, hy - hr, hx + hr, hy + hr], fill=(255, 255, 255, 70))
            g = rr * 2.2
            dg.ellipse([px - g, py - g, px + g, py + g], fill=pal['glow'] + (40,))
    glow = glow.filter(ImageFilter.GaussianBlur(38 * scale))
    soft = petals.filter(ImageFilter.GaussianBlur(9 * scale))
    petals = petals.filter(ImageFilter.GaussianBlur(1.6))

    out = screen(base.convert('RGB'), Image.alpha_composite(Image.new('RGBA', base.size, (0, 0, 0, 255)), glow).convert('RGB'), glow_amt)
    out = out.convert('RGBA')
    out = Image.alpha_composite(out, wood)
    out = Image.alpha_composite(out, soft)
    out = Image.alpha_composite(out, petals)

    # drifting petals to the lee side
    drift = Image.new('RGBA', base.size, (0, 0, 0, 0))
    dd = ImageDraw.Draw(drift)
    for _ in range(140):
        px = rng.uniform(xmin, xmax + 900 * scale * light_dir) if light_dir > 0 else rng.uniform(xmin - 900 * scale, xmax)
        py = rng.uniform(min(t[1] for t in tips), HORIZON - 20)
        rr = rng.uniform(3, 9) * scale
        c = pal['petals'][rng.integers(len(pal['petals']))]
        dd.ellipse([px - rr * 1.6, py - rr, px + rr * 1.6, py + rr], fill=c + (int(rng.uniform(90, 200)),))
    out = Image.alpha_composite(out, drift.filter(ImageFilter.GaussianBlur(1.2)))
    return out


def island(base, x_peak, color, rim, light_dir):
    layer = Image.new('RGBA', base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    pts = []
    for i in range(0, 241):
        t = i / 240
        x = x_peak - 900 + 1800 * t
        bump = math.exp(-((t - 0.5) / 0.23) ** 2)
        y = HORIZON + 6 - 120 * bump - 10 * math.sin(t * 23)
        pts.append((x, y))
    d.polygon(pts + [(x_peak + 900, HORIZON + 8), (x_peak - 900, HORIZON + 8)], fill=color + (255,))
    # rim light along the top edge
    edge = Image.new('RGBA', base.size, (0, 0, 0, 0))
    de = ImageDraw.Draw(edge)
    lit_pts = [p for p in pts if (p[0] - x_peak) * light_dir > -200]
    de.line(lit_pts, fill=rim + (150,), width=5)
    layer = Image.alpha_composite(layer, edge.filter(ImageFilter.GaussianBlur(3)))
    return Image.alpha_composite(base.convert('RGBA'), layer)


def reflect(img, tint, strength):
    """Mirror everything above the horizon into a rippled lake."""
    above = img.crop((0, 0, W, HORIZON)).transpose(Image.FLIP_TOP_BOTTOM)
    hgt = H - HORIZON
    refl = np.asarray(above.resize((W, int(HORIZON * 0.92)))).astype(np.float32)[:hgt]
    out = np.empty_like(refl)
    rows = np.arange(hgt)
    for y in rows:
        k = y / hgt
        amp = 1 + 9 * k ** 1.5
        shift = int(round(amp * math.sin(y * 0.13 + 2.2 * math.sin(y * 0.017))))
        out[y] = np.roll(refl[y], shift, axis=0)
    out = to_img(out).filter(ImageFilter.GaussianBlur(2.2))
    out = np.asarray(out).astype(np.float32)
    t = np.array(tint, np.float32)
    fade = (rows / hgt)[:, None, None]
    out = out * (1 - strength - 0.25 * fade) + t * (strength + 0.25 * fade)
    # horizontal shimmer lines
    rng = np.random.default_rng(3)
    for _ in range(260):
        y = int(rng.uniform(4, hgt - 2))
        x = int(rng.uniform(0, W)); ln = int(rng.uniform(40, 420))
        out[y:y + 2, x:x + ln] += 18 * (1 - y / hgt)
    lake = to_img(out)
    res = img.copy()
    res.paste(lake, (0, HORIZON))
    return res


def finish(img, rng, vignette=0.35):
    a = np.asarray(img.convert('RGB')).astype(np.float32)
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    v = 1 - vignette * (((x / W - 0.5) ** 2 + (y / H - 0.5) ** 2) / 0.5) ** 1.4
    a *= v[..., None]
    a += rng.normal(0, 2.0, a.shape)
    return to_img(a)


def bokeh(img, rng, n, cols, rmin, rmax, alpha, ymax):
    layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(n):
        r = rng.uniform(rmin, rmax)
        x, y = rng.uniform(0, W), rng.uniform(0, ymax)
        c = cols[rng.integers(len(cols))]
        d.ellipse([x - r, y - r, x + r, y + r], fill=c + (int(alpha * rng.uniform(0.4, 1)),))
    return Image.alpha_composite(img.convert('RGBA'), layer.filter(ImageFilter.GaussianBlur(rmin * 0.6)))


def scene(dark):
    rng = np.random.default_rng(21 if dark else 7)
    if not dark:
        sky = vgrad([(0, '#4d7be0'), (0.30, '#8fa8f2'), (0.52, '#d6c3f2'), (0.63, '#ffd3c4'), (0.665, '#ffe6cf'), (1, '#ffe6cf')], H, W)
        sun = (int(W * 0.70), int(HORIZON - 70))
        sky += radial(*sun, 520, H, W)[..., None] * np.array([90, 60, 20], np.float32)
        sky += radial(*sun, 120, H, W)[..., None] * np.array([120, 110, 80], np.float32)
        pal = dict(wood=hexrgb('#3b2a3f'), rim=hexrgb('#ffd9b0'),
                   petals=[hexrgb(c) for c in ('#ffc2dd', '#ff9fca', '#f68dbd', '#ffd9ea', '#e9a6ff', '#ffb4c8')],
                   petal_hi=hexrgb('#fff3e6'), glow=hexrgb('#ffb3d6'))
        hill_cols = [('#9b8fd6', 150), ('#7f72c4', 190), ('#6a5fae', 220)]
        island_col, island_rim, lake_tint, glow_amt, light_dir = hexrgb('#4a3554'), hexrgb('#ffcfae'), (120, 130, 200), 0.85, 1
    else:
        sky = vgrad([(0, '#050816'), (0.35, '#101a44'), (0.55, '#2a1f5e'), (0.665, '#4b2c74'), (1, '#4b2c74')], H, W)
        moon = (int(W * 0.74), int(H * 0.22))
        sky += radial(*moon, 700, H, W)[..., None] * np.array([40, 50, 90], np.float32)
        sky += radial(*moon, 150, H, W)[..., None] * np.array([60, 70, 100], np.float32)
        pal = dict(wood=hexrgb('#140f22'), rim=hexrgb('#9fb6ff'),
                   petals=[hexrgb(c) for c in ('#ff8fd0', '#d77bff', '#ff6fb5', '#b98cff', '#ffa6e0', '#e3a0ff')],
                   petal_hi=hexrgb('#e8f0ff'), glow=hexrgb('#d68bff'))
        hill_cols = [('#2c2a6e', 170), ('#221f55', 210), ('#1a1742', 235)]
        island_col, island_rim, lake_tint, glow_amt, light_dir = hexrgb('#120d22'), hexrgb('#a9b8ff'), (20, 22, 60), 1.0, 1
    img = to_img(sky).convert('RGBA')
    if dark:
        st = Image.new('RGBA', img.size, (0, 0, 0, 0)); ds = ImageDraw.Draw(st)
        for _ in range(1600):
            x, y = rng.uniform(0, W), rng.uniform(0, HORIZON * 0.85)
            r = rng.choice([0.8, 1.0, 1.3, 1.8, 2.6], p=[0.4, 0.3, 0.17, 0.1, 0.03])
            ds.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, int(rng.uniform(80, 255))))
        img = Image.alpha_composite(img, st)
        m = Image.new('RGBA', img.size, (0, 0, 0, 0)); dm = ImageDraw.Draw(m)
        mx, my = int(W * 0.74), int(H * 0.22)
        dm.ellipse([mx - 78, my - 78, mx + 78, my + 78], fill=(246, 244, 255, 255))
        img = Image.alpha_composite(img, m.filter(ImageFilter.GaussianBlur(1.5)))
    for i, (c, a) in enumerate(hill_cols):
        img = Image.alpha_composite(img, hills(rng, HORIZON + 4, 120 + 70 * i, hexrgb(c), a, i * 1.7).filter(ImageFilter.GaussianBlur(4 - i)))
    img = bokeh(img, rng, 70, pal['petals'], 18, 60, 60 if not dark else 80, HORIZON)
    x_peak = int(W * 0.36)
    img = island(img, x_peak, island_col, island_rim, light_dir)
    img = draw_tree(img, rng, x_peak, HORIZON - 104, 0.95, pal, light_dir, glow_amt)
    img = reflect(img.convert('RGB'), lake_tint, 0.30 if not dark else 0.40)
    if dark:
        img = bokeh(img, rng, 120, [hexrgb('#ffe9a8'), hexrgb('#c8ffda')], 3, 7, 230, H)  # fireflies
    return finish(img, rng, 0.28 if not dark else 0.42)


if __name__ == '__main__':
    out = sys.argv[1]
    for dark in (False, True):
        im = scene(dark)
        d = os.path.join(out, 'images_dark' if dark else 'images')
        os.makedirs(d, exist_ok=True)
        im.save(os.path.join(d, '3840x2160.png'), optimize=True)
        im.resize((2560, 1440), Image.LANCZOS).save(os.path.join(d, '2560x1440.png'), optimize=True)
        im.resize((1920, 1080), Image.LANCZOS).save(os.path.join(d, '1920x1080.png'), optimize=True)
        if not dark:
            im.resize((640, 360), Image.LANCZOS).save(os.path.join(out, 'screenshot.png'))
        print('wrote', d)
