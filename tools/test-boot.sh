#!/bin/bash
# Boot the ISO in QEMU (headless) and take a screenshot every 20 s.
#   ./test-boot.sh ISO OUTDIR [bios|uefi] [seconds]
# Send keys meanwhile with:  echo "sendkey ret" | socat - UNIX-CONNECT:OUTDIR/mon.sock
set -euo pipefail
ISO=$1; OUT=$2; MODE=${3:-bios}; SECS=${4:-900}
mkdir -p "$OUT"
SOCK=$OUT/mon.sock; rm -f "$SOCK"
FW=()
if [ "$MODE" = uefi ]; then
  cp /usr/share/OVMF/OVMF_VARS_4M.fd "$OUT/vars.fd"
  FW=(-machine q35
      -drive if=pflash,format=raw,unit=0,file=/usr/share/OVMF/OVMF_CODE_4M.fd,readonly=on
      -drive if=pflash,format=raw,unit=1,file="$OUT/vars.fd")
fi
DISK=()
[ -n "${DISK_IMG:-}" ] && DISK=(-drive file="$DISK_IMG",if=virtio,format=qcow2)
ACCEL=tcg,thread=multi; [ -e /dev/kvm ] && ACCEL=kvm
qemu-system-x86_64 "${FW[@]}" -accel $ACCEL -cpu max -smp 4 -m 6144 \
  -cdrom "$ISO" "${DISK[@]}" -boot d -vga ${VGA:-std} -display none \
  -monitor unix:$SOCK,server,nowait -serial file:$OUT/serial.log \
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
