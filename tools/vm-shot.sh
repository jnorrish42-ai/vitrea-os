#!/bin/bash
# vm-shot.sh QA_DIR OUT.png  -> immediate screenshot of the running test VM
D=$(cd "$1" && pwd); rm -f "$D/now.ppm"
echo "screendump $D/now.ppm" | socat - UNIX-CONNECT:"$D/mon.sock" >/dev/null
for i in $(seq 20); do [ -s "$D/now.ppm" ] && break; sleep 0.5; done
python3 -c "from PIL import Image; Image.open('$D/now.ppm').save('$2')"
