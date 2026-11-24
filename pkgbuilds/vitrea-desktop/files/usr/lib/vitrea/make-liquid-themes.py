#!/usr/bin/env python3
"""Build Vitrea's Plasma themes from Plasma's default (Breeze) theme.

Writes three complete themes (a full copy each, so nothing falls back to Breeze):
  vitrea-liquid-clear   panels almost clear, the wallpaper shows through, refracted
  vitrea-liquid         balanced (default)
  vitrea-liquid-frosted more tint, best readability
The top bar and dock get a see-through glass body (the KWin "glass" effect adds refraction);
popups, menus and tooltips stay near-solid so text is always easy to read.
Re-run by a pacman hook whenever Plasma updates its default theme.
Usage: make-liquid-themes.py [SRC_THEME_DIR] [DEST_PARENT_DIR]
"""
import gzip, json, os, re, shutil, sys
import xml.etree.ElementTree as ET

SRC = sys.argv[1] if len(sys.argv) > 1 else '/usr/share/plasma/desktoptheme/default'
DEST = sys.argv[2] if len(sys.argv) > 2 else '/usr/share/plasma/desktoptheme'

# tint = opacity of the colour-scheme background inside the glass
VARIANTS = {
    # glass on the top bar and dock only; popups, menus and tooltips are near-solid
    'vitrea-liquid-clear':   dict(name='Vitrea (more transparent)', panel=0.18, dialog=0.86, tooltip=0.90, widget=0.40),
    'vitrea-liquid':         dict(name='Vitrea',                    panel=0.32, dialog=0.92, tooltip=0.94, widget=0.55),
    'vitrea-liquid-frosted': dict(name='Vitrea (less transparent)', panel=0.55, dialog=0.96, tooltip=0.97, widget=0.75),
}
FRAMES = {  # file -> (variant key for tint, sheen top, rim top, rim side, rim bottom, corner radius)
    'translucent/widgets/panel-background.svgz': ('panel', 0.05, 0.22, 0.10, 0.05, 16),
    'translucent/dialogs/background.svgz':       ('dialog', 0.0, 0.10, 0.08, 0.05, 12),
    'translucent/widgets/tooltip.svgz':          ('tooltip', 0.0, 0.08, 0.06, 0.04, 8),
    'translucent/widgets/background.svgz':       ('widget', 0.0, 0.10, 0.08, 0.05, 14),
}
GLASS_BUTTONS = False   # plain Breeze buttons; set True for the old glass pills
BG = 'class="ColorScheme-Background"'
DEFS_ID = 'vitrea-liquid-defs'


def frame_parts(tint, sheen, r_top, r_side, r_bot, R=6):
    """9-slice glass frame with R x R rounded corners (Qt SVG needs fill/opacity inside style="")."""
    body = lambda s: s.replace('/>', f' {BG} style="fill:currentColor;opacity:{tint}"/>')
    white = lambda s, op: s.replace('/>', f' style="fill:#ffffff;fill-opacity:{op}"/>')
    grad = lambda s, gid: s.replace('/>', f' style="fill:url(#{gid})"/>')
    rect = lambda w, h, x=0, y=0: f'<rect x="{x}" y="{y}" width="{w}" height="{h}"/>'
    L = 32
    # quarter-disc corners; each piece is drawn in its own R x R box
    tl = f'<path d="M 0,{R} A {R},{R} 0 0 1 {R},0 L {R},{R} Z"/>'
    tr = f'<path d="M 0,0 A {R},{R} 0 0 1 {R},{R} L 0,{R} Z"/>'
    bl = f'<path d="M 0,0 L {R},0 L {R},{R} A {R},{R} 0 0 1 0,0 Z"/>'
    br = f'<path d="M 0,0 L {R},0 A {R},{R} 0 0 1 0,{R} Z"/>'
    h = R - 0.5
    arc = lambda d, op: f'<path d="{d}" style="fill:none;stroke:#ffffff;stroke-width:1;stroke-opacity:{op}"/>'
    parts = {
        'center': body(rect(L, L)) + grad(rect(L, L), 'vl-sheen'),
        'top': body(rect(L, R)) + white(rect(L, R), sheen) + white(rect(L, 1), r_top),
        'bottom': body(rect(L, R)) + white(rect(L, 1, 0, R - 1), r_bot),
        'left': body(rect(R, L)) + grad(rect(R, L), 'vl-sheen') + grad(rect(1, L), 'vl-rim'),
        'right': body(rect(R, L)) + grad(rect(R, L), 'vl-sheen') + grad(rect(1, L, R - 1), 'vl-rim'),
        'topleft': body(tl) + white(tl, sheen) + arc(f'M 0.5,{R} A {h},{h} 0 0 1 {R},0.5', r_top),
        'topright': body(tr) + white(tr, sheen) + arc(f'M 0,0.5 A {h},{h} 0 0 1 {h},{R}', r_top),
        'bottomleft': body(bl) + arc(f'M 0.5,0 A {h},{h} 0 0 0 {R},{h}', r_bot),
        'bottomright': body(br) + arc(f'M 0,{h} A {h},{h} 0 0 0 {h},0', r_bot),
    }
    defs = (f'<defs id="{DEFS_ID}">'
            f'<linearGradient id="vl-sheen" x1="0" y1="0" x2="0" y2="1"><stop offset="0" style="stop-color:#ffffff;stop-opacity:{sheen}"/>'
            '<stop offset="0.55" style="stop-color:#ffffff;stop-opacity:0"/></linearGradient>'
            f'<linearGradient id="vl-rim" x1="0" y1="0" x2="0" y2="1"><stop offset="0" style="stop-color:#ffffff;stop-opacity:{r_side}"/>'
            f'<stop offset="1" style="stop-color:#ffffff;stop-opacity:{r_bot}"/></linearGradient></defs>')
    return parts, defs


