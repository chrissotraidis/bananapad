# DK64Recompiled 1.0.1 upstream comparison contract

Last updated: 2026-08-31

This is the archived behavior contract for the private Apple Silicon comparison build at promoted commit `c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43`. It separates source-derived facts, artifact observations, and still-unproven behavior. Run `scripts/audit-upstream-baseline.sh` after rebuilding and during every upstream-candidate review; a changed result requires explicit recategorization rather than silently becoming BananaPad behavior.

## Launcher and ROM

- Product identity is `DK64: Rekongpiled`; program storage ID is `DK64Recompiled`; the macOS bundle ID is `com.github.dk64recompiled`.
- The launcher is desktop RmlUi. Its primary option is autofocus. When `DK64.z64` is invalid or absent it opens the native file chooser; once validation succeeds it changes to `Start Game`. With no enabled game mode, the callback calls `recomp::start_game(u8"DK64", {})` and hides every launcher context.
- The game entry accepts internal identity `DONKEY KONG 64`, game ID `DK64`, mod-game ID `dk64`, ROM hash `0x4d876060f09b3fc5`, and the NTSC-U version enforced by the validation path.
- macOS storage resolves to `~/Library/Application Support/DK64Recompiled`. The runtime-owned normalized ROM is `DK64.z64`. `APP_FOLDER_PATH` and a neighboring `portable.txt` can intentionally override that location upstream; BananaPad must not inherit those desktop escape hatches silently.

Observed on the reproduced artifact: before the runtime ROM copy, the launcher displayed `Load ROM`; after a clean restart with the exact 33,554,432-byte supported copy, it displayed `Start Game`. This proves launcher launch and exact-ROM recognition, not picker interaction or gameplay.

## Input contract

The upstream input callback polls SDL and translates the active keyboard or controller profile into N64 state. Its compiled defaults are:

| N64 input | Keyboard | SDL controller |
|---|---|---|
| A / B | Space / Left Shift | South / West |
| L / R / Z | E / R / Q | Left shoulder / right trigger / left trigger |
| Start | Return | Start |
| C left/right/up/down | Arrow keys | Right-stick directions, with North/East/Right-stick/Right-shoulder alternates |
| D-pad | J/L/I/K | Controller D-pad |
| Analog stick | A/D/W/S | Left stick |
| Runtime menu | Escape | Back |

The source initializer contains a duplicate `B` keyboard entry immediately after `L`. Because the destination is an `unordered_map`, this currently does not create an additional usable binding. Treat it as an upstream source anomaly to recheck, not as evidence of an observed gameplay defect.

No end-to-end input claim exists yet. The Metal launcher repeatedly times out the Computer Use accessibility-state handshake, including app-path, bundle-ID, and foreground-activation attempts. The control service consequently refuses both element and coordinate actions. No alternate OS event synthesis or blind input was used.

## Video and audio contract

- macOS creates a resizable 1600×900 SDL Metal window and gives RT64 the Cocoa window plus `CAMetalLayer`.
- The renderer uses RT64 through `RecompFrontend`, with early presentation pacing.
- Audio is mandatory at startup. Upstream opens the default SDL device as 48 kHz, two-channel `AUDIO_F32`, queues converted N64 samples, swaps channels for emulated endianness, and trims queued samples when latency exceeds its threshold.
- `n_aspMain` is the only accepted RSP microcode for `M_AUDTASK`; an unknown task is logged and returns no handler.

The launcher rendering is observed. Gameplay video, audible game output, and timing remain unproven until the process reaches normal gameplay.

## Save contract

- DK64 deliberately requests `Eep16k`, allocating exactly `0x800` bytes rather than the original `Eep4k`, to leave room for upstream-added data.
- The default path is `~/Library/Application Support/DK64Recompiled/saves/DK64.bin`.
- Startup creates the parent directory, loads the primary/backup through the runtime file helper, or initializes an all-zero buffer when neither exists.
- EEPROM writes update the shared buffer and signal a dedicated thread. That thread coalesces writes in 10 ms intervals, bounded at 128 actions, writes through the runtime's backup-aware output helper, and finalizes the replacement.
- Shutdown joins the game, event, cleaner, and saving threads before freeing RDRAM.

No `DK64.bin` exists in the current upstream container because normal gameplay has not been reached. A file appearing without observed gameplay is not sufficient evidence under the PRD. G2 remains open until the exact comparison process writes real progress, exits, relaunches, and visibly restores it.

## Desktop-only security assumptions

The reproduced comparison has native arm64 code and a valid deep ad-hoc signature, but it intentionally carries `allow-jit`, `allow-unsigned-executable-memory`, `disable-executable-page-protection`, and `disable-library-validation`. Its Mach-O `__TEXT` maximum protection is `rwx`. It must therefore fail BananaPad's no-dynamic-code audit and cannot be treated as a shipping Apple architecture.

## Observed build and runtime defects

1. Pinned RT64/hlsl++ does not compile under Xcode 26 because `labs` is not declared transitively. The external patch adds the required `<stdlib.h>` include.
2. Homebrew `sdl2-compat` loads SDL3 dynamically, so CMake BundleUtilities does not discover it from Mach-O linkage. The private comparison bundle must explicitly package and sign SDL3.
3. Homebrew host libraries report a macOS 26 build version while the comparison target declares macOS 14. The resulting bundle is not deployment evidence for older macOS releases.
4. The Metal canvas does not provide a usable Computer Use accessibility-state snapshot on this host. This blocks automated hands-on gameplay evidence but is not yet categorized as an end-user input defect.

The comparison app itself remains ignored and private. None of these exceptions may be copied into BananaPad's accepted mobile profile.
