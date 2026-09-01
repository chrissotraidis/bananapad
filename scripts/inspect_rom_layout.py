#!/usr/bin/env python3

from __future__ import annotations

import argparse
import gzip
import json
from pathlib import Path


OVERLAYS = (
    ("global_asm", 0x113F0, 0xC29D4, 0x949C),
    ("menu", 0xCBE70, 0xD4554, 0x5A2),
    ("multiplayer", 0xD4B00, 0xD69F8, 0xFB),
    ("minecart", 0xD6B00, 0xD98A0, 0x197),
    ("bonus", 0xD9A40, 0xDF346, 0x2AB),
    ("race", 0xDF600, 0xE649A, 0x2DB),
    ("critter", 0xE6780, 0xE9D17, 0x38C),
    ("boss", 0xEA0B0, 0xF388F, 0x90A),
    ("arcade", 0xF41A0, 0xFB42C, 0x1EC4),
    ("jetpac", 0xFD2F0, 0x1010FD, 0x936),
)


def align16(value: int) -> int:
    return (value + 0xF) & ~0xF


def main() -> int:
    parser = argparse.ArgumentParser(description="Derive DK64 decompressed overlay layout from a verified normalized ROM")
    parser.add_argument("rom", type=Path)
    args = parser.parse_args()
    data = args.rom.read_bytes()
    cursor = 0x2000000
    records = []
    for name, code_start, data_start, data_size in OVERLAYS:
        code = gzip.decompress(data[code_start:data_start])
        overlay_data = gzip.decompress(data[data_start:data_start + data_size])
        cursor = align16(cursor)
        decompressed_code_start = cursor
        cursor += len(code)
        cursor = align16(cursor)
        decompressed_data_start = cursor
        cursor += len(overlay_data)
        records.append({
            "name": name,
            "compressedCodeStart": f"0x{code_start:X}",
            "compressedDataStart": f"0x{data_start:X}",
            "compressedDataSize": f"0x{data_size:X}",
            "decompressedCodeStart": f"0x{decompressed_code_start:X}",
            "decompressedCodeSize": f"0x{len(code):X}",
            "decompressedDataStart": f"0x{decompressed_data_start:X}",
            "decompressedDataSize": f"0x{len(overlay_data):X}",
            "end": f"0x{cursor:X}",
        })
    print(json.dumps({"finalLength": cursor, "finalLengthHex": f"0x{cursor:X}", "overlays": records}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
