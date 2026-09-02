#!/usr/bin/env python3

import importlib.util
from pathlib import Path
import unittest
import zlib


SCRIPT = Path(__file__).with_name("inject-dk64-save-slot.py")
SPEC = importlib.util.spec_from_file_location("save_slot_injector", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
INJECTOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(INJECTOR)


def make_image(markers: list[int], fill: int) -> bytes:
    image = bytearray([fill] * INJECTOR.EEPROM_SIZE)
    for physical, logical in enumerate(markers):
        start = physical * INJECTOR.BLOCK_SIZE
        end = start + INJECTOR.BLOCK_SIZE
        block = bytearray(image[start:end])
        block[INJECTOR.FILE_INDEX_BYTE] = (
            block[INJECTOR.FILE_INDEX_BYTE] & ~INJECTOR.FILE_INDEX_MASK
        ) | (logical << 2)
        block[INJECTOR.BLOCK_DATA_SIZE : INJECTOR.BLOCK_SIZE] = (
            zlib.crc32(block[: INJECTOR.BLOCK_DATA_SIZE]) & 0xFFFFFFFF
        ).to_bytes(4, "big")
        image[start:end] = block
    return bytes(image)


class SaveSlotInjectorTests(unittest.TestCase):
    def test_remaps_only_requested_logical_slot(self) -> None:
        target = make_image([0, 1, 2, 3], 0x11)
        donor = make_image([1, 2, 3, 0], 0xA5)[:0x700]
        output, source_physical, target_physical = INJECTOR.inject(target, donor, 1, 2)

        self.assertEqual(source_physical, 3)
        self.assertEqual(target_physical, 1)
        start = target_physical * INJECTOR.BLOCK_SIZE
        end = start + INJECTOR.BLOCK_SIZE
        self.assertEqual(output[:start], target[:start])
        self.assertEqual(output[end:], target[end:])
        self.assertEqual(
            (output[start + INJECTOR.FILE_INDEX_BYTE] & INJECTOR.FILE_INDEX_MASK) >> 2,
            1,
        )
        INJECTOR.split_blocks(output, "test output")


if __name__ == "__main__":
    unittest.main()
