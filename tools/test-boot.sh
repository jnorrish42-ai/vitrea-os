#!/bin/bash
# Boot the ISO in QEMU (headless) and take a screenshot every 20 s.
#   ./test-boot.sh ISO OUTDIR [bios|uefi] [seconds]
#   DISK_IMG=disk.qcow2 ./test-boot.sh ISO OUTDIR uefi     -> live ISO + target disk
#   BOOT_DISK=1 DISK_IMG=disk.qcow2 ./test-boot.sh - OUTDIR uefi -> boot the installed disk
# Send keys meanwhile with:  echo "sendkey ret" | socat - UNIX-CONNECT:OUTDIR/mon.sock
set -euo pipefail
ISO=$1; OUT=$2; MODE=${3:-bios}; SECS=${4:-900}
mkdir -p "$OUT"
SOCK=$OUT/mon.sock; rm -f "$SOCK" "$OUT/qmp.sock"
FW=()
if [ "$MODE" = uefi ]; then
  [ -f "$OUT/vars.fd" ] || cp /usr/share/OVMF/OVMF_VARS_4M.fd "$OUT/vars.fd"
  FW=(-machine q35
      -drive if=pflash,format=raw,unit=0,file=/usr/share/OVMF/OVMF_CODE_4M.fd,readonly=on
      -drive if=pflash,format=raw,unit=1,file="$OUT/vars.fd")
fi
DISK=()
[ -n "${DISK_IMG:-}" ] && DISK=(-drive file="$DISK_IMG",if=virtio,format=qcow2)
# Under TCG, use a self-consistent CPU model without AVX2: QEMU 8.x mis-emulates masked
# AVX2 gathers, which crashes Mesa llvmpipe (and with it kwin_wayland + the installer).
# ("max,avx2=off" is not enough: Qt then picks VAES paths and dies with SIGILL.)
ACCEL=tcg,thread=multi; CPU=${CPU:-SandyBridge}
[ -e /dev/kvm ] && { ACCEL=kvm; CPU=${CPU_KVM:-host}; }
MEDIA=(-cdrom "$ISO" -boot d)
[ -n "${BOOT_DISK:-}" ] && MEDIA=(-boot c)
qemu-system-x86_64 "${FW[@]}" -accel $ACCEL -cpu $CPU -smp 4 -m 6144 \
  "${MEDIA[@]}" "${DISK[@]}" -vga ${VGA:-std} -display none \
  -monitor unix:$SOCK,server,nowait -qmp unix:$OUT/qmp.sock,server,nowait -serial file:$OUT/serial.log \
  -nic user,model=virtio-net-pci -device virtio-tablet-pci -device virtio-keyboard-pci &
QPID=$!
echo $QPID > "$OUT/qemu.pid"
start=$(date +%s)
while kill -0 $QPID 2>/dev/null; do
  t=$(( $(date +%s) - start )); [ $t -ge $SECS ] && break
  printf -v f "%s/shot-%04d.ppm" "$OUT" $t
  echo "screendump $f" | socat - UNIX-CONNECT:$SOCK >/dev/null 2>&1 || true
  sleep 20
done