def glassify_frame(svg, tint, sheen, r_top, r_side, r_bot, R):
    parts, defs = frame_parts(tint, sheen, r_top, r_side, r_bot, R)
    svg = re.sub(r'<defs id="vitrea-[^"]*">.*?</defs>', '', svg, flags=re.S)   # earlier Vitrea versions
    for gid, inner in parts.items():
        svg, n = re.subn(r'(<g\b[^>]*\bid="%s"[^>]*>).*?(</g>)' % gid, lambda m: m.group(1) + inner + m.group(2), svg,
                         count=1, flags=re.S)
        if n != 1:
            raise SystemExit(f'element {gid} not found')
        # the blur mask must have the same rounded shape, fully opaque
        solid = re.sub(r'<path d="[^"]*" style="fill:none[^"]*"/>', '', inner)
        solid = re.sub(r'style="[^"]*"', 'style="fill:#000000;fill-opacity:1"', solid)
        solid = re.sub(r' class="[^"]*"', '', solid)
        solid = solid.split('/>')[0] + '/>'          # just the body shape
        # Breeze's masks are bare <rect>/<path> elements (or groups): replace the whole element
        pat = r'<(rect|path)\b[^>]*?\bid="mask-%s"[^>]*?/>|<g\b[^>]*?\bid="mask-%s"[^>]*>.*?</g>' % (gid, gid)
        svg = re.sub(pat, lambda m: f'<g id="mask-{gid}">{solid}</g>', svg, count=1, flags=re.S)
    return re.sub(r'(<svg\b[^>]*>)', lambda m: m.group(1) + defs, svg, count=1)


# ---------- glass pill buttons (widgets/button.svgz) ----------
SVGNS = 'http://www.w3.org/2000/svg'
R = 9  # corner radius of the 9-slice button frames
PIECES = ['topleft', 'top', 'topright', 'left', 'center', 'right', 'bottomleft', 'bottom', 'bottomright']
# state -> (fill opacity, sheen, rim opacity, highlight-colour rim?)
BUTTON_STATES = {
    'normal': (0.08, 0.05, 0.38, False), 'hover': (0.14, 0.06, 0.62, False),
    'pressed': (0.04, 0.00, 0.22, False), 'focus': (0.10, 0.05, 0.85, True),
    'toolbutton-hover': (0.12, 0.05, 0.48, False), 'toolbutton-pressed': (0.05, 0.00, 0.25, False),
    'toolbutton-focus': (0.08, 0.04, 0.80, True),
}


def pill_piece(piece, fill, sheen, rim, accent, ox, oy):
    """One 9-slice piece of a glass pill, drawn at (ox, oy). Corners are R x R; edges R thick, 16 long."""
    L = 16
    w = {'left': R, 'right': R, 'center': L, 'top': L, 'bottom': L}.get(piece, R)
    h = {'top': R, 'bottom': R, 'center': L, 'left': L, 'right': L}.get(piece, R)
    rim_col = 'fill:none;stroke-width:1;' + ('stroke:currentColor;' if accent else 'stroke:#ffffff;')
    rim_cls = ' class="ColorScheme-Highlight"' if accent else ''
    shapes = []
    # body: white glass on top of whatever is behind (the effect blurs/refracts it)
    if piece in ('topleft', 'topright', 'bottomleft', 'bottomright'):
        cx = R if 'left' in piece else 0
        cy = R if 'top' in piece else 0
        sx = -1 if 'left' in piece else 1
        sy = -1 if 'top' in piece else 1
        # quarter disc + rim arc
        x1, y1 = cx + sx * R, cy
        x2, y2 = cx, cy + sy * R
        sweep = 1 if (sx * sy) > 0 else 0   # clockwise from the side point to the top/bottom point
        d = f'M {cx},{cy} L {x1},{y1} A {R},{R} 0 0 {sweep} {x2},{y2} Z'
        top = 'top' in piece
        shapes.append(f'<path d="{d}" style="fill:#ffffff;fill-opacity:{fill + (sheen if top else 0):.3f}"/>')
        rx1, ry1 = cx + sx * (R - 0.5), cy
        rx2, ry2 = cx, cy + sy * (R - 0.5)
        op = rim if top else rim * 0.45
        shapes.append(f'<path{rim_cls} d="M {rx1},{ry1} A {R - 0.5},{R - 0.5} 0 0 {sweep} {rx2},{ry2}" style="{rim_col}stroke-opacity:{op:.3f}"/>')
    else:
        top = piece == 'top'
        f = fill + (sheen if top else 0)
        shapes.append(f'<rect x="0" y="0" width="{w}" height="{h}" style="fill:#ffffff;fill-opacity:{f:.3f}"/>')
        if piece == 'top':
            shapes.append(f'<rect x="0" y="0" width="{w}" height="1" style="fill:{"currentColor" if accent else "#ffffff"};fill-opacity:{rim:.3f}"{rim_cls}/>')
        elif piece == 'bottom':
            shapes.append(f'<rect x="0" y="{h - 1}" width="{w}" height="1" style="fill:{"currentColor" if accent else "#ffffff"};fill-opacity:{rim * 0.45:.3f}"{rim_cls}/>')
        elif piece in ('left', 'right'):
            x = 0 if piece == 'left' else w - 1
            shapes.append(f'<rect x="{x}" y="0" width="1" height="{h}" style="fill:{"currentColor" if accent else "#ffffff"};fill-opacity:{rim * 0.7:.3f}"{rim_cls}/>')
    return f'<g transform="translate({ox},{oy})">' + ''.join(shapes) + '</g>'


