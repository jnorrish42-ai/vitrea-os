#!/usr/bin/env python3
"""Vitrea Night: dark "riced" palette (Catppuccin Mocha-inspired) for Plasma, Konsole and friends.
Usage: make_night.py ROOT_DIR   (normally pkgbuilds/vitrea-desktop/files)"""
import os, sys

PAL = dict(
    crust='#11111b', mantle='#181825', base='#1e1e2e', surface0='#313244', surface1='#45475a', surface2='#585b70',
    overlay0='#6c7086', overlay1='#7f849c', subtext0='#a6adc8', subtext1='#bac2de', text='#cdd6f4',
    lavender='#b4befe', blue='#89b4fa', sapphire='#74c7ec', sky='#89dceb', teal='#94e2d5', green='#a6e3a1',
    yellow='#f9e2af', peach='#fab387', maroon='#eba0ac', red='#f38ba8', mauve='#cba6f7', pink='#f5c2e7',
    rosewater='#f5e0dc', flamingo='#f2cdcd')


def rgb(h):
    h = PAL.get(h, h).lstrip('#')
    return ','.join(str(int(h[i:i + 2], 16)) for i in (0, 2, 4))


def group(bg, bg_alt, fg='text', fg_in='subtext0'):
    return {
        'BackgroundAlternate': rgb(bg_alt), 'BackgroundNormal': rgb(bg),
        'DecorationFocus': rgb('mauve'), 'DecorationHover': rgb('lavender'),
        'ForegroundActive': rgb('blue'), 'ForegroundInactive': rgb(fg_in), 'ForegroundLink': rgb('blue'),
        'ForegroundNegative': rgb('red'), 'ForegroundNeutral': rgb('yellow'), 'ForegroundNormal': rgb(fg),
        'ForegroundPositive': rgb('green'), 'ForegroundVisited': rgb('mauve')}


def colors():
    g = {
        'Colors:Window': group('base', 'mantle'),
        'Colors:View': group('mantle', 'base'),
        'Colors:Button': group('surface0', 'surface1'),
        'Colors:Header': group('crust', 'mantle'),
        'Colors:Header][Inactive': group('crust', 'mantle'),
        'Colors:Tooltip': group('crust', 'mantle'),
        'Colors:Complementary': group('crust', 'mantle'),
        'Colors:Selection': dict(group('mauve', 'lavender', fg='crust', fg_in='mantle'),
                                 ForegroundActive=rgb('crust')),
    }
    out = ['[ColorEffects:Disabled]', 'Color=56,56,56', 'ColorAmount=0', 'ColorEffect=0', 'ContrastAmount=0.65',
           'ContrastEffect=1', 'IntensityAmount=0.1', 'IntensityEffect=2', '',
           '[ColorEffects:Inactive]', 'ChangeSelectionColor=true', 'Color=112,111,110', 'ColorAmount=0.025',
           'ColorEffect=2', 'ContrastAmount=0.1', 'ContrastEffect=2', 'Enable=false', 'IntensityAmount=0',
           'IntensityEffect=0', '']
    for name, kv in g.items():
        out.append(f'[{name}]')
        out += [f'{k}={v}' for k, v in sorted(kv.items())]
        out.append('')
    out += ['[General]', 'ColorScheme=VitreaNight', 'Name=Vitrea Night', 'shadeSortColumn=true', '',
            '[KDE]', 'contrast=4', '',
            '[WM]', f'activeBackground={rgb("crust")}', f'activeBlend={rgb("text")}', f'activeForeground={rgb("text")}',
            f'inactiveBackground={rgb("crust")}', f'inactiveBlend={rgb("subtext0")}', f'inactiveForeground={rgb("overlay1")}', '']
    return '\n'.join(out)


def konsole():
    names = ['Background', 'BackgroundIntense', 'Foreground', 'ForegroundIntense']
    ansi = [('Color0', 'surface1', 'surface2'), ('Color1', 'red', 'red'), ('Color2', 'green', 'green'),
            ('Color3', 'yellow', 'yellow'), ('Color4', 'blue', 'blue'), ('Color5', 'pink', 'pink'),
            ('Color6', 'teal', 'teal'), ('Color7', 'subtext1', 'subtext0')]
    out = [f'[Background]\nColor={rgb("base")}\n', f'[BackgroundIntense]\nColor={rgb("base")}\n',
           f'[BackgroundFaint]\nColor={rgb("base")}\n', f'[Foreground]\nColor={rgb("text")}\n',
           f'[ForegroundIntense]\nColor={rgb("text")}\nBold=true\n', f'[ForegroundFaint]\nColor={rgb("subtext0")}\n']
    for n, c, ci in ansi:
        out.append(f'[{n}]\nColor={rgb(c)}\n')
        out.append(f'[{n}Intense]\nColor={rgb(ci)}\n')
        out.append(f'[{n}Faint]\nColor={rgb(c)}\n')
    out.append('[General]\nBlur=true\nColorRandomization=false\nDescription=Vitrea Night\nOpacity=0.9\nWallpaper=\n')
    return '\n'.join(out)


def main(root):
    cs = os.path.join(root, 'usr/share/color-schemes'); os.makedirs(cs, exist_ok=True)
    open(os.path.join(cs, 'VitreaNight.colors'), 'w').write(colors())
    kd = os.path.join(root, 'usr/share/konsole'); os.makedirs(kd, exist_ok=True)
    open(os.path.join(kd, 'VitreaNight.colorscheme'), 'w').write(konsole())
    open(os.path.join(kd, 'Vitrea.profile'), 'w').write(
        '[Appearance]\nColorScheme=VitreaNight\nFont=JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1\n\n'
        '[General]\nName=Vitrea\nParent=FALLBACK/\nTerminalColumns=100\nTerminalRows=28\nTerminalMargin=12\n\n'
        '[Scrolling]\nScrollBarPosition=2\n\n[Terminal Features]\nBlinkingCursorEnabled=true\n')
    print('Vitrea Night written to', root)


if __name__ == '__main__':
    main(sys.argv[1])
