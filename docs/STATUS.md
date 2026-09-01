# BananaPad status

Last updated: 2026-09-01 09:35 CDT

## Current state

- **Active goal:** finish the iOS/iPadOS Apple shell: touch/chords, three-dot menu, controller ownership, ROM/save management, lifecycle/orientation/memory/audio behavior, and mobile packaging. DK64Recompiled is the accepted game baseline; full-game replay is no longer a BananaPad goal.
- **Current step:** Product source `d7e4873026331e89acbee9e30d91f5daf5b5de8023b011650f040783040fc0cb` preserves PaperPad's byte-identical touch/menu implementation, safe ROM replacement/removal, controller/native-UI suppression, and neutral rearm. The guided manager successfully evaluated actual newer upstream `main` `1b22409b5297dbb710843cc4493d9b7a4a303bdc`: external patches applied, changed game inputs regenerated deterministically, and the iOS/iPadOS candidate built/audited without launching DK64. The manager correctly refused promotion. Release readiness caught that rollback left candidate-generated/build output behind; rollback now archives the checkout, metadata, generated inputs, macOS build, and iOS build together. A fresh same-pin evaluation reproduced clean Simulator executable `b9c1d2a90d5dd47ec945413e642a827ca5b9d0836e403de29c75cfd242517955`, and the complete non-game product gate passes. The promoted lock plus normal Simulator/device artifacts remained byte-identical. A real `bootstrap-bananapad.sh --target all` run also built/audited the normal macOS, Simulator, universal unsigned iPhoneOS app (`2519ee937149d35d367a0b823ac1831a37f710492c9fdcf3658119de5675c2f5`), and immutable ROM-free private IPA (`8730180e8921aa25fd92b85c25444961f78ab617d8ff8ee5ee4e7d9cd6de5e9f`) without booting a Simulator. It is not yet a signed physical-device artifact. Gameplay replay is not the next step.
- **Rights state:** private-only; publication is not authorized.
- **Tracked source:** `main` is the private handoff branch; use `git rev-parse HEAD` for its exact revision. `PRD.md` and `GOAL-LOOP.md` live under `docs/`.
- **Booted Simulators:** none; iPad and iPhone were tested sequentially and each was shut down before the other target or documentation work.
- **Running game instances:** none.
- **Active saves:** macOS Game 1 remains at `0%` and `000` Golden Bananas; no Training Barrel is claimed durable. Exact-candidate iPad Game 1 previously wrote/reloaded a 2,048-byte save, SHA-256 `6d16991320b7786abc8e8fe3f0f4964052a71d24ca48aef256062523be159fe1`; its live disposable Simulator copy was removed during the 05:00 clean reinstall after an intended backup failed while the device was shut down. Exact-candidate iPhone Game 1 independently wrote/reloaded a 2,048-byte save, SHA-256 `54a04cb7dc031627db84910b72feca2205d75854d138943698874c15e2d2e558`. Both visible-reload observations remain valid evidence; only the current iPad container copy is gone. Cross-target/cross-version compatibility and persisted progression beyond file creation remain unclaimed.
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
| G10 | Simulator implementation accepted; physical acceptance pending | PaperPad UI source remains byte-identical; all baseline N64 touch targets, independent touch tracking, tap latching, lifecycle clearing, touch/controller merging, controller-driven auto-hide, native-modal controller suppression/neutral rearm, three-dot menu, Settings, diagnostics, layout editing, ROM-management UI, and an original provenance-bound BananaPad icon are implemented and contract-tested. The exact current iPad app completed three observed background/foreground cycles, retained the open menu and native Settings across transitions, restored the overlay after dismissal, resumed rendering, and rendered in both landscapes. Pinned SDL2 forwards memory-warning events and pauses/restarts CoreAudio across interruptions. Physical multi-touch chords, controller handoff/reconnect, audible audio interruption/routes, memory pressure, and icon appearances remain G12. |
| G11 | Met for current private source; future pins remain gated | The isolated clean Git snapshot independently downloaded every public pin, reproduced generated manifests, and built/audited hardened macOS and Simulator apps. The current same-pin lane cleanly stages, regenerates, builds, checks exact PaperPad UI/touch/menu/ROM behavior, audits AOT packaging, promotes, rolls back, and re-promotes without launching DK64. Unsigned arm64 iPhoneOS packaging passes for both device families. A genuinely newer pin still requires categorized affected-route qualification. |
| G12–G13 | G12 ready/external; G13 not started | The exact private candidate, unsigned IPA, signed-build path, installer, and artifact-bound hands-on preflight are ready. Each device run will record the exact signed bundle/source/device identities and generate a complete pending worksheet. G12 now requires an Apple signing identity plus physical iPad/iPhone hardware; G13 separately requires rights and release authorization. |

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
- Current upstream observation: stable `1.0.1`; `main` at `1b22409b5297dbb710843cc4493d9b7a4a303bdc`. The post-stable D-pad-description and `us.toml` instruction-patch commits are categorized but not promoted without a stable tag or named BananaPad regression.
- The private original input is a 33,554,432-byte V64 image. Its original hashes are recorded only in the private journal; G1 verified a byte-order-normalized Z64 copy without modifying the original.

## Next step

Do not replay DK64 progression without a named BananaPad regression. The mobile source, Simulator build, universal iPhoneOS device build, PaperPad touch/three-dot UI, ROM safety, native-UI suppression/neutral rearm, lifecycle/orientation evidence, packaging, README, and reversible upstream lane are green. The device builder accepts `BANANAPAD_DEVELOPMENT_TEAM` for automatic local signing; the explicit-device installer rejects an invalid signature and re-audits the app; the physical preflight additionally binds the exact signed bundle, source, and resolved device into a private pending receipt and worksheet. No physical device or signing identity is available on this Mac. The next executable step is `scripts/preflight-bananapad-device-acceptance.sh DEVICE-UDID --install` followed by exact signed-device G12 acceptance on each form factor: physical multi-finger chords, real-controller ownership, audible audio routes/interruptions, sustained thermal/memory behavior, and icon appearances. Simulator gameplay is not a substitute.
