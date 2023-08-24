#!/usr/bin/env python3

import sys
import os
import shutil
import re
import glob


src_dir = os.path.abspath(sys.argv[1])
tgt_dir = os.path.abspath(sys.argv[2])
kmod_ctr = 0

# read paths to process
for file in sys.stdin.readlines():
    file = file.strip()
    if not file.startswith("./"):
        continue

    # expand globs, if any
    if "*" in file:
        r = glob.glob(file, root_dir=src_dir)
        assert len(r) == 1
        file = r[0]

    src_fpath = os.path.abspath(os.path.join(src_dir, file))
    src_dirname = os.path.dirname(src_fpath)
    src_filename = os.path.basename(src_fpath)

    tgt_fpath = os.path.abspath(os.path.join(tgt_dir, file))
    tgt_link = None
    # special handling for modules
    if src_filename.endswith(".ko.gz"):
        tgt_fpath = os.path.abspath(os.path.join(tgt_dir, "lib/modules", src_filename))
        kmod_ctr += 1
        tgt_link = os.path.abspath(os.path.join(tgt_dir, "lib/modules", f"ko_{kmod_ctr:02d}"))

    # create links for libraries
    if re.match(r"^.+\.so\.\d+\.\d+\.\d+$", src_filename):
        # only keep first version number
        tmp = src_filename.split(".")
        tmp = ".".join(tmp[:-2])
        tgt_link = os.path.abspath(os.path.join(os.path.dirname(tgt_fpath), tmp))

    # copy file to target directory
    os.makedirs(os.path.dirname(tgt_fpath), exist_ok=True)
    shutil.copy(src_fpath, tgt_fpath)

    # create symlink, if any
    if tgt_link is not None:
        os.symlink(src_filename, tgt_link)
