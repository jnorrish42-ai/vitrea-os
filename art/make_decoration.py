#!/usr/bin/env python3
"""Generate the "Vitrea Glass" KWin (Aurorae) window decorations, light + dark.

Glass title bar with rounded top corners, specular rim and soft shadow, plus
glossy traffic-light buttons (close / minimise / maximise) whose glyph appears on hover.
Usage: make_decoration.py OUT_DIR   ->  OUT_DIR/VitreaGlass, OUT_DIR/VitreaGlassDark
"""
import json, os, sys

P = 26      # shadow padding around the window
R = 11      # title bar corner radius
T = 34      # title bar height
BTN = 14    # button size

THEMES = {
    'VitreaNight': dict(
        name='Vitrea Night', fill='#11111b', fill_op=0.97, fill_op_in=0.93, rim_op=0.07, sep='#000000', sep_op=0.0,
        text='205,214,244', text_in='127,132,156', btn_in='#45475a', glyph='#11111b', gloss=0.0, flat=True,
        buttons={'close': ('#f38ba8', '#f38ba8'), 'minimize': ('#f9e2af', '#f9e2af'),
                 'maximize': ('#a6e3a1', '#a6e3a1'), 'restore': ('#a6e3a1', '#a6e3a1')}),
    'VitreaGlass': dict(
        name='Vitrea Glass', fill='#ffffff', fill_op=0.62, fill_op_in=0.45, rim_op=0.95, sep='#000000', sep_op=0.07,
        text='20,24,42', text_in='110,116,136', btn_in='#c7cad3', glyph='#4a1f1b'),
    'VitreaGlassDark': dict(
        name='Vitrea Glass Dark', fill='#1d2132', fill_op=0.70, fill_op_in=0.55, rim_op=0.22, sep='#000000', sep_op=0.35,
        text='236,239,247', text_in='150,156,176', btn_in='#4a4f63', glyph='#3a1210'),
}
BUTTONS = {'close': ('#ff605c', '#d9443f'), 'minimize': ('#ffbd44', '#d99a22'),
           'maximize': ('#00ca4e', '#00a83e'), 'restore': ('#00ca4e', '#00a83e')}
GLYPHS = {  # drawn in a 14x14 box
    'close': '<path d="M4.6,4.6 L9.4,9.4 M9.4,4.6 L4.6,9.4" stroke-width="1.4" stroke-linecap="round"/>',
    'minimize': '<path d="M4.2,7 L9.8,7" stroke-width="1.5" stroke-linecap="round"/>',
    'maximize': '<path d="M4.4,7 L9.6,7 M7,4.4 L7,9.6" stroke-width="1.4" stroke-linecap="round"/>',
    'restore': '<path d="M4.6,7 L9.4,7" stroke-width="1.4" stroke-linecap="round"/>',
}


def shadow_stops(gid, horiz, rev=False, maxa=0.20):
    # quadratic falloff from the window edge outwards
    pts = [(0.0, maxa), (0.25, maxa * 0.62), (0.5, maxa * 0.30), (0.75, maxa * 0.09), (1.0, 0.0)]
    if rev:
        pts = [(1 - o, a) for o, a in pts][::-1]
    x2, y2 = ('1', '0') if horiz else ('0', '1')
    stops = ''.join(f'<stop offset="{o}" style="stop-color:#000000;stop-opacity:{a:.3f}"/>' for o, a in pts)
    return f'<linearGradient id="{gid}" x1="0" y1="0" x2="{x2}" y2="{y2}">{stops}</linearGradient>'


def radial(gid, cx, cy, maxa=0.20):
    pts = [(0.0, maxa), (0.25, maxa * 0.62), (0.5, maxa * 0.30), (0.75, maxa * 0.09), (1.0, 0.0)]
    stops = ''.join(f'<stop offset="{o}" style="stop-color:#000000;stop-opacity:{a:.3f}"/>' for o, a in pts)
    return (f'<radialGradient id="{gid}" gradientUnits="userSpaceOnUse" cx="{cx}" cy="{cy}" r="{P}">{stops}</radialGradient>')


