# BananaPad release readiness

Last updated: 2026-09-01 09:04 CDT

Decision: **NO-GO for public release**. The private Apple product candidate is playable, its Simulator touch shell is accepted, and isolated clean-source reproduction passes. Remaining blockers are Apple-shell edge cases, physical-device acceptance, rights review, and release authorization—not replaying the upstream game to completion.

## Exact current identity

- Promoted DK64Recompiled source: tag `1.0.1`, commit `c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43`.
- Dependency lock SHA-256: `c6b661c21b3a7698972197dfe41f149b6089cecbc95126f89d74469628aecd0d`.
- Promoted and current BananaPad patch-series SHA-256: `8f9e051ed2d643a39a4618acd0c31f3072317732bd29ade1a8687256e91b9505`.
- BananaPad product-source SHA-256: `d7e4873026331e89acbee9e30d91f5daf5b5de8023b011650f040783040fc0cb`.
- Current clean build/audit Simulator executable SHA-256: `b9c1d2a90d5dd47ec945413e642a827ca5b9d0836e403de29c75cfd242517955`.
- UI/lifecycle-accepted Simulator executable SHA-256: `739fecd9aed836bf235c15ddfac2f80b50babd88fe4850e410e4d79524505117`; subsequent changes are update/build harnesses and the applied Apple UI source remains byte-identical.
- Current full-bootstrap unsigned iPhoneOS device executable SHA-256: `2519ee937149d35d367a0b823ac1831a37f710492c9fdcf3658119de5675c2f5`; arm64, iOS 15 minimum, and both iPhone/iPad families. Package and no-dynamic-code audits pass; no physical launch is claimed.
- Private ROM-free unsigned IPA SHA-256: `8730180e8921aa25fd92b85c25444961f78ab617d8ff8ee5ee4e7d9cd6de5e9f`; package audit passes. Publication remains unauthorized.
- Last full touch/play/save/reload candidate executable SHA-256: `f4fab84e2b0b99c8cba45ccfd576f256810eebd660f25fbf00805564b910f182`; the current delta is confined to ROM-management safety and native-modal controller suppression, not game code.
- Clean replayed candidate worktree SHA-256: `d1bbe0dd4c04a8a793648cdcdc4b690064f9e725418211c06326c1eb1c896a70`.
- PaperPad UI SHA-256: `feb4e78539e4473bff324d402c158de08b9a7eb7f5038787f2dedf0038472c44`; `apple/app/ios_main.mm` remains byte-identical to the pin.
- Rights state: private-only. Neither public source nor public binary/IPA distribution is authorized.

## PRD technical matrix

`Met` means the complete BananaPad-owned row has direct evidence. `Inherited` means DK64Recompiled owns the game behavior and BananaPad preserves it through its bounded integration smoke/update gate. `Partial` means useful evidence exists but at least one required target or behavior is missing. `Open` means the row's central Apple-owned route has not been performed. `External` means completion requires physical hardware or an authorization decision.

