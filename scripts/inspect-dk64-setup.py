#!/usr/bin/env python3
"""Print object coordinates from a DK64 map setup in a decompressed ROM."""

from __future__ import annotations

import argparse
import struct
import zlib
from pathlib import Path


POINTER_TABLE_BASE = 0x101C50
SETUP_TABLE = 9


def be_u16(data: bytes, offset: int) -> int:
    return struct.unpack_from(">H", data, offset)[0]


def be_u32(data: bytes, offset: int) -> int:
    return struct.unpack_from(">I", data, offset)[0]


def be_f32(data: bytes, offset: int) -> float:
    return struct.unpack_from(">f", data, offset)[0]


def setup_slice(rom: bytes, map_id: int) -> tuple[bytes, int, int]:
    table_relative = be_u32(rom, POINTER_TABLE_BASE + SETUP_TABLE * 4)
    table_start = POINTER_TABLE_BASE + table_relative
    entry = table_start + map_id * 4
    start = POINTER_TABLE_BASE + (be_u32(rom, entry) & 0x7FFFFFFF)
    end = POINTER_TABLE_BASE + (be_u32(rom, entry + 4) & 0x7FFFFFFF)
    if not 0 <= start <= end <= len(rom):
        raise ValueError(f"invalid setup bounds: {start:#x}..{end:#x}")
    data = rom[start:end]
    if data.startswith(b"\x1f\x8b"):
        data = zlib.decompress(data, 15 + 32)
    return data, start, end


def print_setup(data: bytes, map_id: int, start: int, end: int) -> None:
    print(f"map={map_id} rom={start:#x}..{end:#x} bytes={len(data)}")

    model2_count = be_u32(data, 0)
    print(f"model2_count={model2_count}")
    cursor = 4
    for index in range(model2_count):
        offset = cursor + index * 0x30
        x, y, z, scale = struct.unpack_from(">ffff", data, offset)
        object_type = be_u16(data, offset + 0x28)
        object_id = be_u16(data, offset + 0x2A)
        print(
            f"model2[{index:3}] type={object_type:4} id={object_id:4} "
            f"xyz=({x:9.3f}, {y:9.3f}, {z:9.3f}) scale={scale:.3f}"
        )

    cursor += model2_count * 0x30
    mystery_count = be_u32(data, cursor)
    print(f"mystery_count={mystery_count}")
    cursor += 4 + mystery_count * 0x24

    actor_count = be_u32(data, cursor)
    print(f"actor_count={actor_count}")
    cursor += 4
    for index in range(actor_count):
        offset = cursor + index * 0x38
        x, y, z = struct.unpack_from(">fff", data, offset)
        actor_type = be_u16(data, offset + 0x32)
        actor_id = be_u16(data, offset + 0x34)
        print(
            f"actor [{index:3}] type={actor_type:4} id={actor_id:4} "
            f"xyz=({x:9.3f}, {y:9.3f}, {z:9.3f})"
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("rom", type=Path, help="decompressed big-endian DK64 ROM")
    parser.add_argument("map_id", type=int, nargs="+", help="decimal map ID")
    args = parser.parse_args()

    rom = args.rom.read_bytes()
    for index, map_id in enumerate(args.map_id):
        if index:
            print()
        data, start, end = setup_slice(rom, map_id)
        print_setup(data, map_id, start, end)


if __name__ == "__main__":
    main()