def decoration_svg(t):
    """Two 9-slice frames: prefix 'decoration' (active) and 'decoration-inactive'."""
    W = 2 * (P + R) + 20          # template width (center slice 20px)
    out = []
    defs = []
    for row, (prefix, op) in enumerate((('decoration', t['fill_op']), ('decoration-inactive', t['fill_op_in']))):
        oy = row * 140               # stack the two templates vertically in the file
        pre = prefix
        sh = 0.28 if prefix == "decoration" else 0.16
        g = f'{pre}-'
        defs += [shadow_stops(g + 'sl', True, rev=True, maxa=sh), shadow_stops(g + 'sr', True, maxa=sh),
                 shadow_stops(g + 'st', False, rev=True, maxa=sh * 0.6), shadow_stops(g + 'sb', False, maxa=sh)]
        defs.append(f'<linearGradient id="{g}gloss" x1="0" y1="0" x2="0" y2="1">'
                    f'<stop offset="0" style="stop-color:#ffffff;stop-opacity:{t.get("gloss", 0.35)}"/>'
                    f'<stop offset="1" style="stop-color:#ffffff;stop-opacity:0.0"/></linearGradient>')
        bar = lambda w: (f'<rect x="0" y="{P}" width="{w}" height="{T}" style="fill:{t["fill"]};fill-opacity:{op}"/>'
                         f'<rect x="0" y="{P}" width="{w}" height="{T}" style="fill:url(#{g}gloss)"/>'
                         f'<rect x="0" y="{P}" width="{w}" height="1" style="fill:#ffffff;fill-opacity:{t["rim_op"]}"/>'
                         f'<rect x="0" y="{P + T - 1}" width="{w}" height="1" style="fill:{t["sep"]};fill-opacity:{t["sep_op"]}"/>')
        cw = P + R
        # top-left: shadow corner + rounded bar corner
        defs.append(radial(g + 'rtl', P, P + R, sh * 0.8))
        defs.append(radial(g + 'rtr', 0 + R, P + R, sh * 0.8))
        defs.append(radial(g + 'rbl', P, 0, sh))
        defs.append(radial(g + 'rbr', R, 0, sh))
        corner_path = f'M {P},{P + T} V {P + R} A {R},{R} 0 0 1 {P + R},{P} V {P + T} Z'
        tl = (f'<g id="{pre}-topleft" transform="translate(0,{oy})">'
              f'<rect width="{P}" height="{P + R}" style="fill:url(#{g}rtl)"/>'
              f'<rect x="{P}" width="{R}" height="{P}" style="fill:url(#{g}st)"/>'
              f'<rect x="0" y="{P + R}" width="{P}" height="{T - R}" style="fill:url(#{g}sl)"/>'
              f'<path d="{corner_path}" style="fill:{t["fill"]};fill-opacity:{op}"/>'
              f'<path d="{corner_path}" style="fill:url(#{g}gloss)"/>'
              f'<path d="M {P + 0.5},{P + T} V {P + R} A {R - 0.5},{R - 0.5} 0 0 1 {P + R},{P + 0.5}" '
              f'style="fill:none;stroke:#ffffff;stroke-width:1;stroke-opacity:{t["rim_op"]}"/>'
              f'<rect x="{P}" y="{P + T - 1}" width="{R}" height="1" style="fill:{t["sep"]};fill-opacity:{t["sep_op"]}"/></g>')
        tr_path = f'M 0,{P + T} V {P} A {R},{R} 0 0 1 {R},{P + R} V {P + T} Z'
        tr = (f'<g id="{pre}-topright" transform="translate({cw + 20},{oy})">'
              f'<rect x="{R}" width="{P}" height="{P + R}" style="fill:url(#{g}rtr)"/>'
              f'<rect width="{R}" height="{P}" style="fill:url(#{g}st)"/>'
              f'<rect x="{R}" y="{P + R}" width="{P}" height="{T - R}" style="fill:url(#{g}sr)"/>'
              f'<path d="{tr_path}" style="fill:{t["fill"]};fill-opacity:{op}"/>'
              f'<path d="{tr_path}" style="fill:url(#{g}gloss)"/>'
              f'<path d="M 0,{P + 0.5} A {R - 0.5},{R - 0.5} 0 0 1 {R - 0.5},{P + R} V {P + T}" '
              f'style="fill:none;stroke:#ffffff;stroke-width:1;stroke-opacity:{t["rim_op"]}"/>'
              f'<rect x="0" y="{P + T - 1}" width="{R}" height="1" style="fill:{t["sep"]};fill-opacity:{t["sep_op"]}"/></g>')
        top = (f'<g id="{pre}-top" transform="translate({cw},{oy})">'
               f'<rect width="20" height="{P}" style="fill:url(#{g}st)"/>{bar(20)}</g>')
        left = (f'<g id="{pre}-left" transform="translate(0,{oy + P + T})">'
                f'<rect width="{P}" height="20" style="fill:url(#{g}sl)"/><rect x="{P}" width="{R}" height="20" style="fill:none"/></g>')
        right = (f'<g id="{pre}-right" transform="translate({cw + 20},{oy + P + T})">'
                 f'<rect x="{R}" width="{P}" height="20" style="fill:url(#{g}sr)"/><rect width="{R}" height="20" style="fill:none"/></g>')
        center = (f'<g id="{pre}-center" transform="translate({cw},{oy + P + T})">'
                  f'<rect width="20" height="20" style="fill:none"/></g>')
        bl = (f'<g id="{pre}-bottomleft" transform="translate(0,{oy + P + T + 20})">'
              f'<rect width="{cw}" height="{P}" style="fill:url(#{g}rbl)"/>'
              f'<rect x="{P}" width="{R}" height="{P}" style="fill:url(#{g}sb)"/></g>')
        br = (f'<g id="{pre}-bottomright" transform="translate({cw + 20},{oy + P + T + 20})">'
              f'<rect width="{cw}" height="{P}" style="fill:url(#{g}rbr)"/>'
              f'<rect width="{R}" height="{P}" style="fill:url(#{g}sb)"/></g>')
        bottom = (f'<g id="{pre}-bottom" transform="translate({cw},{oy + P + T + 20})">'
                  f'<rect width="20" height="{P}" style="fill:url(#{g}sb)"/></g>')
        out += [tl, top, tr, left, center, right, bl, bottom, br]
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="280"><defs>{"".join(defs)}</defs>'
            + ''.join(out) + '</svg>')


