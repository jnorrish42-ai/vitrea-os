#!/usr/bin/env bash
# shellcheck disable=SC2034
iso_name="vitrea-os"
iso_label="VITREA_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Vitrea OS"
iso_application="Vitrea OS Live/Install"
iso_version="${VITREA_VERSION:-1.2}-$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
# xz with the x86 filter: about 10-15% smaller than zstd, so the image fits 4 GB USB sticks
# (the UEFI boot partition sits at the very end of the image; a cut-off write can't boot)
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--long' '-19')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/sudoers.d"]="0:0:750"
  ["/root"]="0:0:750"
  ["/root/.gnupg"]="0:0:700"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/local/bin/vitrea-live-setup"]="0:0:755"
  ["/usr/local/bin/vitrea-customize"]="0:0:755"
  ["/usr/bin/vitrea-install"]="0:0:755"
  ["/usr/lib/vitrea/calamares-cleanup"]="0:0:755"
  ["/usr/lib/vitrea/install-kernel"]="0:0:755"
)
