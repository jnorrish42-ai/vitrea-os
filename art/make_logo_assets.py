#!/usr/bin/env python3
"""Install the Vitrea glass-V logo (art/logo/vitrea-v.png, transparent) at every icon size.
Usage: make_logo_assets.py ROOT_DIR   (normally pkgbuilds/vitrea-desktop/files)"""
import base64, io, os, sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
root = sys.argv[1]
logo = Image.open(os.path.join(HERE, 'logo', 'vitrea-v.png')).convert('RGBA')
icons = os.path.join(root, 'usr/share/icons/hicolor')
for size in (16, 22, 24, 32, 48, 64, 96, 128, 256, 512):
    d = os.path.join(icons, f'{size}x{size}', 'apps')
    os.makedirs(d, exist_ok=True)
    logo.resize((size, size), Image.LANCZOS).save(os.path.join(d, 'vitrea-logo.png'), optimize=True)
# scalable entry: an SVG wrapping the 512px artwork, so "scalable" lookups get the new logo too
buf = io.BytesIO(); logo.resize((512, 512), Image.LANCZOS).save(buf, 'PNG', optimize=True)
svg = ('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="512" height="512" viewBox="0 0 512 512">'
       f'<image width="512" height="512" xlink:href="data:image/png;base64,{base64.b64encode(buf.getvalue()).decode()}"/></svg>')
os.makedirs(os.path.join(icons, 'scalable/apps'), exist_ok=True)
open(os.path.join(icons, 'scalable/apps/vitrea-logo.svg'), 'w').write(svg)
stale = os.path.join(icons, 'scalable/apps/vitrea-logo.png')
if os.path.exists(stale):
    os.remove(stale)
os.makedirs(os.path.join(root, 'usr/share/pixmaps'), exist_ok=True)
logo.resize((256, 256), Image.LANCZOS).save(os.path.join(root, 'usr/share/pixmaps/vitrea-logo.png'), optimize=True)
print('logo installed under', root)
