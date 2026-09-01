# BananaPad ROM inputs

Last updated: 2026-08-31

## Boundary

The original user-supplied ROM is immutable and remains under ignored `ref/`. G1 creates a separate ignored normalized big-endian working copy. The app accepts that standard verified ROM at runtime. A distinct ignored decompressed ROM is produced only for N64Recomp/RSPRecomp generation and is never selected in the app.

## Original input record

| Field | Value |
|---|---|
| Filename | `Donkey Kong 64 (U) [!].v64` |
| Detected byte order | V64 / byte-swapped |
| Length | 33,554,432 bytes (`0x2000000`) |
| SHA-1 | `3ead7798284c0593d8c91e09923cde03e87c6b09` |
| SHA-256 | `5778c9ef72ef269cdcc52333710a79961a343b1f01d12189d1dbe94df3cbabed` |
| Original modified | No |

## Required normalized identity

| Field | Required value |
|---|---|
| Byte order | Z64 / big-endian |
| Length | 33,554,432 bytes (`0x2000000`) |
| SHA-1 | `cf806ff2603640a748fca5026ded28802f1f4a50` |
| Internal identity | `DONKEY KONG 64`, US/NTSC-U 1.0; exact runtime checks still to be recorded from the pinned source |

## Verified derived identities

| Output | Length | SHA-1 | SHA-256 |
|---|---:|---|---|
| Ignored normalized standard ROM | 33,554,432 | `cf806ff2603640a748fca5026ded28802f1f4a50` | `b6347d9f1f75d38a88d829b4f80b1acf0d93344170a5fbe9546c484dae416ce3` |
| Ignored decompressed build ROM | 35,513,184 (`0x21DE360`) | `c2067ea456b8c95bd70bf5725e271c5d041d9825` | `04bca239f17380aa2a97e8f04715a09f1f05b74df9c057b609558408fd39c91a` |

Normalization detected V64 and swapped adjacent byte pairs into an atomic mode-`0600` working copy. The normalized header is `DONKEY KONG 64` / `NDOE`. The decompressor ran twice in isolated directories and the outputs matched byte for byte.

## Derived overlay layout

| Class | Compressed trigger | Code start / size | Data start / size | End |
|---|---:|---:|---:|---:|
| `global_asm` | `0x113F0` | `0x2000000` / `0x149160` | `0x2149160` / `0x1CBF0` | `0x2165D50` |
| `menu` | `0xCBE70` | `0x2165D50` / `0xEF50` | `0x2174CA0` / `0xFC0` | `0x2175C60` |
| `multiplayer` | `0xD4B00` | `0x2175C60` / `0x2F70` | `0x2178BD0` / `0x190` | `0x2178D60` |
| `minecart` | `0xD6B00` | `0x2178D60` / `0x4B90` | `0x217D8F0` / `0x280` | `0x217DB70` |
| `bonus` | `0xD9A40` | `0x217DB70` / `0x9860` | `0x21873D0` / `0x690` | `0x2187A60` |
| `race` | `0xDF600` | `0x2187A60` / `0xBB10` | `0x2193570` / `0x650` | `0x2193BC0` |
| `critter` | `0xE6780` | `0x2193BC0` / `0x57F0` | `0x21993B0` / `0x9C0` | `0x2199D70` |
| `boss` | `0xEA0B0` | `0x2199D70` / `0x118B0` | `0x21AB620` / `0x1510` | `0x21ACB30` |
| `arcade` | `0xF41A0` | `0x21ACB30` / `0xE220` | `0x21BAD50` / `0x189E0` | `0x21D3730` |
| `jetpac` | `0xFD2F0` | `0x21D3730` / `0x7090` | `0x21DA7C0` / `0x3BA0` | `0x21DE360` |

The table is derived by `scripts/inspect_rom_layout.py` from the pinned decompressor boundaries and the verified normalized ROM. Wrong hashes stop the pipeline; they are never bypassed or repaired by downloading replacement game data.
