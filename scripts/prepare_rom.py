#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import tempfile


ROM_SIZE = 0x2000000
EXPECTED_SHA1 = "cf806ff2603640a748fca5026ded28802f1f4a50"
MAGIC_Z64 = bytes.fromhex("80371240")
MAGIC_V64 = bytes.fromhex("37804012")
MAGIC_N64 = bytes.fromhex("40123780")


def convert_chunk(chunk: bytes, byte_order: str) -> bytes:
    if byte_order == "z64":
        return chunk
    if byte_order == "v64":
        if len(chunk) % 2:
            raise ValueError("V64 input length is not divisible by two")
        converted = bytearray(chunk)
        converted[0::2], converted[1::2] = chunk[1::2], chunk[0::2]
        return bytes(converted)
    if byte_order == "n64":
        if len(chunk) % 4:
            raise ValueError("N64 input length is not divisible by four")
        converted = bytearray(len(chunk))
        converted[0::4] = chunk[3::4]
        converted[1::4] = chunk[2::4]
        converted[2::4] = chunk[1::4]
        converted[3::4] = chunk[0::4]
        return bytes(converted)
    raise ValueError(f"unsupported byte order: {byte_order}")


def identify(magic: bytes) -> str:
    if magic == MAGIC_Z64:
        return "z64"
    if magic == MAGIC_V64:
        return "v64"
    if magic == MAGIC_N64:
        return "n64"
    raise ValueError(f"unrecognized Nintendo 64 byte-order magic: {magic.hex()}")


def digest(path: Path, algorithm: str) -> str:
    hasher = hashlib.new(algorithm)
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description="Normalize a private DK64 ROM copy to verified big-endian Z64")
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()

    source = args.source.expanduser().resolve(strict=True)
    destination = args.destination.expanduser().resolve(strict=False)
    if source == destination:
        raise SystemExit("refusing to overwrite the original ROM")
    if source.stat().st_size != ROM_SIZE:
        raise SystemExit(f"wrong ROM size: {source.stat().st_size}; expected {ROM_SIZE}")

    with source.open("rb") as stream:
        byte_order = identify(stream.read(4))

    destination.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary_name = tempfile.mkstemp(prefix=".normalized-", suffix=".z64", dir=destination.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(fd, "wb") as output, source.open("rb") as input_stream:
            while chunk := input_stream.read(1024 * 1024):
                output.write(convert_chunk(chunk, byte_order))
            output.flush()
            os.fsync(output.fileno())
        os.chmod(temporary, 0o600)

        sha1 = digest(temporary, "sha1")
        if temporary.stat().st_size != ROM_SIZE or sha1 != EXPECTED_SHA1:
            raise ValueError(
                f"normalized ROM identity mismatch: size={temporary.stat().st_size} sha1={sha1}"
            )

        with temporary.open("rb") as stream:
            header = stream.read(0x40)
        internal_name = header[0x20:0x34].decode("ascii", errors="replace").rstrip(" \x00")
        identity = header[0x3B:0x3F].decode("ascii", errors="replace")
        if internal_name != "DONKEY KONG 64" or identity != "NDOE":
            raise ValueError(f"unexpected normalized header: name={internal_name!r} identity={identity!r}")

        os.replace(temporary, destination)
        print(f"source-byte-order={byte_order}")
        print(f"normalized={destination}")
        print(f"size={destination.stat().st_size}")
        print(f"sha1={sha1}")
        print(f"sha256={digest(destination, 'sha256')}")
        print(f"internal-name={internal_name}")
        print(f"identity={identity}")
    except BaseException:
        temporary.unlink(missing_ok=True)
        raise

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
