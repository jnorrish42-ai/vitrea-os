#!/usr/bin/env python3
"""Click in the test VM via QMP absolute pointer events.
Usage: vm-click.py QA_DIR X Y [--double] [--right] [--screen 1280x800]"""
import json, socket, sys, time
d, x, y = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
sw, sh = 1280, 800
if '--screen' in sys.argv:
    sw, sh = map(int, sys.argv[sys.argv.index('--screen') + 1].split('x'))
btn = 'right' if '--right' in sys.argv else 'left'
s = socket.socket(socket.AF_UNIX); s.connect(f'{d}/qmp.sock'); f = s.makefile('rw')
f.readline()
def cmd(c, a=None):
    f.write(json.dumps({'execute': c, **({'arguments': a} if a else {})}) + '\n'); f.flush()
    while True:
        r = json.loads(f.readline())
        if 'return' in r or 'error' in r: return r
cmd('qmp_capabilities')
ev = lambda evs: cmd('input-send-event', {'events': evs})
ev([{'type': 'abs', 'data': {'axis': 'x', 'value': int(x * 32767 / (sw - 1))}},
    {'type': 'abs', 'data': {'axis': 'y', 'value': int(y * 32767 / (sh - 1))}}])
time.sleep(0.15)
for _ in range(2 if '--double' in sys.argv else 1):
    ev([{'type': 'btn', 'data': {'down': True, 'button': btn}}]); time.sleep(0.08)
    ev([{'type': 'btn', 'data': {'down': False, 'button': btn}}]); time.sleep(0.12)