| # | Row | State | Current evidence / missing proof |
|---:|---|---|---|
| 1 | Repository safety and rights | Met | `RIGHTS-STATUS.md`, ignore rules, and `check-repo-safety.sh` pass. |
| 2 | Pins, clean references, sync metadata | Met | Pins—including PaperPad's previously hidden ignored SDL2 input—recursive identities, disabled push URLs, promoted/observed state, and sync record are verified in the root and isolated clean snapshot. |
| 3 | Exact standard ROM | Met | G1 verifies normalization, exact size/SHA-1, rejection boundary, and preservation of the private original. |
| 4 | Deterministic decompressed ROM | Met | G1 records two identical derivations and overlay identities from the pinned decompressor. |
| 5 | Game, patch, and RSP generation | Met | Generated manifests/hashes and ignored-output boundary are recorded and audited. |
| 6 | Initial upstream baseline/comparison | Met | Archived `1.0.1` macOS comparison reaches gameplay with audio/input/save/reload and recorded artifact identity. |
| 7 | Static/no-dynamic-code audit | Met | Hardened macOS, exact Simulator app, and unsigned arm64 iPhoneOS app pass source, entitlement, Mach-O, and package audits. |
| 8 | BananaPad boot to title | Met | macOS, iPad Simulator, and iPhone Simulator boot via Metal with audio/input/static code; only one Simulator ran at a time. The real iPhoneOS target compiles and audits; physical launch remains G12. |
| 9 | ROM import/reimport/remove | Partial | Exact valid import works. Current iPad build directly shows Replace/Remove, requires a second destructive confirmation, explicitly preserves saves/settings, and keeps the existing validated ROM on cancellation. Invalid/truncated, failed reimport preservation, and completed removal/relaunch need the remaining matrix. |
| 10 | Shared-core play/save route | Met | Boot, Adventure file creation, real gameplay, map transition, save, exit, and visible reload are proven on the Apple integration. |
| 11 | Jungle Japes | Inherited | DK64Recompiled owns world/progression correctness; reopen only for a named BananaPad or staged-upstream regression. |
| 12 | Angry Aztec | Inherited | DK64Recompiled owns world/progression correctness; reopen only for a named BananaPad or staged-upstream regression. |
| 13 | Frantic Factory | Inherited | DK64Recompiled owns world/arcade correctness; reopen only for a named BananaPad or staged-upstream regression. |
| 14 | Gloomy Galleon | Inherited | DK64Recompiled owns world/water correctness; BananaPad separately tests touch/camera/lifecycle integration. |
| 15 | Fungi Forest | Inherited | DK64Recompiled owns world/time-lighting correctness; reopen only for a named regression. |
| 16 | Crystal Caves | Inherited | DK64Recompiled owns world/effects correctness; reopen only for a named regression. |
| 17 | Creepy Castle | Inherited | DK64Recompiled owns world correctness; reopen only for a named regression. |
| 18 | Hideout Helm, K. Rool, credits | Inherited | DK64Recompiled owns final progression and credits correctness. |
| 19 | Kongs, moves, vendors, tag system | Inherited | DK64Recompiled owns game semantics; BananaPad validates that all required N64 controls and controller/touch ownership reach the game. |
| 20 | Menu/file/options paths | Partial | The current exact iPad build directly exposes the persistent three-dot menu, Settings, Game ROM sheet, and layout controls. Native-modal touch/controller suppression is built and contract-tested; physical-controller observation and file erase remain physical/destructive acceptance items. |
| 21 | Minecart/race/bonus/critter | Inherited | DK64Recompiled owns these game classes; BananaPad's required control masks and independent touch bridge are covered separately. |
| 22 | Boss class | Inherited | DK64Recompiled owns boss correctness; reopen only for a named BananaPad regression. |
| 23 | Donkey Kong arcade/Nintendo Coin | Inherited | DK64Recompiled owns arcade progression; BananaPad preserves D-pad/A/B/Start reachability. |
| 24 | Jetpac/Rareware Coin | Inherited | DK64Recompiled owns Jetpac progression; BananaPad preserves D-pad/A/B/Start reachability. |
| 25 | EEPROM save/compatibility | Partial | Independent iPad/iPhone 2,048-byte creation and visible reload pass. Erase, interrupted write, recovery, slot isolation, and cross-version/desktop round trips remain. |
| 26 | Audio continuity/routes | Partial | Metal/CoreAudio startup and ordinary audio work. Pinned SDL2 observes AVAudioSession interruptions, pauses/restarts its AudioQueue, and retries on foreground when iOS omits interruption-end. Simulator/physical audible interruption and route-change evidence remain. |
| 27 | Baseline timing/rendering | Partial | Native original-mode rendering/gameplay is stable for current smokes and interaction. Scene measurements, long-run memory, and physical baselines remain. |
| 28 | Enhanced modes | Partial | Resolution/aspect/settings contracts and 3x/4x native route are verified. Per-mode gameplay, persistence, timing, and physical qualification remain. |
| 29 | Touch overlay/chords | Partial | Every control mask, independent ownership, merging, cancellation, clamping, and lifecycle release pass compiled contracts; stick/A/B and iPad Z/R/C/swimming are game-visible. Physical independent-finger Z chords remain hands-on. |
| 30 | Three-dot/settings/controller | Partial | Byte-identical menu/settings UI, persistence contracts, controller notification bridge, touch auto-hide, and native-modal controller suppression pass. Real controller takeover/disconnect/reconnect remains physical acceptance. |
| 31 | Lifecycle/orientation/memory/diagnostics/icon | Partial | The exact current iPad executable completed three background/foreground cycles, retained the open three-dot menu and native Settings, restored the overlay after dismissal, resumed rendering, and rendered in both landscapes. Input clear/neutral rearm, both phone landscapes, diagnostics UI, clean stop, original icon master/provenance/package asset, and privacy/package audits pass. SDL2 forwards all UIKit lifecycle and memory-warning events. Observed memory warning, audible audio interruption/routes, and physical icon/appearance presentation remain. |
| 32 | Repeated lifecycle/native-UI transitions and soak | Partial | Three exact-candidate iPad Home→foreground cycles pass, including open-menu and open-Settings transitions plus renderer recovery. Three clean terminate/relaunch cycles then survived initialization with no new crash report. Longer sustained operation, memory pressure, and physical sustained-play evidence remain. |
| 33 | Regression/clean clone/audits/update rehearsal | Met | Product contracts, same-pin candidate replay, exact smokes, audits, promotion/rollback/re-promotion, and isolated clean Git snapshot `2ad0ffb4c8595b359f1681b142832c9f9c50c434` pass. The snapshot independently downloaded all public pins, normalized the external private ROM, reproduced generated manifests, and built/audited hardened macOS and Simulator apps. The current source additionally builds/audits as an unsigned arm64 iPhoneOS app without packaging a ROM. The physical-device preflight contract also proves that a signed/connected run will create an artifact-, source-, and device-bound pending receipt and complete G12 worksheet without auto-claiming acceptance. |
| 34 | Exact public candidate | External | Requires physical iPad/iPhone acceptance by Chris plus separate source/binary rights decisions. `preflight-bananapad-device-acceptance.sh DEVICE-UDID --install` is the exact guided handoff and creates separate private receipts for each form factor. |

## Green qualification commands

Run the current exact-candidate checks without booting a Simulator:

```sh
scripts/validate-product-candidate.sh
```

The command validates the current clean build, PaperPad fidelity, touch/settings/native-input contracts, renderer ordering, release-readiness identity, repository safety, upstream replay, no-dynamic-code, package state, and whitespace. Historical runtime receipts remain bound to the exact executables that produced them and are not relabeled as the current build; this command does not launch DK64 or manufacture physical-device evidence.

## Remaining release blockers

1. Complete the remaining Apple-shell matrix: ROM/save preservation, controller handoff, lifecycle/orientation/memory/audio interruption, settings behavior, and sustained operation.
2. Configure an authorized Apple development team and attach each target; the scripted signed build/install handoff is ready, but this Mac currently reports no signing identity and no physical device. Run `scripts/preflight-bananapad-device-acceptance.sh DEVICE-UDID --install` separately for iPad and iPhone, then complete each generated worksheet per [physical-device acceptance](DEVICE-ACCEPTANCE.md), including multi-finger chords, real controller ownership, audio routes, sustained operation, and icon/appearance presentation.
3. Keep the private tracked source reviewable and resolve public-source and public-binary rights decisions independently and explicitly before changing repository visibility or publishing an artifact.
