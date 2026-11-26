#!/bin/bash
# Repair Vitrea's boot loader from the Vitrea USB stick (live session), when an installed
# Vitrea doesn't start ("Couldn't find a bootable operating system", GRUB errors).
#   curl -sL https://raw.githubusercontent.com/jnorrish42-ai/vitrea-os/main/tools/fix-boot.sh | sudo bash
# Finds the installed Vitrea, rebuilds its startup files and installs GRUB both as "Vitrea" and
# at the standard fallback path EFI/BOOT/BOOTX64.EFI that every PC (and Surface) starts.
set -u
[ "$(id -u)" = 0 ] || exec sudo bash "$0" "$@"
say() { printf '\n==> %s\n' "$*"; }
M=/mnt/vitrea-fix
mkdir -p $M
umount -R $M 2>/dev/null

# the USB stick we're running from is not a candidate
usb=$(lsblk -no PKNAME "$(findmnt -no SOURCE /run/archiso/bootmnt 2>/dev/null)" 2>/dev/null)

say "Looking for the installed Vitrea..."
root=""
for p in $(lsblk -lnpo NAME,FSTYPE | awk '$2=="ext4" || $2=="btrfs" || $2=="xfs" {print $1}'); do
    [ -n "$usb" ] && [ "$(lsblk -no PKNAME "$p")" = "$usb" ] && continue
    opts=""; [ "$(lsblk -no FSTYPE "$p")" = btrfs ] && opts="-o subvol=@"
    mount $opts "$p" $M 2>/dev/null || continue
    if grep -qs 'Vitrea' $M/etc/os-release; then root=$p; break; fi
    umount $M
done
[ -n "$root" ] || { echo "Couldn't find an installed Vitrea on this computer."; exit 1; }
disk=/dev/$(lsblk -no PKNAME "$root")
esp=$(lsblk -lnpo NAME,PARTTYPE "$disk" | awk 'tolower($2)=="c12a7328-f81f-11d2-ba4b-00a0c93ec93b" {print $1; exit}')
[ -n "$esp" ] || { echo "No EFI system partition on $disk."; umount $M; exit 1; }
echo "Vitrea: $root   EFI partition: $esp"
mkdir -p $M/boot/efi && mount "$esp" $M/boot/efi || { echo "Couldn't mount $esp"; exit 1; }
if [ "$(lsblk -no FSTYPE "$root")" = btrfs ]; then
    for sv in home:@home "var/cache:@cache" "var/log:@log"; do
        mkdir -p "$M/${sv%%:*}"; mount -o subvol="${sv#*:}" "$root" "$M/${sv%%:*}" 2>/dev/null
    done
fi

say "Rebuilding the startup files and the boot loader..."
if command -v arch-chroot >/dev/null; then
    CH="arch-chroot $M"
else
    for d in proc sys dev run; do mkdir -p $M/$d; done
    mount -t proc proc $M/proc; mount --rbind /sys $M/sys; mount --rbind /dev $M/dev; mount --bind /run $M/run
    CH="chroot $M"
fi
$CH /bin/bash -e <<'IN'
sed -i -E '/^MODULES=/ s/\bcrc32c[-_]intel\b//g' /etc/mkinitcpio.conf
for k in /usr/lib/modules/*/; do
    [ -f "$k/vmlinuz" ] && [ -f "$k/pkgbase" ] && install -Dm644 "$k/vmlinuz" "/boot/vmlinuz-$(cat "$k/pkgbase")"
done
mkinitcpio -P
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Vitrea --recheck || true
grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable --recheck
grub-mkconfig -o /boot/grub/grub.cfg
IN
rc=$?
ls -la $M/boot/efi/EFI/BOOT/ 2>/dev/null
sync; umount -R $M 2>/dev/null || umount -lR $M
if [ $rc = 0 ] && [ -n "$esp" ]; then
    say "Done. Shut down, take out the USB stick and turn the computer on."
else
    say "Something went wrong (see above). Send a photo of this screen."
fi
