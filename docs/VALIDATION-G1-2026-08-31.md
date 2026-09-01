# G1 validation — 2026-08-31

Goal: exact ROM and deterministic generated inputs.

## Result

**Pass.** The original ROM remained unchanged; normalization, decompression, game generation, patch generation, and audio-RSP generation produced identical results across two runs from pinned inputs. All products are ignored/private. This does not prove that the upstream or BananaPad app builds, launches, or plays.

## ROM identities

| Input/output | Length | SHA-1 | SHA-256 |
|---|---:|---|---|
| Original V64 | 33,554,432 | `3ead7798284c0593d8c91e09923cde03e87c6b09` | `5778c9ef72ef269cdcc52333710a79961a343b1f01d12189d1dbe94df3cbabed` |
| Normalized Z64 | 33,554,432 | `cf806ff2603640a748fca5026ded28802f1f4a50` | `b6347d9f1f75d38a88d829b4f80b1acf0d93344170a5fbe9546c484dae416ce3` |
| Decompressed build ROM | 35,513,184 (`0x21DE360`) | `c2067ea456b8c95bd70bf5725e271c5d041d9825` | `04bca239f17380aa2a97e8f04715a09f1f05b74df9c057b609558408fd39c91a` |

Normalized header checks: big-endian N64 magic, internal name `DONKEY KONG 64`, identity bytes `NDOE`. The original hashes were rechecked after generation and remained unchanged.

Pinned decompressor source SHA-256: `30065b5efdc00bb18d2a853dcbcd2e91c1c4a689828ed22a352d90fa75e5e0be`. Local decompressor executable SHA-256: `6a01e322bb4aa8deaed726d8e2dfb850a213fef45fc9e205162aadb639fc30da`.

## Configuration and symbol inputs

| Input | SHA-256 |
|---|---|
| `us.toml` | `a67794c6c2ebacf9f1ae636cabc5f7ed73e25bda38f001df25b3a14727d623cb` |
| `n_aspMain.toml` | `29f0bfe438bce3af43506aff5d23c2c9a4374398eb9051aaf99a028623fdc6a1` |
| `patches.toml` | `83ca9f0af6907edcf6b3afc9b974c3ff6af87166b2bffc66ebcbdcb8dffef9` |
| `DK64Syms/dump.toml` | `b1e217e3a89f202b0f1989dc132dd48c6a3042167fd55dac551470b8ef98fb92` |
| `DK64Syms/data_dump.toml` | `2c943deeff3ebbccf0e72ea96e53f0a3cc0f161ccea7f8ea23d95c2ad9eb2684` |

Host tools use released pin `2b6f05688de2abc7d86da5b4a89b84c2c6acbabe`; executable hashes are in the G0 validation.

## Deterministic generated output

| Output | Result |
|---|---|
| Game functions | 4,504 functions; 91 files; input identity `c2627a42563082c07431656b3c334f98fba39aca7f334c039056fdbbf7b81496` |
| Game/RSP manifest | `ae6c0ed0deb141a8ee15b3eeb62d73099558ea5b4d8f12fbd906661df62615c6` |
| `rsp/n_aspMain.cpp` | SHA-256 `da1aed4b6ea7306d8fef72475b9c8a12fa1f1e23bd8801e7e5b90f72fc3a819d` |
| Patch functions | 1,744 functions; three generated files; input identity `34daef613e0b8fceebd89057e080efe77b5cc63f514791a1e6eb6dac27eb1361` |
| Patch manifest | `2fdbd3ea3029ea6a28975b524d51a4a2302042fa1e7f3ea4c04d8347db0b7c35` |
| Patch ELF | SHA-256 `2cea93cb9c09e815ac238d7d3eed63de0b9f5e26e1e48c22da5c0a0a6c470fd8` |
| Patch binary/data | SHA-256 `50a403238b22af54af24a2c62c2130a327aaf410a414708acf6165d90e7cea49` |

Each generation script makes two isolated products and compares complete file manifests before promoting the content-addressed ignored set. `current-game` and `current-patches` are ignored symlinks to those sets.

## Warnings retained for interpretation

- N64Recomp reported an ambiguous `jal` target at shared overlay destination `0x80024000` in `func_global_asm_805FBFF4` and an indirect tail call in `recomp_entrypoint`. These are expected audit inputs for G3 overlay/indirect-call work, not silently suppressed warnings.
- The upstream MIPS patch sources compile with existing warnings including pointer signedness, unused/set-but-unused locals, signed comparisons, GCC attribute placement, and an apparently uninitialized `sp1A4` use in `patches_matrix.c`. Generation is deterministic, but G3 must classify required patches and decide whether any warning represents a correctness risk.
- LLVM/LLD 18 was installed because AppleClang has no MIPS backend and the existing MacPorts installation is incompatible with the current host OS.

## Commands

```sh
scripts/prepare-rom.sh --rom /absolute/path/to/the/private-original.v64
scripts/decompress-rom.sh
scripts/generate-game.sh
scripts/generate-patches.sh
scripts/verify-sources.sh
scripts/check-repo-safety.sh
```

Script syntax, Python compilation, JSON parsing, whitespace checks, ignored-output checks, source pins, and the unchanged original hashes also passed.
