#!/usr/bin/env python3

import sys
import gzip
import hashlib

cfg = sys.stdin.buffer.read()
cfg = gzip.compress(cfg)

header = [
    "cfg",
    "128",
    str(len(cfg)),
    hashlib.sha256(cfg).hexdigest(),
    ""
]
header = "\n".join(header)
header = header.encode("utf-8")

final = b""
final += header
final += b"\0" * (128 - len(header))
final += cfg
pad = 16 - (len(final) % 16)
pad = 16 if pad == 0 else pad
final += b"\0" * pad

sys.stdout.buffer.write(final)
