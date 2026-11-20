#!/usr/bin/env python3
"""Image assets for the "Vitrea Liquid" Plymouth boot splash (script module).
Usage: make_splash.py THEME_DIR"""
import math, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
out = sys.argv[1]
os.makedirs(out, exist_ok=True)
logo = Image.open(os.path.join(HERE, 'logo', 'vitrea-v.png')).convert('RGBA')


def save(im, name):
    im.save(os.path.join(out, name), optimize=True)


def radial(size, rgb, power=2.2, alpha=255):
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    c = (size - 1) / 2
    d = np.sqrt((x - c) ** 2 + (y - c) ** 2) / c
    a = np.clip(1 - d, 0, 1) ** power * alpha
    arr = np.zeros((size, size, 4), np.uint8)
    arr[..., :3] = rgb
    arr[..., 3] = a.astype(np.uint8)
    return Image.fromarray(arr, 'RGBA')


def rounded(w, h, r, fill, outline=None, width=1):
    im = Image.new('RGBA', (w * 4, h * 4), (0, 0, 0, 0))
    ImageDraw.Draw(im).rounded_rectangle([0, 0, w * 4 - 1, h * 4 - 1], r * 4, fill=fill,
                                         outline=outline, width=width * 4)
    return im.resize((w, h), Image.LANCZOS)


# logo at two sizes (HiDPI screens get the big one)
for px in (160, 240):
    save(logo.resize((px, px), Image.LANCZOS), f'logo-{px}.png')
# halo behind the logo: lilac core, blue fringe
halo = Image.alpha_composite(radial(520, (130, 100, 255), 2.4, 150), radial(520, (205, 160, 255), 5.0, 120))
save(halo, 'halo.png')
# orbit dot (soft, bright core)
dot = Image.alpha_composite(radial(28, (190, 170, 255), 1.6, 200), radial(28, (255, 255, 255), 6.0, 255))
save(dot, 'dot.png')
# drifting petals: three soft ellipses in the Vitrea palette
for i, rgb in enumerate([(203, 166, 247), (180, 190, 254), (245, 194, 231)]):
    p = Image.new('RGBA', (40, 40), rgb + (0,))   # transparent *petal colour*, so the blur adds no dark rim
    d = ImageDraw.Draw(p)
    d.ellipse([6, 13, 34, 27], fill=rgb + (230,))
    p = p.rotate(30 * i - 20, resample=Image.BICUBIC, fillcolor=rgb + (0,))
    a = p.getchannel('A').filter(ImageFilter.GaussianBlur(1.2))
    p = Image.merge('RGBA', (*Image.new('RGB', p.size, rgb).split(), a))
    hl = Image.new('L', p.size, 0); ImageDraw.Draw(hl).ellipse([13, 15, 22, 20], fill=120)
    p = Image.composite(Image.new('RGBA', p.size, (255, 255, 255, 255)), p, hl.filter(ImageFilter.GaussianBlur(1.5)))
    p.putalpha(a)
    save(p, f'petal{i}.png')
# glass progress bar: track + gradient fill (stretched by the script)
save(rounded(320, 8, 4, (255, 255, 255, 36), (255, 255, 255, 70)), 'track.png')
fill = Image.new('RGBA', (320, 8))
for x in range(320):
    t = x / 319
    c = (int(203 + (137 - 203) * t), int(166 + (180 - 166) * t), int(247 + (250 - 247) * t))
    ImageDraw.Draw(fill).line([(x, 0), (x, 7)], fill=c + (255,))
mask = rounded(320, 8, 4, (255, 255, 255, 255)).getchannel('A')
fill.putalpha(mask)
save(fill, 'fill.png')
# password field (glass), bullet and lock
save(rounded(360, 52, 16, (255, 255, 255, 30), (255, 255, 255, 90), 1), 'entry.png')
save(radial(14, (255, 255, 255), 0.6, 255), 'bullet.png')
lock = Image.new('RGBA', (96, 96), (0, 0, 0, 0)); dl = ImageDraw.Draw(lock)
dl.rounded_rectangle([18, 42, 78, 88], 10, fill=(225, 220, 255, 235))
dl.arc([28, 10, 68, 60], 180, 360, fill=(225, 220, 255, 235), width=8)
dl.line([(28, 35), (28, 46)], fill=(225, 220, 255, 235), width=8); dl.line([(67, 35), (67, 46)], fill=(225, 220, 255, 235), width=8)
dl.ellipse([42, 56, 54, 68], fill=(60, 50, 110, 255))
save(lock.resize((32, 32), Image.LANCZOS), 'lock.png')
print('splash assets written to', out)
