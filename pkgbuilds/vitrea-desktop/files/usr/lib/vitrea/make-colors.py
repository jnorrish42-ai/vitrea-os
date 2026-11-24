#!/usr/bin/env python3
"""Vitrea Dark / Vitrea Light colour schemes: KDE's Breeze schemes with the blue tint taken
out of every background and text colour, so the desktop is neutral grey and the only colour
is the accent (which Vitrea takes from the wallpaper). Re-run safely at any time."""
import colorsys, configparser, io, os, re, sys

SRC = '/usr/share/color-schemes'
KEEP = re.compile(r'^(DecorationFocus|DecorationHover|ForegroundActive|ForegroundLink|ForegroundVisited|'
                  r'ForegroundNegative|ForegroundNeutral|ForegroundPositive|BackgroundNegative|'
                  r'BackgroundNeutral|BackgroundPositive)$')


def grey(value, lift=0.0):
    parts = [p.strip() for p in value.split(',')]
    r, g, b = (int(x) / 255 for x in parts[:3])
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    l = min(1.0, max(0.0, l + lift))
    r, g, b = colorsys.hls_to_rgb(h, l, 0.0)
    out = [str(round(x * 255)) for x in (r, g, b)] + parts[3:]
    return ','.join(out)


def make(variant):
    src = os.path.join(SRC, f'Breeze{variant}.colors')
    if not os.path.exists(src):
        return
    cp = configparser.RawConfigParser(strict=False)
    cp.optionxform = str
    cp.read(src)
    for sec in cp.sections():
        if sec == 'Colors:Selection':       # the accent lives here
            continue
        for key, val in cp.items(sec):
            if KEEP.match(key) or not re.match(r'^\d+,\d+,\d+(,\d+)?$', val.strip()):
                continue
            cp.set(sec, key, grey(val, -0.02 if variant == 'Dark' and key.startswith('Background') else 0.0))
    cp.set('General', 'Name', f'Vitrea {variant}')
    if cp.has_section('KDE'):
        cp.set('KDE', 'contrast', '4')
    buf = io.StringIO()
    cp.write(buf, space_around_delimiters=False)
    with open(os.path.join(SRC, f'Vitrea{variant}.colors'), 'w') as f:
        f.write(buf.getvalue())


for v in ('Dark', 'Light'):
    make(v)