def glass_buttons(svg_text):
    ET.register_namespace('', SVGNS)
    for p, u in [('inkscape', 'http://www.inkscape.org/namespaces/inkscape'),
                 ('sodipodi', 'http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd'),
                 ('xlink', 'http://www.w3.org/1999/xlink')]:
        ET.register_namespace(p, u)
    root = ET.fromstring(svg_text)
    by_id = {el.get('id'): el for el in root.iter() if el.get('id')}
    parent = {c: p for p in root.iter() for c in p}
    oy = 2000  # draw our pieces far below the original artwork so nothing overlaps
    for si, (state, (fill, sheen, rim, accent)) in enumerate(BUTTON_STATES.items()):
        ox = 0
        for piece in PIECES:
            eid = f'{state}-{piece}'
            old = by_id.get(eid)
            if old is None:
                continue
            new = ET.fromstring(f'<g xmlns="{SVGNS}" id="{eid}">' + pill_piece(piece, fill, sheen, rim, accent, ox, oy + si * 40) + '</g>')
            par = parent[old]
            idx = list(par).index(old)
            par.remove(old)
            par.insert(idx, new)
            ox += 40
    # the frame margins must match the new corner size
    for el in root.iter():
        eid = el.get('id') or ''
        if re.match(r'^(normal|hover|pressed|focus|toolbutton-hover|toolbutton-pressed|toolbutton-focus)-hint-(top|bottom|left|right)-margin$', eid):
            if el.tag.endswith('rect'):
                side = eid.rsplit('-', 2)[-2]
                if side in ('top', 'bottom'):
                    el.set('height', str(R - 3))
                else:
                    el.set('width', str(R - 1))
    return ET.tostring(root, encoding='unicode')


def build(theme_id, v):
    out = os.path.join(DEST, theme_id)
    tmp = out + '.new'
    shutil.rmtree(tmp, ignore_errors=True)
    shutil.copytree(SRC, tmp, symlinks=True)
    meta_path = os.path.join(tmp, 'metadata.json')
    meta = json.load(open(meta_path)) if os.path.exists(meta_path) else {'KPlugin': {}}
    meta.setdefault('KPlugin', {}).update({
        'Id': theme_id, 'Name': v['name'], 'Description': 'Vitrea OS: see-through top bar and dock, solid menus',
        'Authors': [{'Name': 'Vitrea OS'}], 'Category': '', 'License': 'LGPL-2.0-or-later', 'Website': ''})
    json.dump(meta, open(meta_path, 'w'), indent=4)
    with open(os.path.join(tmp, 'plasmarc'), 'w') as f:
        f.write('[Theme]\nname=%s\n\n[BlurBehindEffect]\nenabled=true\n\n[ContrastEffect]\nenabled=false\n\n'
                '[AdaptiveTransparency]\nenabled=false\n' % theme_id)
    for rel, (key, sheen, rt, rs, rb, rad) in FRAMES.items():
        path = os.path.join(tmp, rel)
        if os.path.exists(path):
            svg = gzip.open(path).read().decode()
            with gzip.open(path, 'wb') as o:
                o.write(glassify_frame(svg, v[key], sheen, rt, rs, rb, rad).encode())
    btn = os.path.join(tmp, 'widgets/button.svgz')
    if GLASS_BUTTONS and os.path.exists(btn):
        with gzip.open(btn, 'rb') as i:
            svg = i.read().decode()
        with gzip.open(btn, 'wb') as o:
            o.write(glass_buttons(svg).encode())
    shutil.rmtree(out, ignore_errors=True)
    os.rename(tmp, out)


def main():
    if not os.path.isdir(SRC):
        sys.exit(f'{SRC} not found')
    for theme_id, v in VARIANTS.items():
        build(theme_id, v)
    print('Vitrea Plasma themes written to', DEST)


if __name__ == '__main__':
    main()
