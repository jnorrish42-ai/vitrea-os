#!/bin/bash
# Build the Vitrea OS ISO on an Arch Linux host (run as root):
#   sudo pacman -S --needed archiso base-devel git
#   sudo ./build.sh
# Output: out/vitrea-os-*.iso
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
WORK=${WORK:-/tmp/vitrea-work}
# 1) Build the few AUR packages into a local repo at /build/localrepo
mkdir -p /build && rm -rf /build/pkgbuilds && cp -r "$HERE/pkgbuilds" /build/
bash /build/pkgbuilds/build-all.sh
# 2) Build the ISO
mkarchiso -v -r -w "$WORK" -o "$HERE/out" "$HERE/archiso"