def button_svg(kind, t):
    c1, c2 = t.get('buttons', BUTTONS)[kind]
    flat = t.get('flat', False)
    glyph = GLYPHS[kind].replace('<path', f'<path style="fill:none;stroke:{t["glyph"]};stroke-opacity:0.75"')

    def ball(eid, top, bottom, glyph_on, x):
        return (f'<g id="{eid}" transform="translate({x},0)">'
                f'<rect width="{BTN}" height="{BTN}" style="fill:none"/>'
                f'<circle cx="7" cy="7" r="6.2" style="fill:url(#g-{eid})"/>'
                + ('' if flat else
                   f'<circle cx="7" cy="7" r="5.9" style="fill:none;stroke:#000000;stroke-opacity:0.18;stroke-width:0.6"/>'
                   f'<ellipse cx="7" cy="4.6" rx="3.9" ry="2.2" style="fill:#ffffff;fill-opacity:0.42"/>')
                + (glyph if glyph_on else '') + '</g>'), \
               (f'<linearGradient id="g-{eid}" x1="0" y1="0" x2="0" y2="1">'
                f'<stop offset="0" style="stop-color:{top}"/><stop offset="1" style="stop-color:{bottom}"/></linearGradient>')

    parts, defs = [], []
    variants = [('active-center', c1, c2, False), ('hover-center', c1, c2, True), ('pressed-center', c2, c2, True),
                ('inactive-center', t['btn_in'], t['btn_in'], False), ('hover-inactive-center', c1, c2, True),
                ('pressed-inactive-center', c2, c2, True), ('deactivated-center', t['btn_in'], t['btn_in'], False),
                ('deactivated-inactive-center', t['btn_in'], t['btn_in'], False)]
    for i, (eid, a, b, g) in enumerate(variants):
        p, d = ball(eid, a, b, g, i * (BTN + 2))
        parts.append(p); defs.append(d)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{len(variants) * (BTN + 2)}" height="{BTN}">'
            f'<defs>{"".join(defs)}</defs>{"".join(parts)}</svg>')


def rc(t):
    return f"""[General]
ActiveTextColor={t['text']}
InactiveTextColor={t['text_in']}
TitleAlignment=Center
TitleVerticalAlignment=Center
Animation=140
DecorationPosition=0

[Layout]
BorderLeft=0
BorderRight=0
BorderBottom=0
TitleEdgeTop=0
TitleEdgeBottom=0
TitleEdgeLeft=12
TitleEdgeRight=12
TitleEdgeTopMaximized=0
TitleEdgeBottomMaximized=0
TitleEdgeLeftMaximized=12
TitleEdgeRightMaximized=12
TitleBorderLeft=8
TitleBorderRight=8
TitleHeight={T}
ButtonWidth={BTN}
ButtonHeight={BTN}
ButtonSpacing=8
ButtonMarginTop={(T - BTN) // 2}
ButtonMarginTopMaximized={(T - BTN) // 2}
ExplicitButtonSpacer=10
PaddingTop={P}
PaddingBottom={P}
PaddingLeft={P}
PaddingRight={P}
"""


def main(out):
    for tid, t in THEMES.items():
        d = os.path.join(out, tid)
        os.makedirs(d, exist_ok=True)
        open(os.path.join(d, 'decoration.svg'), 'w').write(decoration_svg(t))
        for kind in BUTTONS:
            open(os.path.join(d, f'{kind}.svg'), 'w').write(button_svg(kind, t))
        open(os.path.join(d, f'{tid}rc'), 'w').write(rc(t))
        open(os.path.join(d, 'metadata.desktop'), 'w').write(
            f"[Desktop Entry]\nName={t['name']}\nComment=Liquid glass title bars with traffic-light buttons\n"
            f"X-KDE-PluginInfo-Author=Vitrea OS\nX-KDE-PluginInfo-Name={tid}\nX-KDE-PluginInfo-Version=1.0\n"
            f"X-KDE-PluginInfo-License=CC-BY-SA-4.0\n")
        json.dump({'KPackageStructure': 'KWin/Aurorae',
                   'KPlugin': {'Id': tid, 'Name': t['name'], 'Description': 'Liquid glass title bars',
                               'Authors': [{'Name': 'Vitrea OS'}], 'License': 'CC-BY-SA-4.0', 'Version': '1.0'}},
                  open(os.path.join(d, 'metadata.json'), 'w'), indent=2)
        print('wrote', d)


if __name__ == '__main__':
    main(sys.argv[1])
