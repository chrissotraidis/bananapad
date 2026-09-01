#!/usr/bin/env python3
"""Print loading-zone and cutscene-trigger coordinates from a DK64 ROM."""

from __future__ import annotations

import argparse
import struct
import zlib
from pathlib import Path


POINTER_TABLE_BASE = 0x101C50
TRIGGER_TABLE = 18


def be_u16(data: bytes, offset: int) -> int:
    return struct.unpack_from(">H", data, offset)[0]


def be_i16(data: bytes, offset: int) -> int:
    return struct.unpack_from(">h", data, offset)[0]


def be_u32(data: bytes, offset: int) -> int:
    return struct.unpack_from(">I", data, offset)[0]


def trigger_slice(rom: bytes, map_id: int) -> tuple[bytes, int, int]:
    table_relative = be_u32(rom, POINTER_TABLE_BASE + TRIGGER_TABLE * 4)
    table_start = POINTER_TABLE_BASE + table_relative
    entry = table_start + map_id * 4
    start = POINTER_TABLE_BASE + (be_u32(rom, entry) & 0x7FFFFFFF)
    end = POINTER_TABLE_BASE + (be_u32(rom, entry + 4) & 0x7FFFFFFF)
    data = rom[start:end]
    if data.startswith(b"\x1f\x8b"):
        data = zlib.decompress(data, 15 + 32)
    return data, start, end


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("rom", type=Path, help="big-endian DK64 ROM")
    parser.add_argument("map_id", type=int, nargs="+", help="decimal map ID")
    args = parser.parse_args()

    rom = args.rom.read_bytes()
    for map_index, map_id in enumerate(args.map_id):
        data, start, end = trigger_slice(rom, map_id)
        if map_index:
            print()
        count = be_u16(data, 0)
        print(f"map={map_id} rom={start:#x}..{end:#x} bytes={len(data)} count={count}")
        for index in range(count):
            offset = 2 + index * 0x38
            x, y, z = (be_i16(data, offset + axis * 2) for axis in range(3))
            radius = be_u16(data, offset + 0x06)
            height = be_u16(data, offset + 0x08)
            object_type = be_i16(data, offset + 0x10)
            destination_map = be_u16(data, offset + 0x12)
            destination_exit = be_u16(data, offset + 0x14)
            print(
                f"trigger[{index:3}] type={object_type:3} xyz=({x:6}, {y:6}, {z:6}) "
                f"radius={radius:4} height={height:4} "
                f"destination=({destination_map}, {destination_exit})"
            )


if __name__ == "__main__":
    main()
