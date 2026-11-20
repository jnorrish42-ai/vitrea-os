#!/bin/bash
# Runs inside the Arch build root: build local packages into /build/localrepo.
set -euo pipefail
id builder >/dev/null 2>&1 || useradd -m builder
REPO=/build/localrepo; mkdir -p $REPO
for d in /build/pkgbuilds/*/; do
  n=$(basename "$d")
  case $n in
    vitrea-*)  # Vitrea's own file packages: always rebuild (timestamp version), no build deps
      rm -f $REPO/$n-[0-9]*.pkg.tar.zst
      chown -R builder "$d"
      su builder -c "cd $d && rm -f *.pkg.tar.zst && makepkg -d -f --noconfirm"
      cp "$d"/$n-[0-9]*.pkg.tar.zst $REPO/
      continue ;;
  esac
  ls $REPO/$n-[0-9]*.pkg.tar.zst >/dev/null 2>&1 && { echo "skip $n"; continue; }
  # install deps as root, build as builder
  ( source "$d/PKGBUILD"; deps=("${depends[@]}" "${makedepends[@]}"); [ ${#deps[@]} -eq 0 ] || pacman -S --needed --noconfirm --asdeps "${deps[@]}" )
  chown -R builder "$d"
  su builder -c "cd $d && makepkg -f --noconfirm --nocheck --skippgpcheck" 
  cp $(ls "$d"/*.pkg.tar.zst | grep -v -- -debug-) $REPO/
done
cd $REPO && rm -f vitrea-local.db* vitrea-local.files* && repo-add -q vitrea-local.db.tar.zst *.pkg.tar.zst
ls -la $REPO
