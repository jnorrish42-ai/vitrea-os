#!/usr/bin/env python3
"""Keep the test VM display awake: nudge the pointer every N seconds. Usage: vm-jiggle.py QA_DIR [seconds]"""
import json, socket, sys, time
d = sys.argv[1]; every = int(sys.argv[2]) if len(sys.argv) > 2 else 240
while True:
    try:
        s = socket.socket(socket.AF_UNIX); s.connect(f'{d}/qmp.sock'); f = s.makefile('rw'); f.readline()
        f.write(json.dumps({'execute': 'qmp_capabilities'}) + '\n'); f.flush(); f.readline()
        for x in (20000, 20100):
            f.write(json.dumps({'execute': 'input-send-event', 'arguments': {'events': [
                {'type': 'abs', 'data': {'axis': 'x', 'value': x}}, {'type': 'abs', 'data': {'axis': 'y', 'value': 31000}}]}}) + '\n')
            f.flush(); f.readline(); time.sleep(0.3)
        f.close(); s.close()
    except OSError:
        pass
    time.sleep(every)
