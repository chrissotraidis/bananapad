#!/usr/bin/env python3

"""Copy one DK64 EEPROM game slot into another without replacing other slots.

The input files are private runtime data and must stay outside source control.
DK64 stores four CRC-protected physical blocks: three visible game files and
one rotating temporary file. Each block records the logical file it owns, so
the physical order cannot be assumed.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import sys
import zlib


EEPROM_SIZE = 0x800
BLOCK_SIZE = 0x1AC
BLOCK_COUNT = 4
BLOCK_DATA_SIZE = BLOCK_SIZE - 4
FILE_INDEX_BYTE = 0x1A0
FILE_INDEX_MASK = 0x0C


def fail(message: str) -> "NoReturn":
    raise SystemExit(f"error: {message}")


def crc32(block_data: bytes) -> int:
    return zlib.crc32(block_data) & 0xFFFFFFFF


def split_blocks(image: bytes, label: str) -> list[bytes]:
    required = BLOCK_SIZE * BLOCK_COUNT
    if len(image) < required:
        fail(f"{label} is too short: expected at least {required} bytes, found {len(image)}")

    blocks = [image[index * BLOCK_SIZE : (index + 1) * BLOCK_SIZE] for index in range(BLOCK_COUNT)]
    logical_files: list[int] = []
    for physical_index, block in enumerate(blocks):
        expected = int.from_bytes(block[BLOCK_DATA_SIZE:BLOCK_SIZE], "big")
        actual = crc32(block[:BLOCK_DATA_SIZE])
        if actual != expected:
            fail(
                f"{label} physical block {physical_index} has an invalid CRC "
                f"(expected {expected:08x}, calculated {actual:08x})"
            )
        logical_files.append((block[FILE_INDEX_BYTE] & FILE_INDEX_MASK) >> 2)

    if sorted(logical_files) != list(range(BLOCK_COUNT)):
        fail(f"{label} does not contain one unique mapping for each DK64 file block: {logical_files}")
    return blocks


def physical_block_for(blocks: list[bytes], logical_file: int) -> int:
    for physical_index, block in enumerate(blocks):
        if ((block[FILE_INDEX_BYTE] & FILE_INDEX_MASK) >> 2) == logical_file:
            return physical_index
    fail(f"logical file {logical_file + 1} is not present")


def inject(target: bytes, donor: bytes, source_slot: int, target_slot: int) -> tuple[bytes, int, int]:
    if len(target) != EEPROM_SIZE:
        fail(f"target must be BananaPad's {EEPROM_SIZE}-byte Eep16k image, found {len(target)} bytes")

    target_blocks = split_blocks(target, "target")
    donor_blocks = split_blocks(donor, "donor")
    source_logical = source_slot - 1
    target_logical = target_slot - 1
    source_physical = physical_block_for(donor_blocks, source_logical)
    target_physical = physical_block_for(target_blocks, target_logical)

    replacement = bytearray(donor_blocks[source_physical])
    replacement[FILE_INDEX_BYTE] = (
        (replacement[FILE_INDEX_BYTE] & ~FILE_INDEX_MASK) | (target_logical << 2)
    )
    replacement[BLOCK_DATA_SIZE:BLOCK_SIZE] = crc32(replacement[:BLOCK_DATA_SIZE]).to_bytes(4, "big")

    output = bytearray(target)
    start = target_physical * BLOCK_SIZE
    end = start + BLOCK_SIZE
    output[start:end] = replacement

    # Re-parse the result and prove the requested physical block is the only
    # range changed. This guards the user's other saves and global settings.
    split_blocks(bytes(output), "output")
    if output[:start] != target[:start] or output[end:] != target[end:]:
        fail("bytes outside the destination game block changed")
    return bytes(output), source_physical, target_physical


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Copy a DK64 EEPROM game slot while preserving every other slot and global byte"
    )
    parser.add_argument("--target", required=True, type=Path, help="existing 2,048-byte BananaPad DK64.bin")
    parser.add_argument("--donor", required=True, type=Path, help="donor DK64 EEPROM image")
    parser.add_argument("--source-slot", required=True, type=int, choices=(1, 2, 3))
    parser.add_argument("--target-slot", required=True, type=int, choices=(1, 2, 3))
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    if args.output.exists():
        fail(f"refusing to overwrite existing output: {args.output}")
    target = args.target.read_bytes()
    donor = args.donor.read_bytes()
    output, source_physical, target_physical = inject(
        target, donor, args.source_slot, args.target_slot
    )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(output)
    print(f"target SHA-256: {sha256(target)}")
    print(f"donor SHA-256: {sha256(donor)}")
    print(f"output SHA-256: {sha256(output)}")
    print(
        f"copied donor Game {args.source_slot} physical block {source_physical} "
        f"to target Game {args.target_slot} physical block {target_physical}"
    )
    print("verified: all other game blocks and global bytes are unchanged")
    return 0


if __name__ == "__main__":
    sys.exit(main())
