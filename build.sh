#!/bin/bash
# Build the Vitrea OS ISO on an Arch Linux host (run as root):
#   sudo pacman -S --needed archiso base-devel git
#   sudo ./build.sh          # standard edition  -> out/vitrea-os-*.iso
#   sudo ./build.sh --t2     # T2 Mac edition    -> out/vitrea-os-t2-*.iso
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
WORK=${WORK:-/tmp/vitrea-work}
PROFILE="$HERE/archiso"
# 1) Build the few AUR packages into a local repo at /build/localrepo
mkdir -p /build && rm -rf /build/pkgbuilds && cp -r "$HERE/pkgbuilds" /build/
bash /build/pkgbuilds/build-all.sh
# 2) T2 Mac edition: derive its profile from the standard one (see t2/)
if [ "${1:-}" = "--t2" ]; then
  PROFILE=/build/profile-t2
  "$HERE/t2/make-profile.sh" "$HERE/archiso" "$PROFILE"
fi
# 3) Build the ISO
mkarchiso -v -r -w "$WORK" -o "$HERE/out" "$PROFILE"
