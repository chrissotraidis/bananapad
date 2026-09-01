"""LLDB command script for inspecting DK64's live actor list.

Usage from an attached LLDB session:
    command script import scripts/lldb_dump_dk64_actors.py
    dk64-actors

This is a read-only diagnostic. Its output is not gameplay acceptance evidence.
"""

from __future__ import annotations

import lldb
import struct


RDRAM_BASE = 0x300000000
ACTOR_LIST = RDRAM_BASE + 0x7FBFF0
# N64 halfwords are XOR-2 addressed inside the word-swapped RDRAM image.
ACTOR_COUNT = RDRAM_BASE + 0x7FC3F0 + 2


def _read(process: lldb.SBProcess, address: int, size: int) -> bytes:
    error = lldb.SBError()
    data = process.ReadMemory(address, size, error)
    if error.Fail() or len(data) != size:
        raise RuntimeError(f"could not read {size} bytes at 0x{address:x}: {error}")
    return data


def _u16(process: lldb.SBProcess, address: int) -> int:
    return struct.unpack("<H", _read(process, address, 2))[0]


def _s16(process: lldb.SBProcess, address: int) -> int:
    return struct.unpack("<h", _read(process, address, 2))[0]


def _u32(process: lldb.SBProcess, address: int) -> int:
    return struct.unpack("<I", _read(process, address, 4))[0]


def _f32(process: lldb.SBProcess, address: int) -> float:
    return struct.unpack("<f", _read(process, address, 4))[0]


def dump_actors(debugger: lldb.SBDebugger, _command: str, result: lldb.SBCommandReturnObject, _dict: dict) -> None:
    process = debugger.GetSelectedTarget().GetProcess()
    if not process.IsValid():
        result.SetError("no valid process")
        return

    try:
        count = _u16(process, ACTOR_COUNT)
        if count > 256:
            raise RuntimeError(f"invalid actor count {count}")

        result.AppendMessage("index type pointer    x         y         z")
        for index in range(count):
            guest_pointer = _u32(process, ACTOR_LIST + index * 4)
            if guest_pointer in (0, 0xFFFFFFFF):
                continue
            host_pointer = RDRAM_BASE + (guest_pointer & 0xFFFFFF)
            actor_type = _s16(process, host_pointer + 0x58)
            x = _f32(process, host_pointer + 0x7C)
            y = _f32(process, host_pointer + 0x80)
            z = _f32(process, host_pointer + 0x84)
            result.AppendMessage(
                f"{index:5d} {actor_type:4d} 0x{guest_pointer:08x} "
                f"{x:9.3f} {y:9.3f} {z:9.3f}"
            )
    except (RuntimeError, struct.error) as error:
        result.SetError(str(error))


def __lldb_init_module(debugger: lldb.SBDebugger, _dict: dict) -> None:
    debugger.HandleCommand("command script add -f lldb_dump_dk64_actors.dump_actors dk64-actors")
    print("Installed LLDB command: dk64-actors")
