#!/usr/bin/env python3

import struct
import sys


start_offset = None
end_offset = None

with open(sys.argv[1], "rb") as fh:
    while True:
        tmp = fh.read(16)
        if len(tmp) != 16:
            break
        a, b, c, d = struct.unpack(">4I", tmp)
        has_static_pattern = b == 0xdeadbeef and c == 0xdeadb11f and d == 0xdeadb22f
        if start_offset is None and has_static_pattern and a == 0:
            start_offset = fh.tell() - 16
        if start_offset is not None and has_static_pattern:
            end_offset = fh.tell()
            assert end_offset - start_offset == (a+1) * 16
        if start_offset is not None and not has_static_pattern:
            break

assert start_offset is not None and end_offset is not None and end_offset - start_offset >= (1 << 14)
print(f"{start_offset} {end_offset-start_offset}")
