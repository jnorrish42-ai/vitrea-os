#!/usr/bin/env bash
# shellcheck disable=SC2034
iso_name="vitrea-os"
iso_label="VITREA_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Vitrea OS"
iso_application="Vitrea OS Live/Install"
iso_version="1.0-$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15' '-b' '1M')
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
  ["/usr/bin/vitrea-welcome"]="0:0:755"
  ["/usr/bin/vitrea-appearance"]="0:0:755"
  ["/usr/bin/vitrea-install"]="0:0:755"
  ["/usr/bin/43pr-hyprland-session"]="0:0:755"
  ["/usr/lib/vitrea/add-flathub"]="0:0:755"
  ["/usr/lib/vitrea/make-glass-theme.py"]="0:0:755"
  ["/usr/lib/vitrea/calamares-cleanup"]="0:0:755"
)
