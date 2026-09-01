# BananaPad source map

Last updated: 2026-08-31

## Ownership rule

DK64Recompiled remains the game source of truth. BananaPad-owned Apple shell, adapters, tests, scripts, and exact patches live outside the pristine reference trees. PaperPad is the user-directed README/docs and touch-UI reference; applicable UI is preserved verbatim in structure and interaction—including the persistent three-dot menu—while identifiers, product labels, DK64 input masks/settings, and necessary integration boundaries become BananaPad-specific. SunPad is an additional PRD reference, not permission to import GameCube/Dolphin/Sunshine behavior.

## DK64 implementation map

| Path | What it establishes |
|---|---|
| `ref/dk64-recompiled/README.md` | Supported product behavior, enhancements, controls, known issues, dependency acknowledgements |
| `BUILDING.md` | Decompressed build-ROM requirement, N64Recomp/RSPRecomp generation, native CMake build, standard runtime ROM |
| `.github/workflows/validate.yml` | Released host-tool pin, Apple ARM64 build commands, and opaque private `extra` boundary that BananaPad must replace |
| `us.toml` | Entry `0x80000400`, symbol inputs, decompressed ROM, generated game output, boot/overlay hooks |
| `patches.toml` + `patches/` | Static patch ELF, symbol references, binary data, exports/events, strict patch mode |
| `decompressor.cpp` | Ten named compressed overlay classes and appended decompressed layout after 32 MiB |
| `src/game/rom_decompression.cpp` | Runtime standard-ROM placeholder/TODO; it cannot substitute for build-time decompression evidence |
| `src/main/register_overlays.cpp` | Generated game section registration |
| `src/main/register_patches.cpp` | Patch binary/section/export/event/manual-symbol registration and primary static conversion boundary |
| `src/game/recomp_api.cpp` | Overlay map, host APIs, settings/input bridges, no-Controller-Pak result, special routines |
| `src/main/main.cpp` | GameEntry/ROM hash, `Eep16k`, `n_aspMain`, SDL/Metal/audio, startup, mod/texture paths, shutdown |
| `src/game/config.cpp` | Camera, story, lightning, draw distance, sound, control, and multiplayer setting semantics |
| `n_aspMain.toml` | Audio RSP range/function/indirect targets |
| `CMakeLists.txt` + `.github/macos/entitlements.plist` | Static generated libraries plus desktop writable-text/JIT exceptions that mobile must remove |

## PaperPad mapping

| Path | BananaPad use |
|---|---|
| `README.md` and `docs/` | Documentation information architecture, honesty/evidence language, setup/status/project maps, privacy and rights presentation |
| `apple/app/ios_main.mm` | Verbatim touch overlay/menu/settings reference: independent `UITouch` ownership, `•••` button, action sheet, layout editor, modal clear/hide, controller auto-hide, device-class defaults |
| `apple/app/rom_setup.mm` | Native N64 picker, byte-order normalization, exact-hash validation, atomic activation/removal |
| `apple/app/diagnostics.mm` | Bounded private logs and reviewable system-share report |
| `apple/app/touch_tap_latch.h` | Short touch tap preservation without stuck holds |
| `src/paperpad_main.cpp` | N64 input merge, SDL2 controllers, runtime startup, settings bridge, clean stop |
| `src/controller_slots.*` | Stable controller/player ownership and reconnect behavior |
| `src/paper_rt64_context.*` | RT64 Metal ownership, settings, render state, and diagnostics |
| `CMakeLists.txt` + patches | Static Apple libraries, `N64MODERN_NO_DYNAMIC_CODE`, SDL2/RT64 fixes, package boundary |
| `scripts/` | Deterministic source/build/package/repository machinery |

Paper Mario-specific HLE audio, timing, save, or game hooks are hypotheses until DK64 reproduces their need.

## SunPad mapping

| Path | BananaPad use |
|---|---|
| `apple/ios/SunPadGameOverlay.*` | Cross-check safe bounds, independent touches, editing, and utility-button presentation |
| `apple/ios/SunPadGameViewController.mm` | Honest loading phases, lifecycle, Game Data & Saves, diagnostics/report flow |
| `apple/shared/` | Settings, normalized input, controller reconciliation, diagnostics patterns |
| `tests/` | Controller, input, diagnostics, touch-default, and experimental-setting test patterns |
| app-icon provenance and package scripts | Original-art provenance and package acceptance discipline |

Do not import Dolphin/ModernGekko, disc extraction, Sunshine controls, FLUDD pressure, performance patches, or dynamic module assumptions.
