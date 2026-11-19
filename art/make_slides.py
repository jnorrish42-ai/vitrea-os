#!/usr/bin/env python3
"""Generate Calamares slideshow + branding images for Vitrea OS.
Usage: make_slides.py WALLPAPER.png LOGO.png OUTDIR"""
import os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

wall, logo_path, out = sys.argv[1:4]
os.makedirs(out, exist_ok=True)
W, H = 2266, 1275
FONT = "/usr/share/fonts/opentype/inter/Inter-%s.otf"

def font(weight, size):
    return ImageFont.truetype(FONT % weight, size)

SLIDES = [
    ("01-welcome.png", "Welcome to Vitrea OS",
     ["Beautiful, simple and fast.", "Sit back — this only takes a few minutes."]),
    ("02-apps.png", "Thousands of apps, one click away",
     ["Open Discover to browse and install free apps", "like Firefox, Spotify, Steam, LibreOffice and more."]),
    ("03-safe.png", "Always fresh",
     ["Built on Arch Linux: the newest apps and drivers,", "updated with one click in Discover."]),
    ("04-yours.png", "Two desktops, your choice",
     ["Riced Plasma for everyday ease, or 43PR's Hyprland", "for keyboard lovers. Pick one at the login screen."]),
]

bg = Image.open(wall).convert("RGB").resize((W, H), Image.LANCZOS)
logo = Image.open(logo_path).convert("RGBA")

def glass_card(img, box, radius=60):
    x0, y0, x1, y1 = box
    region = img.crop(box).filter(ImageFilter.GaussianBlur(40))
    white = Image.new("RGB", region.size, (255, 255, 255))
    region = Image.blend(region, Image.new("RGB", region.size, (24, 24, 37)), 0.72)
    mask = Image.new("L", region.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, x1 - x0 - 1, y1 - y0 - 1), radius, fill=255)
    img.paste(region, (x0, y0), mask)
    d = ImageDraw.Draw(img, "RGBA")
    d.rounded_rectangle(box, radius, outline=(69, 71, 90, 255), width=3)

for fname, title, lines in SLIDES:
    img = bg.copy()
    box = (233, 220, W - 233, H - 220)
    glass_card(img, box)
    lg = logo.resize((200, 200), Image.LANCZOS)
    img.paste(lg, (box[0] + 110, (H - 200) // 2 - 10), lg)
    d = ImageDraw.Draw(img)
    tx = box[0] + 400
    d.text((tx, 450), title, font=font("SemiBold", 76), fill=(205, 214, 244))
    for i, ln in enumerate(lines):
        d.text((tx, 590 + i * 70), ln, font=font("Regular", 48), fill=(166, 173, 200))
    img.save(os.path.join(out, fname), optimize=True)

# Calamares images: logo (sidebar), icon, welcome banner
logo.resize((86, 86), Image.LANCZOS).save(os.path.join(out, "logo.png"))
logo.resize((512, 512), Image.LANCZOS).save(os.path.join(out, "icon.png"))
ban = bg.resize((800, 450), Image.LANCZOS).crop((0, 75, 800, 375))
glass_card(ban, (40, 40, 760, 260), 36)
lg = logo.resize((120, 120), Image.LANCZOS)
ban.paste(lg, (80, 90), lg)
ImageDraw.Draw(ban).text((230, 108), "Vitrea OS", font=font("SemiBold", 64), fill=(205, 214, 244))
ImageDraw.Draw(ban).text((232, 186), "Simple. Beautiful. Yours.", font=font("Regular", 28), fill=(166, 173, 200))
ban.save(os.path.join(out, "welcome.png"))
print("ok")
