#!/usr/bin/env python3

#
# This file is part of LiteX.
#
# Copyright (c) 2020-2022 Florent Kermarrec <florent@enjoy-digital.fr>
# SPDX-License-Identifier: BSD-2-Clause

import os
import argparse

from litex.build.tools import replace_in_file

def main():
    parser = argparse.ArgumentParser(description="LiteX Bare Metal Demo App.")
    parser.add_argument("--build-path",                      help="Target's build path (ex build/board_name).", required=True)
    parser.add_argument("--with-cxx",   action="store_true", help="Enable CXX support.")
    parser.add_argument("--mem",        default="main_ram",  help="Memory Region where code will be loaded/executed.")
    args = parser.parse_args()

    os.system("reset")

    # Create demo directory
    os.makedirs("firmware", exist_ok=True)

    # Copy contents to demo directory
    os.system(f"cp -r {os.path.abspath(os.path.dirname(__file__))}/* firmware")

    # Update memory region.
    replace_in_file("firmware/linker.ld", "main_ram", args.mem)

    # Compile demo
    build_path = args.build_path if os.path.isabs(args.build_path) else os.path.join("..", args.build_path)
    os.system(f"export BUILD_DIR={build_path} && {'export WITH_CXX=1 &&' if args.with_cxx else ''} cd firmware && make")

    # Copy demo.bin
    os.system("cp firmware/firmware.bin ./")

    # rm -rf firmware
    os.system("rm -rf firmware")

if __name__ == "__main__":
    main()

