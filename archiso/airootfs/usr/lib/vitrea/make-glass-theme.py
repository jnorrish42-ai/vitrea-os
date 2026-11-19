#!/usr/bin/env python3
"""Turn Plasma's default (Breeze) theme into Vitrea's Liquid Glass, in place.

Liquid-glass look: a nearly clear tint, a glossy sheen that is strongest at the top,
and a bright specular rim along the edges. Only the translucent panel/dialog/tooltip
frames are rewritten. Idempotent; a pacman hook re-runs it whenever Plasma updates them.
Usage: make-glass-theme.py [THEME_DIR]   (default: /usr/share/plasma/desktoptheme/default)
"""
import gzip, os, re, sys

THEME = sys.argv[1] if len(sys.argv) > 1 else '/usr/share/plasma/desktoptheme/default'
MARK = 'vitrea-glass-defs-night'

# tint = Breeze background colour opacity; gloss = white sheen top->bottom; rim = specular edge
STYLES = {
    'translucent/widgets/panel-background.svgz': dict(tint=0.80, gloss=(0.03, 0.0), rim=(0.14, 0.07, 0.05)),
    'translucent/dialogs/background.svgz':       dict(tint=0.90, gloss=(0.02, 0.0), rim=(0.12, 0.06, 0.04)),
    'translucent/widgets/tooltip.svgz':          dict(tint=0.94, gloss=(0.02, 0.0), rim=(0.12, 0.06, 0.04)),
    'translucent/widgets/background.svgz':       dict(tint=0.85, gloss=(0.02, 0.0), rim=(0.12, 0.06, 0.04)),
}
BG = 'class="ColorScheme-Background"'


def groups(st):
    t, (g_top, g_bot), (r_top, r_side, r_bot) = st['tint'], st['gloss'], st['rim']
    # Qt SVG (used by Plasma) needs opacity/fill inside style="", like Breeze does
    body = lambda shape: shape.replace('/>', f'{BG} style="fill:currentColor;opacity:{t}"/>')
    white = lambda shape, op: shape.replace('/>', f'style="fill:#ffffff;fill-opacity:{op}"/>')
    grad = lambda shape, gid: shape.replace('/>', f'style="fill:url(#{gid})"/>')
    rect = lambda w, h, x=0, y=0: f'<rect x="{x}" y="{y}" width="{w}" height="{h}" />'
    tl, tr = '<path d="M 0,6 H 6 V 0 C 2,0 0,2 0,6 Z" />', '<path d="M 0,0 V 6 H 6 C 6,2 4,0 0,0 Z" />'
    bl, br = '<path d="M 6,6 V 0 H 0 c 0,4 2,6 6,6 z" />', '<path d="M 0,6 V 0 H 6 C 6,4 4,6 0,6 Z" />'
    arc = lambda d, op: f'<path d="{d}" style="fill:none;stroke:#ffffff;stroke-width:1;stroke-opacity:{op}" />'
    return {
        'center': body(rect(32, 32)) + grad(rect(32, 32), 'vg-gloss'),
        'top': body(rect(32, 6)) + white(rect(32, 6), g_top) + white(rect(32, 1), r_top),
        'bottom': body(rect(32, 6)) + white(rect(32, 6), g_bot) + white(rect(32, 1, 0, 5), r_bot),
        'left': body(rect(6, 32)) + grad(rect(6, 32), 'vg-gloss') + grad(rect(1, 32), 'vg-rim'),
        'right': body(rect(6, 32)) + grad(rect(6, 32), 'vg-gloss') + grad(rect(1, 32, 5), 'vg-rim'),
        'topleft': body(tl) + white(tl, g_top) + arc('M 0.5,6 C 0.5,2.6 2.6,0.5 6,0.5', r_top),
        'topright': body(tr) + white(tr, g_top) + arc('M 0,0.5 C 3.4,0.5 5.5,2.6 5.5,6', r_top),
        'bottomleft': body(bl) + white(bl, g_bot) + arc('M 0.5,0 C 0.5,3.4 2.6,5.5 6,5.5', r_bot),
        'bottomright': body(br) + white(br, g_bot) + arc('M 0,5.5 C 3.4,5.5 5.5,3.4 5.5,0', r_bot),
    }, (
        '<defs id="vitrea-glass-defs-night">'
        f'<linearGradient id="vg-gloss" x1="0" y1="0" x2="0" y2="1"><stop offset="0" style="stop-color:#ffffff;stop-opacity:{g_top}"/>'
        f'<stop offset="1" style="stop-color:#ffffff;stop-opacity:{g_bot}"/></linearGradient>'
        f'<linearGradient id="vg-rim" x1="0" y1="0" x2="0" y2="1"><stop offset="0" style="stop-color:#ffffff;stop-opacity:{r_side}"/>'
        f'<stop offset="1" style="stop-color:#ffffff;stop-opacity:{r_bot}"/></linearGradient></defs>')


def glassify(svg, st):
    content, defs = groups(st)
    for gid, inner in content.items():
        svg, n = re.subn(r'(<g\b[^>]*\bid="%s"[^>]*>).*?(</g>)' % gid, lambda m: m.group(1) + inner + m.group(2), svg,
                         count=1, flags=re.S)
        if n != 1:
            raise SystemExit(f'element {gid} not found')
    return re.sub(r'(<svg\b[^>]*>)', lambda m: m.group(1) + defs, svg, count=1)


def main():
    rc = os.path.join(THEME, 'plasmarc')
    if os.path.exists(rc) and '[ContrastEffect]' not in open(rc).read():
        with open(rc, 'a') as f:
            # vivid colour bleeding through the glass
            f.write('\n[ContrastEffect]\nenabled=true\ncontrast=0.25\nintensity=1.25\nsaturation=2.2\n'
                    '\n[BlurBehindEffect]\nenabled=true\n')
    for rel, st in STYLES.items():
        path = os.path.join(THEME, rel)
        if not os.path.exists(path):
            continue
        svg = gzip.open(path).read().decode()
        if MARK in svg:
            continue
        with gzip.open(path, 'wb') as out:
            out.write(glassify(svg, st).encode())
    print('Vitrea liquid glass applied to', THEME)


if __name__ == '__main__':
    main()
