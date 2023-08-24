#!/usr/bin/env python3

import struct
import sys

fsize = int(sys.argv[1]) if len(sys.argv) >= 2 else 1
for i in range((fsize << 20) >> 4):
    sys.stdout.buffer.write(struct.pack(">4I", i, 0xdeadbeef, 0xdeadb11f, 0xdeadb22f))
