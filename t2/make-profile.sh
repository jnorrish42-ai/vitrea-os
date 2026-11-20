#!/bin/bash
# Turn the standard Vitrea archiso profile into the T2 Mac edition.
#   t2/make-profile.sh SRC_PROFILE DST_PROFILE
# Used by ./build.sh --t2. Follows https://wiki.t2linux.org (linux-t2 kernel from the
# arch-mact2 repo, t2bce modules, kernel parameters, iwd for Broadcom Wi-Fi).
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=$1 DST=$2
T2_PARAMS="intel_iommu=on iommu=pt pm_async=off"
# Live session only (as on t2linux's own ISO): the BCM4377 Bluetooth driver misbehaves
# before the firmware has been fetched.
LIVE_EXTRA="modprobe.blacklist=hci_bcm4377"

rm -rf "$DST"
cp -a "$SRC" "$DST"

# --- packages: T2 kernel instead of the stock one, T2 tools, vitrea-t2 (files: pkgbuilds/vitrea-t2) ---
grep -vxF -f "$HERE/packages.remove" "$SRC/packages.x86_64" > "$DST/packages.x86_64"
cat "$HERE/packages.add" >> "$DST/packages.x86_64"

# --- the arch-mact2 repo for the build ---
cat >> "$DST/pacman.conf" <<'EOF'

[arch-mact2]
SigLevel = Never
Server = https://mirror.funami.tech/arch-mact2/os/$arch
EOF

# --- ISO identity ---
sed -i -e 's/^iso_name=.*/iso_name="vitrea-os-t2"/' \
       -e 's/^iso_label="VITREA_/iso_label="VITREA_T2_/' \
       -e 's/^iso_application=.*/iso_application="Vitrea OS Live\/Install for T2 Macs"/' "$DST/profiledef.sh"

# --- live boot entries: kernel file names + T2 kernel parameters ---
for f in "$DST"/efiboot/loader/entries/*.conf "$DST"/syslinux/*.cfg "$DST"/grub/*.cfg; do
  [ -f "$f" ] || continue
  sed -i -e 's/vmlinuz-linux\b/vmlinuz-linux-t2/g' -e 's/initramfs-linux\.img/initramfs-linux-t2.img/g' "$f"
  sed -i -E "/^\s*(options|APPEND) .*archisobasedir/ s/\$/ $T2_PARAMS $LIVE_EXTRA/" "$f"
  sed -i -E "/^\s*linux .*archisobasedir/ s/\$/ $T2_PARAMS $LIVE_EXTRA/" "$f"
done
sed -i -E 's/^(title .*)Vitrea OS/\1Vitrea OS for T2 Macs/' "$DST"/efiboot/loader/entries/*.conf

# --- installer: copy the T2 kernel, carry fetched firmware over, T2 kernel parameters ---
C="$DST/airootfs/etc/calamares/modules"
sed -i 's/vmlinuz-linux\b/vmlinuz-linux-t2/g' "$C/shellprocess_kernel.conf"
printf '    - "-/usr/lib/vitrea/t2-copy-firmware ${ROOT}"\n' >> "$C/shellprocess_kernel.conf"
sed -i -E "s/^kernelParams: \[ (.*) \]/kernelParams: [ \1, $(echo $T2_PARAMS | sed -E 's/([^ ]+)/"\1"/g; s/ /, /g') ]/" "$C/bootloader.conf"
sed -i -E "s/(GRUB_CMDLINE_LINUX_DEFAULT: \"[^\"]*)\"/\1 $T2_PARAMS\"/" "$C/grubcfg.conf"

echo "T2 profile written to $DST"
