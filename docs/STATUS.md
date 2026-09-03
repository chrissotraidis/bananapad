# BananaPad status

Last updated: 2026-09-03

## Current state

- **Active goal:** Preview 3 is public; obtain the reporter's physical-iPhone confirmation for the faster Z-lock engage and release timing.
- **Current step:** Product source `b4b4fc8dec848055b84ca265094db13be96feaaaaf9a5a4c022062737ce04b1e` produces merged-tree unsigned release executable `8d7085f3082ab0647257bd5d2ea785fd47002c6b8d00e111727f7bd6b6e59e40`. Two deterministic packages of `BananaPad-v0.1.0-preview.3-unsigned.ipa` matched byte-for-byte at SHA-256 `ad8efa113b34d3cb80ca330a9fbb8a67297245b6b5ad78f7e0af9aeb48cd882f`. The anonymously downloaded GitHub IPA/checksum matched the local artifacts exactly and passed hosted checksum, ZIP, package, and no-dynamic-code re-audits. The existing signed hardware app and its private ROM/save/preferences were not changed.
- **Rights state:** public source, tag, prerelease, exact IPA, and checksum publication are explicitly authorized. ROM/save/generated private inputs and signing/user/device data remain prohibited.
- **Tracked source:** public `main` is the handoff branch; use `git rev-parse HEAD` for its exact revision. `PRD.md` and `GOAL-LOOP.md` live under `docs/`.
- **Booted Simulators:** none; iPad and iPhone were tested sequentially and each was shut down before the other target or documentation work.
- **Running game instances:** the signed physical-iPad build is running; no Simulator is booted.
- **Active saves:** the hardware iPad primary EEPROM now contains a private 101% capture save in Game 2. Its exact 2,048-byte image was visually opened and loaded in a disposable iPad Simulator, copied while the hardware app was stopped, and read back byte-for-byte after hardware launch. The pre-import hardware primary is preserved locally and remains byte-identical in the on-device `DK64.bin.bak`; Game 1, Game 3, the rotating temporary block, and global bytes were not changed by the importer. The disposable Simulator was deleted after validation. No save is tracked or distributable.
- **Known-good comparison artifact:** private upstream macOS bundle SHA-256 `7bebbc99e7d9ad97b776e9de8d86f30709ab93f230e2f5c95d2ee00408e2c983`; not a BananaPad product artifact and fails the no-dynamic-code audit by design.

## Goal summary

| Goal | State | Evidence / blocker |
|---|---|---|
| G0 | Met | `VALIDATION-G0-2026-08-31.md`; prerequisite/source/safety/upstream checks green; released host tools built from pin |
| G1 | Met | `VALIDATION-G1-2026-08-31.md`; exact normalized ROM, deterministic decompression, game/patch/RSP generation and hashes |
| G2 | Met | The archived upstream comparison contract and recursively bound stage/replay/build/Simulator-test/promote/rollback lane pass. The consolidated patch digest is promoted in `dependencies.lock.json`. |
| G3 | Met | `VALIDATION-G3-2026-08-31.md`; complete generated-code/patch/overlay/RSP/save inventories and exact-candidate no-dynamic-code/Mach-O/package audits pass. |
| G4 | Met | `VALIDATION-G4-2026-08-31.md`; BananaPad macOS direct-boots DK64 through Metal with pinned static SDL2, active audio, native input, static overlays/patches, no desktop RmlUi launcher or forbidden dynamic-code behavior, and clean exit. |
| G5–G7 | G5/G6 accepted; G7 mobile integration in progress | The exact hardened candidate boots, plays, accepts real input, transitions maps, writes/reloads the 2,048-byte save, renders/runs audio, and exits cleanly. DK64Recompiled owns gameplay correctness. G7 now covers Apple-owned lifecycle, controller, ROM/save, settings, and sustained-operation behavior. |
| G8 | Met | Exact staged executable passed immutable locked-ROM iPad smoke, created/reloaded Game 1, and proved touch stick/A/B/Z/R plus every C-camera direction in gameplay. Home→foreground cleared pending input. |
| G9 | Met | The same executable independently created/reloaded Game 1 on iPhone, accepted compact stick/A/B, wrote a 2,048-byte save, visibly restored `0% / 000 / 00:04`, and preserved the complete layout across edit/reset, Home→foreground, and both landscapes. |
| G10 | Simulator accepted; physical boot/render accepted | The PaperPad-derived UI preserves baseline N64 touch targets, independent touch tracking, tap latching, lifecycle clearing, touch/controller merging, controller-driven auto-hide, native-modal controller suppression/neutral rearm, three-dot menu, Settings, diagnostics, layout editing, and ROM management while using BananaPad product labels. The corrected signed app now launches and visibly renders DK64 with the full overlay on physical iPad hardware. Physical multi-touch chords, controller handoff/reconnect, audible audio interruption/routes, memory pressure, and sustained operation remain G12. |
| G11 | Met for the promoted source; stable `1.0.2` rehearsal archived | The live `1.0.2` rehearsal narrowed one stale patch context and shared the Apple path helper across macOS/mobile, then passed exact patch replay, deterministic regeneration, Apple builds, product contracts, and package audit. It remained unpromoted at `needs-full-validation`. The candidate was archived recoverably after the subsequent Xbox input repair changed the Apple product identity; `evaluate-latest` can restage it against the new source. |
| G12–G13 | G12 started; Preview 3 published | Preview 3 shortens Z-lock engagement to 0.75 seconds and release to 0.35 seconds. Its source/tag/prerelease/IPA/checksum publication and anonymous hosted-byte verification are complete; reporter confirmation remains. |

## Verified starting facts

- Apple Silicon (`arm64`) host on macOS 26.5.
- Xcode 26.6 and installed Metal Toolchain component.
- CMake 3.27.1, Ninja 1.13.2, Git 2.41.0, jq 1.7.1, Rust/Cargo 1.97.1, and GNU `cpp-16` are available.
- Python 3.13.0 is available at the Homebrew path; scripts require Python 3.11 or newer rather than the older system shim.
- `ref/dk64-recompiled` is pinned to `1.0.1` / `c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43` with recursive submodules present.
- `ref/paperpad` is pinned to `74b6e45830a06c7f274c5ac1ddd7c625bc13a557`.
- PaperPad's ignored static SDL2 input is now independently locked and verified at `5d249570393f7a37e037abf22cd6012a4cc56a71` instead of being borrowed from local state.
- `ref/sunpad` is pinned to `e43f0ea6b797e5110787171957c9dc3c6213269c`.
- Push URLs are disabled for all three top-level references and discovered nested submodules.
- The released N64Recomp/RSPRecomp host-tool source is pinned at `2b6f05688de2abc7d86da5b4a89b84c2c6acbabe`; both tools build successfully with AppleClang/Ninja.
- Current upstream observation: promoted stable `1.0.1`; latest stable `1.0.2` at `9177e21a3f633e834779573783b399750f20e7fe`; `main` observed at `fe291083`. The isolated `1.0.2` candidate builds and audits, but its affected gameplay/save/settings routes have not been qualified and it is not promoted.
- The private original input is a 33,554,432-byte V64 image. Its original hashes are recorded only in the private journal; G1 verified a byte-order-normalized Z64 copy without modifying the original.

## Next step

Do not replay DK64 progression without a named BananaPad regression. Preview 3 is public and hosted-verified; keep Issue #2 open for the reporter's physical-iPhone timing retest. Product-quality work continues through the remaining hands-on G12 worksheet: controller reconnect, audible audio routes/interruptions, sustained thermal/memory behavior, and icon appearances. Simulator gameplay is not a substitute.
