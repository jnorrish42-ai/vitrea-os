#!/usr/bin/env python3
"""Type text into a QEMU VM via its monitor socket: vm-type.py SOCK 'text' [--enter]"""
import socket, sys, time
sock, text = sys.argv[1], sys.argv[2]
m = {' ': 'spc', '\n': 'ret', '-': 'minus', '=': 'equal', '/': 'slash', '.': 'dot', ',': 'comma',
     ';': 'semicolon', "'": 'apostrophe', '\\': 'backslash', '[': 'bracket_left', ']': 'bracket_right', '`': 'grave_accent'}
shift = {'|': 'backslash', '_': 'minus', '+': 'equal', ':': 'semicolon', '"': 'apostrophe', '>': 'dot', '<': 'comma',
         '?': 'slash', '!': '1', '@': '2', '#': '3', '$': '4', '%': '5', '^': '6', '&': '7', '*': '8', '(': '9', ')': '0',
         '{': 'bracket_left', '}': 'bracket_right', '~': 'grave_accent'}
def keys(ch):
    if ch in m: return m[ch]
    if ch in shift: return 'shift-' + shift[ch]
    if ch.isupper(): return 'shift-' + ch.lower()
    return ch
s = socket.socket(socket.AF_UNIX); s.connect(sock); s.recv(4096)
seq = [keys(c) for c in text] + (['ret'] if '--enter' in sys.argv else [])
for k in seq:
    s.send(f'sendkey {k}\n'.encode()); time.sleep(0.08)
time.sleep(0.3); s.close()
