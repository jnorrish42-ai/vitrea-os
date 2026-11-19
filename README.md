# Vitrea OS

An easy-to-use, Arch-based Linux desktop with a **Liquid Glass** look,
plus [43PR's Hyprland dotfiles](https://github.com/43PR/dotfiles) as a second desktop.

![Vitrea OS desktop](screenshots/desktop-liquid-glass.png)

## Two desktops, picked at the login screen

| | **Vitrea Glass** (default) | **Hyprland (43PR)** |
|---|---|---|
| Base | KDE Plasma 6 | Hyprland 0.57 + Quickshell |
| Feel | Point-and-click, familiar | Keyboard-driven tiling |
| Look | Liquid Glass: clear top bar, dock and popups with a glossy sheen and bright specular rim (light blur, boosted colour), glass Kvantum windows with translucent title bars, global menu in the top bar, always-visible floating dock, window buttons on the left, magic-lamp minimise, Inter font, original "Glass Blossom" tree wallpaper (dawn in light mode, moonlit night in dark mode) | 43PR's bar, settings, wallpaper picker and matugen colour themes, unchanged |
| Good for | Everyone | Ricers and power users |

Both share the same apps and home folder. In the live session, open **Welcome → Try Hyprland**
(or log out) and pick **Hyprland (43PR)** in the session menu at the bottom-left of the login screen.

## Easy by default

* Boots straight into a live desktop with no password; nothing changes until you install
* **Install Vitrea OS** icon on the desktop and in the dock opens a guided graphical installer (Calamares)
* **Welcome** app on first login: Install, Get Apps, Wi-Fi, Displays, Updates, Light/Dark mode
* **Discover** app store with Flathub; Firefox, LibreOffice-ready, media player and the KDE app set
* Wi-Fi, Bluetooth, printing, PipeWire audio, firmware updates, compressed RAM swap (zram)
* New users get zsh + starship + eza (from the 43PR dotfiles)

## Try it

Write the ISO to a USB stick (Ventoy, balenaEtcher, Rufus in DD mode, or `dd`), or boot it in a VM
(2+ CPUs, 4 GB+ RAM, 3D acceleration on).

```bash
sudo dd if=vitrea-os-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

**Secure Boot:** like Arch Linux itself, the ISO isn't signed, so turn Secure Boot off in
your firmware settings.

## Build it

On Arch (or inside an Arch container), as root:

```bash
sudo pacman -S --needed archiso base-devel git
sudo ./build.sh
```

| Path | What it is |
|---|---|
| `archiso/` | the archiso profile (based on Arch's official `releng`) |
| `archiso/packages.x86_64` | every package on the ISO |
| `archiso/airootfs/` | files placed into the OS: themes, layout, Welcome app, installer config, 43PR dotfiles in `/etc/skel` |
| `archiso/airootfs/usr/local/bin/vitrea-customize` | one-time build step: branding, colour schemes, services |
| `archiso/airootfs/usr/lib/vitrea/make-glass-theme.py` | turns Plasma's Breeze frames into Liquid Glass (re-run by a pacman hook after Plasma updates) |
| `archiso/airootfs/etc/calamares/` | installer configuration and branding |
| `pkgbuilds/` | local builds of the AUR packages: calamares, mpvpaper, papirus-folders, ttf-tabler-icons |
| `art/` | generators for the Glass Blossom tree wallpaper (`make_tree.py`), the liquid gradient, logo and installer slides |
| `tools/` | QEMU boot test with screenshots (`test-boot.sh`), plus helpers to type into and screenshot the VM |

### Updating the 43PR dotfiles

They're copied into `archiso/airootfs/etc/skel/` (commit recorded in
`/usr/share/doc/43pr-dotfiles/COMMIT`). To update, re-copy `.config/` from the repo
(`.config/.zshrc` goes to `etc/skel/.zshrc`) and rebuild. The only change made to them:
the browser is `firefox` instead of `brave` (Brave is AUR-only).

## Credits

* Arch Linux, KDE Plasma, Hyprland, Quickshell, Calamares
* **43PR/dotfiles** by 43PR (MIT): Hyprland/Quickshell desktop, zsh, kitty, rofi, theming
* Glass Kvantum styles derived from Tsu Jan's KvMojave (GPLv3)
* Vitrea logo, wallpapers and installer slides: original

Not affiliated with Arch Linux, KDE, 43PR or Apple.
