# BananaPad PRD: Donkey Kong 64, native on Apple platforms

Status: approved for **gated autonomous execution**. Written 31 Aug 2026.
Audience: an autonomous agentic system with full control of a macOS Apple Silicon machine.
Companion document: `docs/GOAL-LOOP.md` (the operating loop). Read both before doing anything.

Decision: **GO for a private technical porting program. NO-GO for public source or binary distribution until the static-code, complete-game, physical-device, package-safety, GPL/dependency, game-rights, and explicit-approval gates in this document are satisfied.**

---

## 1. Objective

Build **BananaPad** (`bananapad`): a native ARM64 port of **Donkey Kong 64 (Nintendo 64, US/NTSC-U 1.0)** for macOS, iPadOS, and iOS.

This is an integration and hardening project, not a new DK64 recompilation from scratch. The game-specific source of truth is the released **Donkey Kong 64: Recompiled** project at `github.com/Rainchus/Donkey-Kong-64-Recompiled`. Start from its stable `1.0.1` source state as the **initial reproducibility anchor, not a permanent ceiling**. Preserve its working static-recomp game core, compressed-code overlay map, patches, audio RSP, save behavior, input semantics, and compatible enhancements, then replace its desktop-only Apple boundary with a mobile-safe Apple shell. Keep the BananaPad-owned layer thin and patch-driven so the promoted DK64Recompiled pin can advance to later stable tags or selected upstream fixes without rebuilding the Apple shell from scratch.

Three references have different, non-interchangeable jobs:

- **`ref/dk64-recompiled`** is the game implementation and currently promoted upstream desktop baseline; `1.0.1` is the archived initial anchor, not a forever pin.
- **`ref/paperpad`** is the N64Recomp/N64ModernRuntime/RT64 Apple reference: AOT-only Apple builds, no-dynamic-code runtime profile, Metal integration, N64 touch/input plumbing, ROM management, controller ownership, lifecycle, diagnostics, deterministic scripts, and package audits.
- **`ref/sunpad`** is the product-shell reference requested for the three-dot menu and touch experience: native UIKit layout, loading phases, normalized multi-touch input, editable device-specific layouts, controller handoff, Game Data & Saves organization, settings, diagnostics/reporting, app-icon provenance, and mobile acceptance discipline.

The user supplies their own legally obtained supported ROM. The runtime app accepts only the standard verified US ROM. A separate ignored decompressed ROM is derived locally only for N64Recomp/RSPRecomp generation. No ROM, decompressed ROM, generated game code, generated patch code, extracted game data, or save is committed or distributed.

Preferred repository topology: a new integration repository named exactly **`bananapad`** (display product name **BananaPad**) with the three pinned reference checkouts under ignored `ref/`. The eventual GitHub repository name is `bananapad`; do not create, push, publish, or tag a remote until Chris explicitly authorizes it.

Order of delivery:

1. **Reproducible source and input state.** Pin upstream `1.0.1` as the archived initial anchor, separately record the promoted/observed/candidate upstream identities, pin PaperPad, SunPad, and every transitive build input; verify the exact standard ROM; deterministically derive the decompressed build ROM and all generated code; establish source/package rights state.
2. **Known-good initial upstream comparison.** Build and run the upstream `1.0.1` Apple Silicon macOS app from source; verify title, gameplay, audio, input, save/reload, and record its exact entitlements, generated inputs, behavior, and known defects.
3. **Upstream synchronization lane.** Provide scripts and records that discover newer stable tags or selected bug-fix commits, stage them in an isolated worktree, categorize the delta, reapply BananaPad's exact patch series, regenerate all derived output, run affected tests, and promote or roll back one reviewable pin change.
4. **Mobile-safe static-code boundary.** Inventory upstream game patches, mod hooks, overlays, RSP, saves, and desktop services. Remove the need for writable-executable memory, JIT, LiveRecomp, TCC, runtime C compilation, dynamic user code, and the upstream writable-text linker route. Required game patches must be linked ahead of time or represented by writable data dispatch tables, never writable code pages.
5. **Hardened macOS core.** Build BananaPad on macOS through the same static core and PaperPad-derived runtime profile intended for iOS/iPadOS. Replace the desktop RmlUi launcher with a minimal BananaPad-owned native shell before mobile promotion.
6. **macOS first-play loop.** Verify ROM import, title, Adventure file creation, opening tutorial, DK Isles, first Golden Banana, Jungle Japes gameplay objective, persistence, clean exit, and reload.
7. **Complete macOS game path.** Complete required progression through every world, required bosses, embedded arcade/Jetpac coin gates, Hideout Helm, K. Rool, credits, and save reload. Exercise all named compressed-code classes and major Kong/game systems.
8. **iPadOS and iOS Simulator cores.** Build iPad Simulator first, shut it down, then build iPhone Simulator, always with one Simulator and one game instance at a time.
9. **SunPad/PaperPad Apple shell.** Port the three-dot menu, touch layout, settings, ROM/saves flow, controller handoff, loading states, diagnostics, lifecycle, and package machinery. Adapt the controls to DK64's N64 semantics and multi-touch chords.
10. **Original app identity.** Create a rights-clean BananaPad app icon and asset catalog for iPhone/iPad, record provenance, and verify presentation in the Home Screen, app switcher, Settings/search, light/dark/tinted appearances where supported, and packaged candidate.
11. **End-to-end and physical-device acceptance.** Complete the test matrix in Section 10, then obtain hands-on iPad/iPhone evidence from Chris against the exact artifact.
12. **Public release gate.** Satisfy GPL and dependency obligations, separate source and binary rights decisions, audit every package boundary, and publish nothing until Section 12 is green.

Five requirements are hard, not aspirational:

- **The mobile build must be genuinely AOT/static.** A sideloaded app that needs JIT, unsigned executable memory, writable text, a dynamic recompilation service, or user-supplied executable mods is not BananaPad's accepted iOS/iPadOS architecture.
- **The first-play loop must work end to end.** Generated C, a successful link, a process ID, a launcher, a title screen, or a save file created without observed gameplay is not a playable port.
- **The complete required game path and special code paths must work.** A Jungle Japes demo, controller-only mobile build, build that skips arcade/Jetpac, or build whose enhanced modes hide baseline defects is not complete.
- **BananaPad must not become a dead-end fork.** `1.0.1` is a bootstrap anchor. Later upstream stable releases and exact bug-fix commits must remain consumable through a scripted, isolated, reviewable, reversible update path; copied vendor source and untracked in-place edits are not acceptable architecture.
- **A public candidate requires exact-artifact device testing and explicit release clearance.** GPL source availability and a ROM-free package do not by themselves decide whether the translated game binary may be distributed.

## 2. What “done” means

All of the following, each backed by evidence per Section 11:

- **D1. Exact inputs and deterministic generation.** The supplied ROM is normalized to big-endian `.z64`, is exactly 33,554,432 bytes, and matches SHA-1 `cf806ff2603640a748fca5026ded28802f1f4a50`. The pinned decompressor produces the ignored `donkeykong64.decompressed.us.z64`; N64Recomp, RSPRecomp, symbol files, game output, patch output, patch data, and `rsp/n_aspMain.cpp` are generated reproducibly. Every input/output hash and command is recorded.
- **D2. Initial upstream macOS baseline and update lane.** DK64Recompiled `1.0.1` builds from source on Apple Silicon macOS, accepts the standard ROM, reaches normal gameplay, produces working video/audio/input, writes progress, exits, relaunches, and restores progress. Its entitlements, writable-code assumptions, launcher behavior, save path/format, and known defects are archived as the initial comparison—not inherited silently. BananaPad can also detect, stage, patch-rebase, regenerate, test, promote, and roll back a later upstream tag or selected fix commit without mutating the last known-good promoted state.
- **D3. Mobile-safe execution model.** BananaPad's game and required patch functions are ahead-of-time native code. The iOS/iPadOS profile excludes LiveRecomp, JIT, TCC, runtime compiler invocation, downloaded/user executable code, and writable-executable mappings. Required static patch behavior survives without the upstream `allow-jit`, `allow-unsigned-executable-memory`, `disable-executable-page-protection`, or disabled-library-validation exceptions. Every generated game/patch section and dispatch mechanism is inventoried and testable.
- **D4. Hardened macOS first-play loop.** The BananaPad macOS app imports/verifies the standard ROM, reaches title/intro, creates or selects an Adventure file, completes the opening Training Grounds route, reaches DK Isles, collects the first Golden Banana, enters Jungle Japes, completes one documented in-level Golden Banana objective, persists progress, exits cleanly, relaunches, and visibly restores the same file/progress with working Metal rendering, audio, input, overlays, patches, and diagnostics.
- **D5. Complete required progression.** From a fresh save, a golden path reaches Jungle Japes, Angry Aztec, Frantic Factory, Gloomy Galleon, Fungi Forest, Crystal Caves, Creepy Castle, and Hideout Helm; unlocks all five Kongs; obtains the moves/items/keys/coins required to progress; completes required bosses; obtains the Nintendo Coin and Rareware Coin through the embedded Donkey Kong arcade and Jetpac paths; completes Hideout Helm and the final K. Rool sequence; reaches credits; and reloads the completed save without a progression blocker.
- **D6. Special-code and gameplay-system coverage.** The `menu`, `minecart`, `bonus`, `race`, `critter`, `boss`, `arcade`, and `jetpac` code classes each load, execute, return, and leave no stale mapping. Kong switching, tag barrels, Cranky/Funky/Candy/Snide flows, weapons, instruments, oranges, first-person aiming, fairy camera, swimming, boats, transformations/animal helpers, minecarts, races, bonus barrels, Troff 'n' Scoff, B. Locker, loading zones, boss doors, arcade, and Jetpac have observed representative coverage. The upstream multiplayer feature remains disabled/WIP unless separately approved and does not block baseline completion.
- **D7. Timing, rendering, audio, and enhancement correctness.** Original-framing and original-cadence modes provide a stable baseline. Frame pacing, game update timing, audio pitch/continuity, input response, cutscenes, HUD, fog/depth/effects, loading, and save behavior are measured. Upstream high-framerate, widescreen/ultrawide logic, analog camera, draw distance, story skip, lightning reduction, gyro/controller options, and other enhancements are retained only where their exact mobile settings pass the matrix and never hide a baseline failure.
- **D8. Simulator core.** iPadOS Simulator and iOS Simulator builds complete the first-play loop with the same AOT/static core, overlay registration, static patch profile, RSP path, Metal renderer, and save implementation. Simulator measurements are diagnostic only and are never converted into physical-device claims.
- **D9. Apple shell and app identity.** SunPad's three-dot menu and touch product architecture plus PaperPad's N64/RT64 Apple mechanisms are adapted as BananaPad. ROM import/reimport/remove, save status, settings, controller ownership, diagnostics, report flow, loading states, lifecycle, landscape safe areas, and all required DK64 controls/chords work on iPad and iPhone. A rights-clean original BananaPad app icon and provenance file are packaged correctly.
- **D10. Stability and persistence.** Background/foreground, phone interruption, audio route change, controller connect/disconnect, orientation reversal, native UI presentation, renderer recreation, memory warning, app termination, ROM reimport/removal, repeated loading zones, repeated special-overlay transitions, repeated EEPROM writes, and a minimum 90-minute soak complete without stuck input, save corruption, sustained audio underrun/static, orphan processes, unbounded memory growth, or an entitlement/runtime-code regression.
- **D11. Reproducibility, updateability, and auditability.** Technical matrix rows 1–33 are green, host tests and scripted smoke routes are green, and the full macOS/Simulator pipeline reproduces from a clean checkout using scripts, pinned public source, and the user's local ROM alone. The upstream synchronization workflow has been rehearsed end to end in an isolated candidate state, including categorized diff, exact patch reapplication, regeneration, affected tests, promotion metadata, and rollback. No upstream private CI input or undocumented terminal/update step is required. Repository, entitlement, Mach-O, and package audits are executable and green.
- **D12. Public candidate.** The exact source revision and exact binary/IPA candidate pass physical iPad/iPhone hands-on testing, repository/package audits, app-icon provenance review, third-party notices, GPL/dependency obligations, and the separate source/binary rights gate in Section 12. Chris explicitly approves that exact artifact.

Explicit non-goals for the baseline candidate:

- App Store submission, TestFlight, notarization, commercial signing, end-user automatic app updates, store compliance, or broad device-support marketing. This does not remove the required gated source-level upstream synchronization workflow.
- ROM regions, revisions, hacks, translations, or randomizer ROMs other than the verified US/NTSC-U 1.0 ROM.
- Runtime code mods, LiveRecomp, user-supplied native modules, downloaded executable code, or an iOS mod marketplace. Static built-in upstream fixes/enhancements are different and may be retained after audit.
- Texture-pack loading or arbitrary replacement assets in the first mobile candidate. Revisit only after D1–D11.
- Repairing or productizing upstream multiplayer. The upstream settings describe it as work in progress/non-functional; keep it disabled unless a separate PRD authorizes it.
- New cheats, randomizer integration, save-state systems, free camera, gameplay rebalance, or new content.
- A blanket “101% complete” claim. A fresh-save route to final credits is required; a 101% claim requires a separately observed 101% file and full-content evidence. Later-game fixtures do not justify that wording.
- Making high frame rate, widescreen, analog camera, draw-distance expansion, gyro, or other enhancements the only supported path. Baseline correctness comes first; enhancements remain selectable only after their own evidence.
- A new device-motion gyro implementation as a baseline blocker. Existing physical-controller gyro may remain experimental when inherited safely; mobile device motion requires a separate acceptance path.
- Vision Pro, Apple TV, Android, Windows, Linux, Steam Deck, Intel macOS, or Mac App Store work. Upstream may support other desktops; BananaPad's scope is Apple Silicon macOS, iPadOS, and iOS.

## 3. Why this is feasible — and what remains unproven

Validated by source/release audit on 31 Aug 2026 against:

- Donkey Kong 64: Recompiled tag `1.0.1`, commit `c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43`;
- research-time observed `main` snapshot `ee0455d131e0e2198821d35a88033b18524d75ba` (current tags/`main` must be fetched by the synchronization workflow rather than assumed from this snapshot);
- PaperPad revision `74b6e45830a06c7f274c5ac1ddd7c625bc13a557`;
- SunPad revision `e43f0ea6b797e5110787171957c9dc3c6213269c`.

Validated facts that materially reduce the porting risk:

- **A working Apple Silicon macOS product already exists.** DK64Recompiled `1.0.1` publishes a macOS ARM64 release. The project is not an untested decomp or partial N64Recomp experiment; a complete native desktop game is the comparison baseline.
- **The public build pipeline identifies the exact ROM and generated boundary.** `BUILDING.md` requires the NTSC-U 1.0 ROM with SHA-1 `cf806ff2603640a748fca5026ded28802f1f4a50`, derives `donkeykong64.decompressed.us.z64`, runs `N64Recomp us.toml`, runs `RSPRecomp n_aspMain.toml`, and builds the native app with CMake.
- **The game entry and static generation configuration are already game-specific.** `us.toml` uses entry point `0x80000400`, the DK64 symbol manifests, the decompressed build ROM, generated `RecompiledFuncs`, and explicit overlay hooks. `patches.toml` statically recompiles the project's patch ELF and emits generated patch code/data.
- **Compressed-code handling is enumerable and implemented upstream.** The runtime explicitly maps the main, menu, multiplayer, minecart, bonus, race, critter, boss, arcade, and Jetpac code classes into generated overlay sections. `register_overlays.cpp` registers the generated section tables with N64ModernRuntime.
- **Audio RSP generation is explicit.** `n_aspMain.toml` describes a fixed audio microcode region and the upstream app registers the statically recompiled `n_aspMain` handler.
- **The runtime save choice is explicit.** The game entry selects `Eep16k` (with an upstream comment that it intentionally expands beyond `Eep4k` for extra save data). This is a concrete contract to preserve and test, not a save-type guess.
- **The upstream input/feature layer is source-visible.** DK64's A/B/Z/R/Start/C-button semantics, original/analog camera modes, inversion/sensitivity, story skip, lightning setting, draw distance, volume, rumble/gyro flags, high-frame-rate and widescreen hooks are visible and can be adapted deliberately.
- **The renderer already has an Apple Metal path.** The upstream macOS build creates an SDL Metal window and passes a `CAMetalLayer` into RT64. BananaPad does not need to invent a renderer backend.
- **PaperPad has already solved the closest N64 mobile substrate.** Its pinned build compiles generated N64 game/RSP code into an iOS/iPadOS app, turns on `N64MODERN_NO_DYNAMIC_CODE`, uses RT64 Metal, supports native ROM management, N64 multi-touch, physical controllers, diagnostics, lifecycle, clean exit, and package audits.
- **SunPad has already solved the requested mobile interaction shell.** Its pinned iPhone/iPad implementation includes a three-dot menu, 1x–4x render scale, aspect modes, touch opacity/size/edit/reset, controller auto-hide/handoff, loading phases, Game Data & Saves actions, diagnostics/reporting, device-specific layouts, app-icon provenance, and physical iPad evidence.

The following are **not** validated by this review and must be proven by execution:

- That the public DK64 source plus the user's ROM can reproduce every generated input without relying on the upstream workflow's private `extra` checkout. BananaPad must replace any private CI convenience with deterministic local scripts and public dependencies.
- That DK64's complete static patch set can be retained on iOS/iPadOS without writable executable pages, dynamic patch code, or LiveRecomp. The required route may be generated static patch functions plus writable data dispatch, or narrowly re-expressed native hooks; this needs source and runtime proof.
- That the upstream special `ld64` writable-text wrapper and macOS entitlements are needed only by desktop mod/patch behavior and can be removed without losing required gameplay/enhancements.
- That the current public `rom_decompression.cpp` placeholder, build-time decompressed-ROM generation, generated overlay tables, and runtime standard-ROM path form a complete deterministic boundary on a clean BananaPad checkout. Trace the actual bytes and never infer it from filenames.
- That the DK64 fork of N64ModernRuntime/RT64 and PaperPad's pinned Apple patches can be reconciled without regressions or incompatible APIs.
- That the desktop RmlUi/RecompFrontend configuration layer can be replaced by native UIKit/AppKit state while every required game-facing setting and input hook continues to receive correct values.
- That SDL/RT64/N64ModernRuntime audio behaves correctly through iOS `AVAudioSession`, interruptions, Bluetooth, wired/headphone routes, and macOS HDMI/external routes. An upstream macOS external-audio issue exists and must be retested rather than assumed fixed.
- That every special code path—including arcade and Jetpac—survives static patch conversion, mobile memory/layout differences, save writes, and repeated transitions.
- That touch controls make DK64's Z-modified actions and camera controls comfortable and reliable on both compact iPhone and large iPad.
- That high-frame-rate/widescreen/analog-camera enhancements preserve timing, cutscenes, UI, audio, and gameplay across Apple displays and refresh rates.
- That a public translated-game binary is authorized. The upstream integration source is GPL-3.0, but game copyrights and binary distribution remain a separate decision.

**Conclusion:** proceed. This is substantially more feasible—and likely much faster—than starting from an arbitrary N64 ROM because a complete native macOS DK64 recomp, game-specific patches, compressed-code map, RSP path, save profile, and feature layer already exist. The honest difficulty is not “port DK64 from zero”; it is **convert a desktop recomp/mod architecture into a static, mobile-safe Apple product without losing the game's working behavior**. That is a bounded integration program, but not a one-command cross-compile.

This review was source/release-level. No user ROM was available in the research environment, so no local ROM normalization, decompression, generation, source build, launch, gameplay, entitlement audit of a locally built binary, Simulator run, or physical-device run was executed. The agent must not convert this GO decision into an acceptance claim.

## 4. Environment and workspace

You have free rein on a macOS Apple Silicon machine. Verify and install what is missing: a current Xcode 26.x toolchain and command-line tools, CMake, Ninja, Clang, Python 3, Git, `jq`, `ripgrep`, `xxd`, `shasum`, `codesign`, `otool`, `nm`, `file`, and any exact host dependencies required by the pinned DK64/PaperPad graph. `xcodebuild`, `xcrun simctl`, Instruments, current iPad/iPhone Simulators, and Metal capture/profiling must work.

Start from a local integration repository whose directory and intended remote name are `bananapad`. Recommended layout:

```text
docs/                           PRD, GOAL-LOOP, status, journal, technical
                                inventories, release readiness, evidence index.
design/
  app-icon-source/              Original editable source and provenance.
ref/                            Entirely ignored; pinned/read-only inputs.
  dk64-recompiled/              Donkey Kong 64: Recompiled promoted pin; initial `1.0.1` archived.
  paperpad/                     N64/RT64 Apple reference implementation.
  sunpad/                       Three-dot menu/touch product reference.
  rom/                          User's original ROM; never modified.
  toolchain/                    Any separate pinned host tools not vendored above.
worktrees/                      Entirely ignored; isolated upstream-update candidates.
  dk64-upstream-candidate/      Created by script for one tag/SHA; never the promoted tree.
generated/                      Entirely ignored.
  rom/                          Normalized standard ROM and decompressed build ROM.
  aot/game/                     N64Recomp game output.
  aot/patches/                  Generated static patch output and data.
  aot/rsp/                      RSPRecomp output.
  build/                        Native build products and caches.
  package-audit/                Expanded local package inspection.
port/
  apple/                        BananaPad AppKit/UIKit shell and assets.
  runtime/                      Game entry, paths, overlays, static patch bridge,
                                RSP/audio, save, settings, diagnostics.
  patches/                      Exact source patches grouped by upstream and pin.
scripts/                        Reproducible setup/build/test/audit entry points.
tests/                          Host regressions, static audits, scripted input/smoke.
```

The app data root should be platform-private and consistently named, for example:

```text
Library/Application Support/BananaPad/
  GameData/                     Verified standard ROM/private derived runtime data.
  Saves/                        DK64 save files and local backups.
  Config/                       BananaPad settings and touch layouts.
  RT64/                         Renderer data/config where required.
  Logs/                         Current/previous bounded runtime logs.
  Diagnostics/                  User-reviewed export reports.
```

Working bundle identifier: `com.chrissotraidis.bananapad`, unless an existing project convention or signing requirement dictates another identifier. Keep the identifier configurable; record any change.

Hard workspace rules:

- Never modify, rename, truncate, or delete the user's original ROM. Work from an ignored normalized copy.
- Treat `ref/dk64-recompiled`, `ref/paperpad`, and `ref/sunpad` as read-only source references. Never “fix” them in place or commit from inside them.
- Pin every checkout and recursive submodule. Disable push URLs on reference checkouts. A branch name is not a pin.
- Treat `1.0.1` as the archived initial anchor while separately tracking the currently promoted upstream pin, the last observed stable/`main` identity, and an optional candidate pin. Normal builds use only the promoted pin.
- Preserve a clean upstream comparison checkout or worktree at every promoted pin. BananaPad patches apply into generated/ignored worktrees or a deliberate candidate worktree, not the pristine reference. Fetching tags/metadata is allowed through the synchronization scripts; editing source in place is not.
- Never commit or upload any standard/decompressed ROM, generated game/AOT code, generated patch code/binary/data, extracted asset, save, private screenshot, crash dump containing game memory, or private diagnostic log.
- `docs/artifacts/` or `artifacts/` is local/ignored by default. Select public screenshots only during explicit release review.
- Never run `git clean -fdx`, destructive resets, blanket deletion, or commands that can erase ignored references, ROMs, generated output, saves, or evidence.
- Do not overwrite unknown local modifications. Inspect `git status`; preserve, isolate, or hand off.
- Do not create/push a remote branch, tag, release, source archive, package, screenshot set, or unsigned IPA unless Chris has configured the destination and explicitly authorized that action.
- Do not use an upstream prebuilt binary as a substitute for source reproducibility. It is a behavior reference and optional comparison artifact only.

## 5. Inputs and repositories

### 5.1 The ROM: standard runtime input and decompressed build input

Keep the user's original ROM under `ref/rom/`. Before any build work:

1. Identify byte order (`.z64`, `.v64`, or `.n64`) without modifying the original.
2. Record original filename, byte order, byte length, SHA-1, and SHA-256 in `docs/JOURNAL.md`.
3. Normalize an ignored copy to big-endian `.z64`.
4. Require length `0x2000000` (33,554,432 bytes) and SHA-1 `cf806ff2603640a748fca5026ded28802f1f4a50`.
5. Record the internal game name/region checks used by the pinned runtime in `docs/ROM-INPUTS.md`.
6. Use this normalized **standard ROM** for runtime import/testing. Never ask the app user to select the decompressed build ROM.
7. Build the pinned decompressor from source and derive `generated/rom/donkeykong64.decompressed.us.z64`. Prefer the repository's `decompressor.cpp` route or the exact pinned DK64 decomp script after comparing outputs.
8. Record the decompressed file's length, SHA-1, SHA-256, overlay offsets, tool revision, and command. Re-run from a clean generated directory and require deterministic equality.
9. Point `us.toml` and `n_aspMain.toml` at an ignored path or generated copy without changing the pristine reference tree.
10. Confirm no generated or public package contains either ROM form.

The upstream decompressor appends decompressed code/data after the original 32 MiB boundary and treats the following named code classes as first-class inputs: `global_asm`, `menu`, `multiplayer`, `minecart`, `bonus`, `race`, `critter`, `boss`, `arcade`, and `jetpac`. The final generated layout must be derived and verified from the pinned source, not copied from this prose without checking.

If the ROM does not match, stop G1 with a clear handoff. Do not bypass the checksum, patch a different revision into compliance, download a replacement ROM, or accept a “close enough” header.

### 5.2 The game implementation: `ref/dk64-recompiled`

Clone `github.com/Rainchus/Donkey-Kong-64-Recompiled` recursively and pin the **initial archived baseline** to tag `1.0.1`, commit `c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43`. That pin exists to make the first comparison reproducible; it is not intended to freeze BananaPad forever.

At the research snapshot, `main` was `ee0455d131e0e2198821d35a88033b18524d75ba`. Record it as the then-observed candidate, not as a permanently special commit. The synchronization scripts must fetch current tags and `main` when run rather than assuming this snapshot remains current.

BananaPad tracks three upstream identities:

- **promoted** — the exact DK64Recompiled tag/SHA used by normal BananaPad builds;
- **last observed** — the newest stable tag and `main` SHA reviewed by `scripts/check-upstream.sh`;
- **candidate** — an optional tag/SHA or narrow commit range staged in an ignored worktree for evaluation.

As soon as the initial G2 comparison is recorded, an exact upstream fix may be staged when it addresses a named blocker; the agent does not need to wait until G5 or the next stable release. Prefer stable tags for broad upgrades. Use a selected `main` commit/range only when its scope is understood and provenance is recorded. Never merge unrelated `main` churn merely because one desired fix is present.

Before writing BananaPad code, read in order:

1. `README.md` — release behavior, supported ROM, enhancements, controls, save notes, known issues, and dependency acknowledgements.
2. `BUILDING.md` — exact ROM/decompression/generation/build sequence.
3. `.gitmodules` and the recursive submodule state — exact forks and branches that must become immutable pins.
4. `.github/workflows/validate.yml` — released host-tool pins, Apple ARM64 build commands, private `extra` input, packaging, and the difference between CI convenience and a public clean-clone pipeline.
5. `us.toml` — entry point, symbol inputs, decompressed ROM path, generated output, boot hook, overlay hooks, and warning policy.
6. `patches.toml`, `patches/Makefile`, patch source/headers, generated-patch registration, exports/events/imports, and strict-patch behavior.
7. `decompressor.cpp` and `src/game/rom_decompression.cpp` — build-time appended overlay layout versus runtime standard-ROM behavior. Trace the real path; the public runtime source contains a placeholder/TODO and must not be treated as self-explanatory.
8. `src/main/register_overlays.cpp` and generated `recomp_overlays.inl` — static section registration.
9. `src/main/register_patches.cpp` and the pinned runtime's patch/mod implementation — determine every writable-code and function-dispatch assumption.
10. `src/game/recomp_api.cpp` — overlay mapping, imported host functions, timing/aspect/settings hooks, accessory behavior, and special routines.
11. `src/main/main.cpp` — GameEntry, ROM hash, save type, RSP registration, SDL/Metal/audio, runtime startup, mods/texture packs, and cleanup.
12. `src/game/config.cpp`, input headers, and mapping code — game-facing semantics and default settings.
13. `CMakeLists.txt`, `.github/macos/entitlements.plist`, and the Apple packaging workflow — desktop frontend, Metal window, special linker, JIT/unsigned-executable-memory entitlements, and mobile-incompatible assumptions.
14. `n_aspMain.toml` and generated RSP source — exact audio microcode route.
15. Open issues and latest release notes, especially current macOS audio-route failures and any save/progression regressions.

The upstream repository is the game source of truth. Preserve its functional behavior while making the platform boundary static and native. Keep BananaPad's integration, Apple shell, adapters, tests, and exact patch files outside the vendor tree so later upstream revisions remain mechanically rebaseable. Do not replace working DK64 patches with Paper Mario or Sunshine analogies.

### 5.3 The N64 Apple reference: `ref/paperpad`

Pin `github.com/chrissotraidis/paperpad` to `74b6e45830a06c7f274c5ac1ddd7c625bc13a557` first.

Read in order:

1. `README.md` and `docs/ARCHITECTURE.md` — ROM-to-generated-AOT boundary, RT64 Metal, iOS shell, input, save paths, diagnostics, and shutdown.
2. `CMakeLists.txt` — iOS deployment target, generated static libraries, `N64MODERN_NO_DYNAMIC_CODE=ON`, SDL2/static Apple linking, universal device family, app assets, and package shape.
3. `docs/BUILDING.md`, `docs/DEPENDENCIES.md`, and `dependencies.lock.json` — exact source graph and scripts.
4. `docs/TESTING.md`, `docs/STATUS.md`, `docs/KNOWN-ISSUES.md`, `docs/TECH-DEBT.md`, and `docs/HANDOFF.md` — accepted mechanisms versus unresolved limitations.
5. `patches/n64modernruntime/no-dynamic-code.patch`, Apple clean-exit patch, RT64 Metal patches, and every exact patch needed by the Apple target.
6. `apple/app/ios_main.mm`, `rom_setup.mm`, `diagnostics.mm`, `touch_tap_latch.h`, assets, privacy manifest, and notices.
7. `src/paperpad_main.cpp`, controller-slot code, RT64 context, paths, overlays, tests, and package audits.

PaperPad proves an N64Recomp/RT64 mobile architecture, not DK64 correctness. Reuse the AOT/no-dynamic-code/Metal/ROM/input/lifecycle/package mechanisms; port a Paper Mario-specific timing/audio/save/game hook only after DK64 reproduces the same need.

### 5.4 The requested UI reference: `ref/sunpad`

Clone `github.com/chrissotraidis/sunpad` and pin it to `e43f0ea6b797e5110787171957c9dc3c6213269c`.

Read in order:

1. `docs/ARCHITECTURE.md`, `docs/IOS_IPADOS.md`, `docs/TESTING.md`, `docs/STATUS.md`, `docs/KNOWN_ISSUES.md`, and `docs/TECH-DEBT.md`.
2. `apple/ios/SunPadGameOverlay.mm` and `.h` — touch rendering, independent fingers, edit mode, safe bounds, device layouts, and utility button.
3. `apple/ios/SunPadGameViewController.mm` — three-dot menu, loading phases, native presentation, lifecycle, controller visibility, diagnostics, and Game Data & Saves flows.
4. `apple/shared/SunPadSettings.*`, `SunPadInputState.h`, `SunPadInputMixer.*`, `SunPadControllerMapping.*`, `SunPadDiagnostics.*`, and controller-slot code.
5. `tests/` — controller mapping/disconnect, input encoding, diagnostics, game-data setup, touch defaults, and experimental-setting tests.
6. `apple/ios/Assets.xcassets/AppIcon.appiconset/PROVENANCE.md` — provenance pattern for original app artwork.
7. `scripts/audit-ios-package.sh`, packaging/provisioning scripts, privacy manifest, notices, and issue/report flow.

Use SunPad's interaction architecture and UI quality directly where rights and code shape allow. Do **not** copy its GameCube/Dolphin runtime, disc extractor, Sunshine controls, FLUDD pressure mapping, performance flags, or nested dynamic module assumptions into an N64/RT64 app.

### 5.5 Core toolchain and starting pins

Create a BananaPad-owned `dependencies.lock.json` with repository URL, exact commit, recursive submodule state, license path, patch-set hash, dirty-state rule, and purpose for every source. Initial research pins:

| Input | Role | Starting state |
|---|---|---|
| `Rainchus/Donkey-Kong-64-Recompiled` | Game implementation and desktop baseline | tag `1.0.1`, commit `c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43` |
| DK64Recompiled release channel / `main` | Upstream discovery and candidate source | newest fetched stable tag plus current `main`; research snapshot was `ee0455d131e0e2198821d35a88033b18524d75ba` |
| `chrissotraidis/paperpad` | N64/RT64 AOT Apple reference | `74b6e45830a06c7f274c5ac1ddd7c625bc13a557` |
| `chrissotraidis/sunpad` | Three-dot menu/touch/mobile UX reference | `e43f0ea6b797e5110787171957c9dc3c6213269c` |
| DK64 host N64Recomp/RSPRecomp | Generate game and RSP source | released workflow pin `2b6f05688de2abc7d86da5b4a89b84c2c6acbabe`; verify actual tool identity used by local generation |
| `Killklli/N64ModernRuntime` | DK64 runtime fork | `45bd0180f85c89c19ae45d30190be54c9d577904` |
| N64ModernRuntime nested N64Recomp | Runtime headers/live-recomp source boundary | recursive pin `81213c1831fab2521a6a5459c67b63437d67e253`; verify against lock |
| `Killklli/RecompFrontend` | Upstream desktop RmlUi/input/config comparison only | `6d187f7964a44801a4095287acc23a043033aff3` |
| `rt64/rt64` through DK64 submodule | Renderer and Metal RHI | `cc6d137a3cca95faa018f24ebb5ca765dbfa7cf2` |
| `dk64_decomp/dk64` through DK64 submodule | Decompression/header/symbol support | `2431154b417d4e80a6bfaf38291213c059be59f7` |
| `microsoft/vcpkg` through DK64 submodule | Desktop dependency graph | `114d9fe62faf35856b45cf55cb93b57028a45d63` |
| PaperPad-pinned SDL2/RT64/runtime sources | iOS-capable Apple substrate | resolve exact commits from PaperPad's `dependencies.lock.json`; do not substitute Homebrew shims |

These are starting pins, not permission to mix incompatible revisions. First reproduce DK64's stable graph. Then compare PaperPad's runtime/RT64 deltas and choose one controlled integration strategy:

1. apply PaperPad's Apple/no-dynamic-code patches to the DK64 fork pins;
2. rebase DK64's game-specific runtime changes onto PaperPad's proven pins; or
3. take a newer common upstream revision and rebase both patch sets.

Whichever route is selected must have a written diff/provenance map and rerun the affected D2–D11 gates. A broad promoted-pin change requires the full technical matrix before release. Do not “update everything” until the source graph happens to compile.

### 5.6 Upstream synchronization and promotion policy

The initial `1.0.1` baseline must remain reproducible, but the working BananaPad source graph is allowed—and expected—to advance when upstream fixes defects or publishes a better stable release.

Required files and scripts:

- `docs/UPSTREAM-SYNC.md` — dated record of promoted, last-observed, and candidate identities; release notes; categorized commit/file/submodule diff; generated hash changes; patch conflicts; affected goals/matrix rows; save/config migration; test evidence; promotion, deferment, rejection, and rollback decisions.
- `scripts/check-upstream.sh` — fetches tags and `main` without editing the promoted working tree; reports newer stable tags and commits since the promoted pin; never changes `dependencies.lock.json` automatically.
- `scripts/stage-upstream-update.sh <tag-or-sha>` — creates/recreates an ignored candidate worktree, initializes recursive submodules, applies the exact BananaPad patch series with zero fuzz, regenerates the standard derived outputs, and creates candidate-only lock metadata.
- `scripts/test-upstream-update.sh` — builds the pristine upstream macOS comparison and BananaPad hardened macOS target, runs source/host audits, then executes the impact-selected gameplay/save/audio/overlay tests and highest known-good smoke routes.
- `scripts/promote-upstream-update.sh` — refuses promotion unless required evidence exists, then performs one reviewable update of the promoted pin, recursive pins, patch-set hash, generated identities, migration notes, and docs.
- `scripts/rollback-upstream-update.sh` — restores the previous promoted lock/patch metadata and verifies the previous known-good build command/artifact; it does not delete ROMs, saves, evidence, or unrelated work.

Update procedure:

1. **Discover.** Check at G2 completion, major goal transitions, when an upstream defect may explain a blocker, and before any technical/public candidate.
2. **Select.** Prefer the newest stable tag for broad synchronization. A selected commit/range from `main` is permitted for a named fix when unrelated changes are excluded or explicitly reviewed.
3. **Categorize.** Classify changes as game logic, correctness patch, enhancement, overlay/decompression, RSP/audio, save/config format, input/settings, runtime/renderer, frontend-only, build/CI, documentation, or dependency/license.
4. **Rebase mechanically.** Apply BananaPad-owned changes as an external patch series or narrow adapters. Temporary manual edits may occur only inside the isolated candidate worktree; any retained edit must be exported into the BananaPad-owned patch series before formal testing or promotion. No in-place edit to the pristine or promoted reference is allowed.
5. **Invalidate derived state.** Regenerate game, patch, RSP, manifests, caches, and package inputs after any relevant source/submodule pin changes. Reuse only outputs whose complete input identity still matches.
6. **Test by impact.** During development, run all affected macOS routes plus the highest known-good smoke, static/no-dynamic-code audits, and save/config compatibility. An overlay/RSP/save/runtime change reopens the corresponding lowest goal. Before a technical or public candidate, rerun rows 1–33 and required physical-device gates against the exact promoted result.
7. **Promote or defer explicitly.** Promotion requires clean patch application, documented generated deltas, no unexplained regression, and a rollback point. A newer upstream release may be deliberately deferred, but `UPSTREAM-SYNC.md` must name the reason, missing tests, and known bugs left unfixed.
8. **Preserve rollback and bisectability.** Keep the previous lock, patch-set hash, baseline artifact/hash, known-good command, and compatible save backup. Never overwrite the initial `1.0.1` evidence; add a new promoted-baseline record.

Easy updating does **not** mean unattended tracking of upstream `main`. It means the port is structurally thin, pins are explicit, deltas are externalized, generated state is reproducible, tests are impact-aware, and promotion is reversible.

### 5.7 BananaPad technical source map

Create `docs/SOURCE-MAP.md` and record at minimum:

| Path/reference | What it establishes |
|---|---|
| DK64 `BUILDING.md` | Supported ROM hash, decompressed build input, host generation, native build, standard runtime ROM |
| DK64 `decompressor.cpp` | Named compressed overlays and appended decompressed layout |
| DK64 `us.toml` | Entry point, symbol inputs, generated game output, boot and overlay hooks |
| DK64 `patches.toml` + `patches/` | Static patch ELF, imports/exports/events, generated patch code/data, strict patch mode |
| DK64 `src/main/register_overlays.cpp` | Generated game-section registration |
| DK64 `src/main/register_patches.cpp` | Patch registration and the mobile-static conversion target |
| DK64 `src/game/recomp_api.cpp` | Overlay mapping, host APIs, input/settings, special routines, accessory behavior |
| DK64 `src/main/main.cpp` | GameEntry, ROM hash, `Eep16k`, RSP handler, SDL/Metal/audio, startup/shutdown |
| DK64 `src/game/config.cpp` | Camera, story, lighting, draw distance, sound, control descriptions/defaults, multiplayer state |
| DK64 `n_aspMain.toml` | Audio RSP generation range, function, and indirect branch targets |
| DK64 `CMakeLists.txt` + macOS entitlements | Desktop frontend, writable-text/JIT exceptions, current Apple build boundary |
| PaperPad `CMakeLists.txt` + architecture | Static generated libraries, no-dynamic-code profile, iOS RT64/SDL/Metal package |
| PaperPad Apple shell/runtime paths | ROM manager, N64 input, controller ownership, lifecycle, logs, clean exit |
| SunPad overlay/view-controller/shared paths | Requested menu, touch editor, settings, diagnostics, controller and loading UX |

Use source and generated manifests to turn every address, patch, and transition into a named behavior. Do not debug anonymous hex longer than necessary.

## 6. Phase 0 gate: reproducibility, comparison baseline, and rights state

Technical work may proceed privately once the following state is recorded. Publication may not proceed.

1. Create `docs/RIGHTS-STATUS.md` with initial state: **private technical work permitted by Chris; public source and public binary/IPA not yet approved**.
2. Record that DK64Recompiled and SunPad expose GPL-3.0 source licenses at the audited revisions. Inspect PaperPad's rights/license documents and every copied file. Do not describe the complete combined project as having one license until the dependency inventory is complete.
3. Create the local `bananapad` repository layout, `.gitignore`, and safety checks before generated output exists.
4. Pin all references, disable push URLs, refuse dirty reference trees, and create `dependencies.lock.json` with promoted/last-observed/candidate upstream fields plus patch-set hashes.
5. Create `docs/UPSTREAM-SYNC.md` and the check/stage/test/promote/rollback scripts from Section 5.6 before BananaPad accumulates vendor-tree edits.
6. Port/derive repository checks that reject ROM extensions/hashes, decompressed ROMs, `RecompiledFuncs`, `RecompiledPatches`, RSP-generated sources, patch binaries/data, saves, logs, crash dumps, screenshots, signing files, provisioning profiles, absolute user paths, and `ref/`/`generated/` contents.
7. Normalize and verify the standard ROM, derive the decompressed build ROM twice, and prove deterministic output.
8. Build N64Recomp/RSPRecomp at the exact starting pin. Generate game, patch, and audio RSP output into ignored directories and record hashes/warnings.
9. Build the pristine upstream `1.0.1` macOS target from source. If upstream's scripts or workflow depend on private `extra` content, identify each missing input and replace it with a public-source/user-ROM-derived local step; do not copy opaque private artifacts into the BananaPad pipeline.
10. Run the upstream comparison app: import standard ROM, reach gameplay, create/load progress, capture settings and logs, inspect its save, dump entitlements/Mach-O/load commands, and record current known defects.
11. Create `docs/UPSTREAM-BASELINE.md` with exact command, artifact hash, revision, ROM hash, generated-input hashes, macOS/SDK/hardware, screenshots, save evidence, entitlements, current settings, and behavior. Preserve this `1.0.1` record after future promotions.
12. Rehearse the synchronization lane in isolation: stage either the same pin as a deterministic no-op and, when available, a newer tag/SHA as a real candidate; prove patch application, regeneration, impact reporting, and rollback without changing the promoted pin.
13. Choose and record the public source topology without publishing it: separate BananaPad integration repository that fetches pinned references locally is the preferred starting topology.

G0–G2 are complete only when another clean local directory can reproduce the initial upstream comparison from documented public source plus the user's ROM **and** the upstream-sync scripts can stage and roll back a candidate without mutating the promoted state. A downloaded upstream release alone is not sufficient.

## 7. Phase 1 gates: static-code conversion, patches, overlays, RSP, and saves

### 7.1 Generation boundary

BananaPad must preserve the upstream generation model while moving all outputs under ignored `generated/` paths:

```text
Verified standard DK64 US ROM
          |
          +--> runtime-private imported copy
          |
          +--> deterministic decompressor
                         |
                         v
          ignored decompressed build ROM
                         |
          +--------------+----------------+
          |                               |
       N64Recomp                    RSPRecomp n_aspMain
          |                               |
   ignored game C/C++               ignored RSP C++
          |
   patch ELF + N64Recomp
          |
   ignored patch C/C++ + patch data
          |
          +--------------+----------------+
                         v
             static arm64 libraries/app
```

Provide single-purpose scripts whose output paths never require modifying the pristine references. Every generator warning must be captured and interpreted. Suppress a warning only after writing why it is harmless at the exact pin.

Required generated identities:

- standard ROM SHA-1/SHA-256;
- decompressed build ROM SHA-1/SHA-256 and length;
- `us.toml`/symbol-input hashes;
- N64Recomp and RSPRecomp executable hashes/commits;
- generated game source manifest/hash;
- generated patch source/data manifest/hash;
- generated RSP source hash;
- final static library and app hashes.

### 7.2 Static patch conversion — the primary mobile gate

Create `docs/AOT-AND-PATCHES.md`. Inventory every upstream patch source, generated function, exported symbol, imported host function, event, manual patch symbol, data section, binary blob, and runtime registration call.

Classify each item:

1. **Required baseline correctness** — necessary for DK64 to run correctly through credits.
2. **Retained upstream enhancement** — high frame rate, widescreen/HUD, analog camera, story skip, draw distance, lighting reduction, audio volume, control improvements, or another visible setting.
3. **Desktop frontend/config glue** — RmlUi, native file dialog, desktop-only text/font/menu behavior; replace with native Apple state/UI.
4. **Runtime mod/texture-pack support** — excluded from the baseline mobile build.
5. **Unknown** — cannot be removed or retained silently; trace callsites and create an experiment.

The accepted mobile design:

- generated game functions compile into a static `BananaPadGame` library;
- generated required patch functions/data compile into a static `BananaPadPatches` library or equivalent app objects;
- replaced functions resolve through compile-time/static registration or writable **data** dispatch tables;
- no native text section is made writable;
- `N64MODERN_NO_DYNAMIC_CODE=ON` or an equivalent verified compile-time profile excludes LiveRecomp and dynamic code paths;
- code mods and texture-pack executable modules are absent/disabled cleanly;
- no `.dylib` containing generated game code is required on iOS unless it is fully ahead-of-time, bundled, signed, and the architecture is explicitly approved. Prefer one static app executable, following PaperPad.

For every static patch conversion:

1. name the original target and patch function;
2. record whether it is correctness or enhancement;
3. prove the expected dispatch before and after conversion;
4. exercise at least one gameplay route that calls it;
5. add a host/source audit or regression;
6. confirm no W+X page and no forbidden entitlement appears.

Run a dedicated `scripts/check-no-dynamic-code.sh` that fails on the iOS/iPadOS candidate if it finds, as applicable:

- JIT/unsigned executable memory/disabled executable-page protection/disabled library validation entitlements;
- linkage to LiveRecomp/TCC or an included compiler intended for runtime code generation;
- code paths that call `mprotect`, `vm_protect`, or `mmap` to create writable-executable guest/mod code without a documented false positive;
- user executable mod/module directories or dynamic code loading in the release profile;
- upstream writable-text linker flags or custom `ld64` wrapper in the mobile link;
- unexpected executable writable segments in Mach-O inspection.

A simulator launch under a development environment is not enough. The architecture must pass source, build, entitlement, Mach-O, and runtime checks.

### 7.3 Compressed-code and overlay manifest

Create `docs/OVERLAYS.md` plus a machine-readable manifest generated from the pinned `us.toml`, decompressor, symbol data, and generated `recomp_overlays.inl`.

The upstream `load_dk64_overlay` map at the starting pin provides this initial audit table; verify every value against generated output before using it as runtime truth:

| Class | Compressed ROM trigger | Decompressed ROM section | Runtime RAM | Generated size |
|---|---:|---:|---:|---:|
| `global_asm` | `0x113F0` | `0x2000000` | `0x805FB300` | `0x165D50` |
| `menu` | `0xCBE70` | `0x2165D50` | `0x80024000` | `0xFF10` |
| `multiplayer` | `0xD4B00` | `0x2175C60` | `0x80024000` | `0x3100` |
| `minecart` | `0xD6B00` | `0x2178D60` | `0x80024000` | `0x4E10` |
| `bonus` | `0xD9A40` | `0x217DB70` | `0x80024000` | `0x9EF0` |
| `race` | `0xDF600` | `0x2187A60` | `0x80024000` | `0xC160` |
| `critter` | `0xE6780` | `0x2193BC0` | `0x80024000` | `0x61B0` |
| `boss` | `0xEA0B0` | `0x2199D70` | `0x80024000` | `0x12DC0` |
| `arcade` | `0xF41A0` | `0x21ACB30` | `0x80024000` | `0x26C00` |
| `jetpac` | `0xFD2F0` | `0x21D3730` | `0x80024000` | `0xAC30` |

For every executable section/class record:

- logical name and gameplay owner;
- generated section/index and symbol prefix;
- compressed ROM trigger/range;
- decompressed ROM range and derivation;
- runtime destination and complete replaced span;
- text/data/BSS boundaries where applicable;
- predecessor/successor and return transition;
- static patch profile active in the route;
- callsite/loader hook;
- test scene/save that proves execution;
- evidence path and known limitations.

Rules:

- Register all generated sections before any indirect call can target them.
- Preserve the upstream boot overlay hook and runtime `load_dk64_overlay` behavior unless a tested static route supersedes it.
- Log overlay/class load and active identity with ROM/RAM/size/section information.
- Treat the shared `0x80024000` destination as an overlap/replacement boundary. A class working once does not prove return or next-class correctness.
- Never silence a partial-unload/mapping assertion by arbitrary range widening. Reconcile generated section boundaries and actual replaced bytes.
- Do not mark `arcade` or `jetpac` green because their title frames appear; obtain the required coin and return to the main game.
- The `multiplayer` class is not a baseline feature. Its disabled setting/path must remain safe; do not spend progression time repairing it unless all lower goals are green and a separate decision authorizes it.

### 7.4 RSP and audio gate

Create `docs/RSP.md`. The starting `n_aspMain.toml` identifies a fixed audio microcode text region at decompressed ROM offset `0x2146010`, size `0xC30`, address `0x04001080`, output function `n_aspMain`, plus explicit indirect branch targets. Verify these values and the generated source/hash at the pinned ROM/tool revision.

Required process:

1. Generate `n_aspMain.cpp` from the verified decompressed build ROM.
2. Register the handler exactly as the upstream working app does.
3. Confirm no unsupported runtime RSP overlay or hidden HLE fallback is required.
4. Preserve the stable upstream audio task scheduling first; port a PaperPad audio patch only after reproducing its underlying need in DK64.
5. Integrate the Apple audio session deliberately. Record SDL sample format/rate, guest cadence, host conversion/resampling, queue thresholds, and route state.
6. Test title/intro music, DK Rap/cutscene audio where applicable, world music/ambience, Kong voices, UI/menu, weapons, instruments, animal/vehicle sounds, bosses, arcade, Jetpac, transitions, and credits.
7. Measure queue depth, underruns/overruns, discontinuities, pitch, long-run drift, and resume behavior.
8. Test macOS built-in, headphones/Bluetooth where available, and external/HDMI route; test iOS speaker, Bluetooth, wired/USB route where available, route change, phone/audio interruption, background/foreground, and controller audio if exposed.

A title screen with silent, truncated, static-filled, incorrectly pitched, or route-fragile audio does not pass D4.

### 7.5 Save and accessory gate

Create `docs/SAVE-AND-ACCESSORIES.md`.

Preserve the upstream `Eep16k` runtime setting initially. Do not rename it to “16 KiB,” “2 KiB,” or another byte count until the actual persisted representation and runtime API are inspected. Record:

- guest-visible EEPROM operations and expected logical size;
- host save filename/path/length/format;
- why upstream selected `Eep16k` instead of `Eep4k`;
- any extra BananaPad/upstream settings stored in or alongside the save;
- exact compatibility with the archived desktop `1.0.1` save and the currently promoted upstream desktop save;
- whether automatic migration is safe or must be an explicit user action.

Test:

- blank save/file-select initialization;
- Adventure file creation and slot isolation;
- persistent Golden Bananas/keys/Kongs/moves/coins/settings required by game logic;
- repeated autosave/manual-trigger points discovered in gameplay;
- clean exit and immediate relaunch;
- forced termination after a completed write and during a deliberately instrumented write window;
- backup and recovery behavior;
- erase/new-file flow;
- ROM reimport without unintended save deletion;
- standard ROM removal without unintended save deletion;
- desktop-upstream save import/copy into BananaPad and BananaPad save readback in the desktop baseline, where format compatibility is intended;
- no cross-talk among test saves or app identities;
- no write past the runtime's verified EEPROM/save allocation.

Accessory policy:

- Standard P1 controller input is required.
- The no-Controller-Pak/no-accessory path is the default and must never hang.
- The current source returns `PFS_ERR_DEVICE` for the Controller Pak initialization path; verify that this is the expected safe absence behavior.
- Rumble is supported when the selected runtime and Apple controller expose it; absence alone is not a progression blocker. Capability/failure must be logged cleanly.
- Physical-controller gyro may remain experimental when inherited safely; mobile device motion is not required for baseline.
- Do not expose unsupported accessory or multiplayer claims.

### 7.6 Phase 1 pass condition

Phase 1 is complete only when:

- exact standard/decompressed ROM generation is reproducible;
- game, static patches, and RSP output generate and compile from pinned public source;
- the complete static patch manifest exists;
- the mobile build/link profile has no forbidden dynamic-code requirement;
- all required executable sections/classes are registered and inventoried;
- the fixed audio RSP path is explicit;
- save/accessory behavior is explicit and tested at host level where possible;
- warnings, removed desktop features, retained enhancements, and open risks are recorded.

## 8. Phase 2: hardened macOS bring-up and complete-game path

Build the pipeline through scripts rather than terminal archaeology. Provide at minimum:

```text
scripts/check-prerequisites.sh
scripts/clone-sources.sh
scripts/verify-sources.sh
scripts/prepare-rom.sh
scripts/build-host-tools.sh
scripts/generate-game.sh
scripts/generate-patches.sh
scripts/build-upstream-macos-baseline.sh
scripts/build-macos-app.sh
scripts/build-ios-simulator.sh
scripts/build-ios-device.sh
scripts/run-smoke.sh
scripts/capture-crashes.sh
scripts/check-no-dynamic-code.sh
scripts/check-repo-safety.sh
scripts/audit-ios-package.sh
scripts/package-unsigned-ipa.sh   # created/tested locally; publication not authorized
```

### 8.1 Hardened macOS bring-up ladder

Each rung is tested immediately and backed by logs/screenshots:

1. BananaPad native process starts with the no-dynamic-code/static-patch profile and creates an RT64 Metal surface.
2. The native first-run UI accepts `.z64`/`.v64`/`.n64`, normalizes privately, verifies exact size/hash/identity, rejects wrong files, and stores no public/game data outside the private app path.
3. Static game/RSP/patch libraries register; resident/boot code reaches the title without RecompFrontend/RmlUi.
4. Keyboard and physical controller navigate title, intro, file select, and name/file creation where applicable.
5. The opening Training Grounds route works: movement, jump, attack, Z actions, camera, first-person view, C controls, R center, pause, cutscene skip behavior, and relevant tutorial barrels are usable.
6. DK Isles loads and the first Golden Banana outside the Jungle Japes entrance is collected.
7. Jungle Japes loads; an exact, written in-level Golden Banana objective is completed. The route must exercise normal movement, camera/first-person aiming, combat or interaction, loading/transition, and a persistent state change.
8. Progress visibly updates, the app completes pending save work, and exits without a teardown crash or orphan process.
9. Relaunching the same artifact with the same ROM restores the same Adventure file, first Golden Banana, world access, and in-level progress.
10. The same route is repeatable from a clean local app-data directory through one scripted setup command plus hands-on gameplay.

Only after rung 10 works may BananaPad be described as playable. Package a normal macOS `.app` for comparison/testing; macOS publication is not automatically authorized by this PRD.

### 8.2 Complete required progression

Complete at least one observed fresh-save golden path through:

- opening tutorial/Training Grounds;
- DK Isles/K. Lumsy/B. Locker world progression;
- Jungle Japes;
- Angry Aztec;
- Frantic Factory;
- Gloomy Galleon;
- Fungi Forest;
- Crystal Caves;
- Creepy Castle;
- Hideout Helm;
- required Nintendo Coin and Rareware Coin gates;
- final K. Rool sequence;
- credits and post-credit/completed-file return.

Record every required unlock and gate: all five Kongs, required Slam/weapon/instrument/potion progress, boss keys, world access, required Golden Bananas/colored bananas/medals/crowns/blueprints/fairies/coins only to the extent needed by the chosen legal route, and all persistent state.

A later-game ignored save fixture is allowed for fast regression. Maintain several named local fixtures when useful:

- first-play/Jungle Japes;
- all-Kongs/mid-game;
- arcade/Jetpac access;
- late-game/Hideout Helm;
- final boss/credits;
- optional 101% content audit.

Fixtures never replace the fresh-save proof and never enter Git or a public package.

### 8.3 Special-code and system acceptance

Maintain a route sheet that explicitly triggers:

- main/global gameplay and world loading;
- file select/options/menu code;
- at least one minecart sequence and return;
- representative bonus barrels and return;
- representative race and return;
- representative critter/minigame path and return;
- every required boss class and return;
- original Donkey Kong arcade play sufficient to obtain the Nintendo Coin;
- Jetpac play sufficient to obtain the Rareware Coin;
- final menu/game transitions after both embedded games.

Also test:

- each playable Kong, tag barrel switching, and Kong-specific move/weapon/instrument;
- Cranky, Funky, Candy, Snide, Wrinkly, Troff 'n' Scoff, and B. Locker flows;
- first-person aiming, analog camera option, fairy camera, zoom, swimming, boat/vehicle, transformations/animal helpers, oranges, instruments, weapon ammo, health/death/retry, pause, cutscene skip, and loading zones;
- boss entrances/exits, game-over/continue, file erase/new file, and credits return.

Do not mark D6 complete from source inspection or a cheat-warp title screenshot. The path must be observed against the exact build and save.

### 8.4 Baseline and enhancement policy

The stable baseline means the **currently promoted upstream pin plus BananaPad's accepted mobile adaptations**. The initial `1.0.1` comparison remains archived for bisecting and regression diagnosis, but it does not prevent promotion to a newer upstream release. The promoted baseline must remain available and testable:

- original 4:3 framing;
- original game cadence/frame-rate option;
- vanilla-compatible camera and gameplay behavior;
- multiplayer disabled;
- code mods/texture packs disabled;
- safe/default draw distance and effects.

Then retain upstream enhancements one at a time where practical:

- high-frame-rate/display-rate support;
- widescreen/expand and HUD positioning;
- analog camera/right stick;
- camera inversion/sensitivity;
- story skip;
- lightning intensity reduction;
- draw-distance adjustment;
- BGM/SFX volume;
- rumble/gyro options when supported.

Each enhancement has an explicit setting key, default, restart/live-apply semantics, diagnostic identity, and regression route. A setting that cannot be preserved safely may be temporarily hidden with a documented reason; it may not silently do nothing.

## 9. Phase 3: iPadOS/iOS, touch controls, native menu, icon, and lifecycle

### 9.1 Minimal Simulator core

Port the PaperPad-proven N64/RT64/Metal build profile before the full UI:

- iOS/iPadOS arm64/Simulator target with iPhone+iPad device family;
- no JIT/dynamic-code profile;
- static game/patch/RSP libraries;
- pinned SDL2/static Apple dependencies where retained;
- RT64 direct Metal backend and correct `CAMetalLayer` ownership/lifetime;
- private writable RT64/config/save paths;
- native app lifecycle entry;
- landscape-only baseline, supporting both landscape-left and landscape-right safe areas;
- current PaperPad-proven minimum deployment target unless the reconciled dependency graph requires a higher explicit target.

Build and run **iPad Simulator first**. Shut it down completely before booting an iPhone Simulator. Prove title and the full first-play loop on each before adding every menu option.

### 9.2 Shell extraction strategy

Use the references by layer:

- From **PaperPad**, take the N64 ROM manager/normalization/hash boundary, AOT/no-dynamic-code build shape, RT64 Metal bridge, N64 input snapshot, controller-slot ownership, paths, diagnostics privacy boundary, lifecycle, save completion, and clean-exit handling.
- From **SunPad**, take the three-dot utility button/menu hierarchy, honest startup phases, overlay editor, device-specific normalized layouts, native settings organization, touch/controller auto-hide, Game Data & Saves UX, report flow, controller tests, and app-icon provenance pattern.
- From **DK64Recompiled**, preserve game input semantics, settings values, static patches, game entry, overlay/RSP/save behavior, and enhancement logic.

Do not rename copied code mechanically. First isolate game-neutral behavior, create BananaPad-owned types/settings/tests, and then adapt labels, paths, defaults, and controls.

### 9.3 DK64 touch controls

The touch overlay must expose the complete N64 input set and be designed around DK64's context-sensitive chords.

Default visible controls:

- fixed-origin left analog stick with a forgiving pickup region and full outer magnitude;
- large **A** (jump/select/context action);
- large **B** (context-sensitive attack);
- prominent **Z** hold control (crouch/modifier);
- **R** (camera center/tighter boat turn);
- **Start** (pause/cutscene skip where supported);
- four distinct **C** directions or a clearly segmented C cluster;
- optional right analog camera region when the upstream Analog Camera mode is enabled.

Controls available in edit/mapping mode even if de-emphasized by default:

- **L**;
- D-pad Up/Down/Left/Right;
- every C direction independently;
- any utility mapping needed for accessibility without changing guest semantics.

Required chords and contexts:

- Z+A;
- Z+B;
- Z+C-Up (instrument context);
- Z+C-Down (fairy camera context);
- Z+C-Left (fruit weapon context);
- Z+C-Right (orange context);
- C-Up first-person view;
- C-Down zoom;
- C-Left/C-Right original camera rotation;
- R camera center;
- simultaneous movement plus A/B/Z/C actions;
- swimming/vehicle and first-person aiming.

Touch rules:

- independent fingers and stable touch ownership; no single-touch serialization;
- Z remains held while another finger presses A/B/C, and releases exactly when its finger/cancel event ends;
- stick/C/right-camera regions cannot steal button touches;
- slide-out, cancellation, interruption, menu, picker, controller handoff, background, orientation reversal, runtime stop, and ROM removal clear held state;
- no hidden control remains logically pressed;
- physical controller takeover hides gameplay touch controls when configured but leaves the three-dot utility control available;
- iPhone and iPad defaults use separate schema/version keys;
- edit mode supports move, per-control size, per-control opacity, visibility, safe bounds, reset, and grouped/ungrouped C/D-pad movement where useful;
- no essential control is behind an edge/home-indicator unsafe area;
- an optional Z latch/accessibility mode may be explored only as an explicit visible setting; hold behavior remains the baseline and tests must prevent accidental latch.

### 9.4 Three-dot menu

Use SunPad's native three-dot menu organization and interaction discipline, adapted to RT64/DK64. Minimum entries:

**Resume**

**Graphics**

- Render Resolution: `Auto` plus supported `1x`–`4x` values using PaperPad/RT64-confirmed semantics;
- Aspect Ratio: Original 4:3 baseline; Widescreen/Expand and Fill/crop only when their DK64-specific behavior is clear and tested;
- Frame Rate: expose only settings supported by the upstream DK64 hooks; include Original/stable baseline and clearly identified enhanced modes;
- HUD aspect/position option where the upstream renderer supports it;
- image filtering/anti-aliasing options only where RT64 supports them safely;
- Draw Distance;
- Cutscene Borders;
- Lightning Flash Intensity;
- any high-precision framebuffer option only after visual and memory evidence.

**Controls**

- Touch Controls on/off;
- Hide Touch Controls When Controller Connected;
- Edit Layout;
- Reset Layout;
- per-control/global opacity and size where the selected architecture supports them;
- Camera Type: Free, Follow, Better Free, Analog Camera;
- camera/aim/swimming inversion and analog-camera sensitivity;
- controller mapping/status;
- rumble/gyro options only when supported and clearly labeled.

**Gameplay**

- Story Skip with the upstream meanings/default;
- other retained upstream gameplay-facing options only after their native setting bridge is tested;
- Multiplayer omitted or explicitly disabled/WIP; never imply support.

**Audio**

- Background Music volume;
- Sound Effects volume;
- current output-route/status details only when useful and privacy-safe.

**Game Data & Saves**

- Import or Reimport Supported ROM;
- Import from BananaPad Folder where a safe local-folder path is implemented;
- Verify/Show Supported ROM identity without exposing bytes or a private path;
- Remove Stored Game Data, with an explicit statement that saves remain unless the user separately chooses otherwise;
- Save status/location description and safe backup/export/import actions only if implemented atomically and tested;
- no raw save editor.

**Diagnostics and About**

- Share Diagnostic Log;
- Report a Problem;
- Add Screenshot Marker;
- About BananaPad;
- Third-Party Notices;
- Rights/ROM wording;
- exact app/build/core/dependency-lock identity.

Native UI rules:

- opening any menu suppresses guest input and clears held state;
- settings persist in app config, not by mutating the ROM;
- live changes have observed effect and diagnostics; restart-required settings say so and apply only on next launch;
- no synthetic loading percentage. Use honest phases such as Preparing Runtime, Verifying Game Data, Registering Static Code, Starting Game, and Waiting for First Frame;
- a visible boot failure replaces a permanent black screen;
- every option has a stable baseline/default and a migration path for corrupt/old preferences.

### 9.5 ROM management on iOS/iPadOS

Adapt PaperPad's N64 native picker flow and SunPad's hardened staging UX:

1. Present a clear first-launch explanation that BananaPad requires the user's legally obtained supported US ROM and contains no game data.
2. Use a native document picker and security-scoped access correctly.
3. Copy the selected file into a unique private staging directory.
4. Normalize `.z64`/`.v64`/`.n64` in staging; require exact size/hash/identity.
5. Activate the private normalized standard ROM atomically only after validation succeeds.
6. A failed import removes staging and leaves the prior working ROM untouched.
7. Reimporting the same filename is supported.
8. Removing stored game data stops the runtime safely and deletes only the ROM/private derived game-data copy, not saves, settings, or logs unless explicitly selected.
9. The app never imports or stores the decompressed build ROM as user game data.
10. ROM bytes, filenames where avoidable, and absolute private paths are excluded/redacted from diagnostic exports.

Add a headless/test launch path for valid/invalid import fixtures that contains no real ROM in Git. Structural tests may use tiny synthetic files; exact-ROM acceptance remains local and private.

### 9.6 App icon and visual identity

Create an original BananaPad icon; do not reuse upstream DK64 launcher art, Nintendo/Rare logos, Kong characters, game bananas/coins, screenshots, textures, or another project's icon.

Approved creative direction: a simple original **generic banana curve integrated with a neutral controller-pad motif**, with no text or recognizable Nintendo controller silhouette. Generate or draw it as original project artwork.

Required artifacts:

- editable/source master under `design/app-icon-source/`;
- opaque 1024x1024 master suitable for the current Xcode app-icon workflow;
- `port/apple/Assets.xcassets/AppIcon.appiconset` or current Icon Composer asset with Any/light, dark, and tinted/clear appearances where supported and appropriate;
- `PROVENANCE.md` recording creation date, tool/process, prompt or design brief, selected source hash, modifications, and explicit statement that no third-party game art/marks were used;
- packaged iPhone/iPad icon plus macOS icon if the BananaPad macOS app ships.

Acceptance:

- no baked rounded corners or unintended transparency/halo;
- no clipping under system masks;
- readable at small Settings/search size and large Home Screen size;
- correct on iPhone and iPad Home Screen, app switcher, Settings/search, install sheet, and package inspection;
- current appearance modes do not make the symbol disappear or resemble an official Nintendo product;
- source/package audit confirms only the approved original assets are included.

### 9.7 Controller and lifecycle

BananaPad is single-player P1 for baseline. Preserve robust ownership:

- enumerate existing controllers at launch;
- retain stable instance/player slots;
- reconcile on add/remove/remap, foreground return, and periodically while active;
- close stale handles and release held input;
- a sole returning controller reclaims P1;
- touch hides/restores according to settings;
- no controller restarts or player replacement during normal reconnect;
- map all N64 controls and preserve analog range/deadzone;
- report controller type/capabilities without serial/private identifiers.

Lifecycle:

- pause/suppress input before background;
- complete or safely defer EEPROM writes;
- deactivate/reactivate audio session correctly;
- stop/preserve renderer resources according to the proven PaperPad/RT64 Apple path;
- resume the same runtime when safe or perform an explicit clean relaunch path when not;
- clear held input on every transition;
- respond to memory warning without deleting active game/save state;
- support both landscape orientations and safe-area changes;
- handle native menu/picker/share sheet, phone/audio interruption, screen lock, natural sleep/wake, and external display changes without false acceptance.

### 9.8 Diagnostics and privacy

Wire breadcrumbs early. Minimum events:

- app/build/core/dependency-lock identity;
- boot phase and first frame;
- ROM present/verified identity hash (never bytes);
- generated game/patch/RSP identities;
- static-code profile and no-dynamic-code status;
- renderer/Metal/device/screen/resolution/aspect/frame-rate mode;
- overlay class load/use/return;
- patch profile and dispatch errors;
- RSP/audio mode, queue warnings, interruption, route change;
- controller ownership and touch hide/show;
- input clear and chord-test markers;
- save open/write/flush/error without contents;
- lifecycle/orientation/memory warning;
- runtime warning/error/crash marker;
- screenshot marker;
- clean exit.

Store current/previous bounded private logs under Application Support, exclude from backup, use data protection where available, and rate-limit repeated messages. The user-facing report may include app/OS/device/screen/controller/settings and bounded logs, but excludes ROM/decompressed ROM/generated code/save contents/controller input history/signing material/private container paths. State honestly that reports require user review and are not guaranteed fully anonymous.

### 9.9 Timing, rendering, performance, and thermals

Establish baseline and enhanced profiles separately:

1. Record the original-mode game update cadence, VI/present cadence, audio task cadence, and input polling in title, Training Grounds, DK Isles, each world, boss, minecart/race/bonus, arcade, Jetpac, Hideout Helm, final fight, and credits.
2. Record RT64 internal resolution, drawable size, scale, aspect/HUD mode, frame pacing, CPU/GPU time, memory, thermal state, and audio queue.
3. On macOS, compare BananaPad static core against the app built from the currently promoted upstream pin in the same scenes/settings; retain the archived `1.0.1` comparison for bisecting when behavior changes across promotions.
4. On Simulator, record diagnostic performance only.
5. On physical iPad/iPhone, test original/stable mode first. Then test high-frame-rate/widescreen/analog-camera modes independently.
6. Include 60 Hz and high-refresh devices where available; do not equate monitor refresh with verified game timing.
7. Profile worst-case and long-run behavior, not just average FPS. Include loading, transitions, particle-heavy scenes, water, bosses, arcade/Jetpac, and native UI return.
8. Keep an experimental setting default-off if it changes gameplay timing, audio, physics, UI, power, or thermal behavior and lacks full evidence.

A performance claim must include device, OS, build, settings, scene, duration, thermal state, observed frame/pacing measurements, and artifact hash.

## 10. Phase 4: test matrix

Adopt the evidence rules from PaperPad and SunPad: compilation is not gameplay; configured behavior is not observed behavior; run only one Simulator and one game instance at a time; a Simulator cannot prove device behavior; a fixture cannot prove a fresh playthrough; and a different artifact proves nothing about the candidate.

Capture dated evidence for every row: target, hardware/Simulator, OS/SDK, build configuration, BananaPad revision, dependency-lock hash, DK64/PaperPad/SunPad pins, ROM hash, generated game/patch/RSP hashes, commands, settings/profile, save identity, logs, screenshots/captures, result, and remaining defects.

| # | Row | Target | Pass condition |
|---|---|---|---|
| 1 | Repository safety and rights state | repo | `RIGHTS-STATUS.md` exists; private/public state is explicit; ROM/decompressed-ROM/AOT/patch/RSP/save/log/signing/ref/generated patterns are ignored and rejected |
| 2 | Dependency pins, clean references, and sync metadata | clean checkout | DK64Recompiled promoted/last-observed/candidate identities, PaperPad, SunPad, nested runtime/renderer/tools and patch-set hashes match `dependencies.lock.json`; references are clean; push disabled; `UPSTREAM-SYNC.md` is current |
| 3 | Exact standard ROM | local private input | Byte order normalized; size and SHA-1 `cf806ff2603640a748fca5026ded28802f1f4a50` pass; wrong revision/format is rejected safely |
| 4 | Deterministic decompressed build ROM | fresh generated dir | Pinned decompressor creates identical output twice; lengths/hashes/overlay layout recorded; original untouched |
| 5 | Game, patch, and RSP generation | fresh generated dir | N64Recomp/RSPRecomp and patch build complete; output manifests/hashes exist; warnings interpreted; no generated code enters Git |
| 6 | Initial upstream `1.0.1` baseline and promoted comparison | macOS hands-on | Archived `1.0.1` source build imports the standard ROM, reaches gameplay, audio/input/save/reload work, and entitlements/settings/artifact are captured; any newer promoted pin has an equivalent comparison record and documented delta |
| 7 | Static patch/no-dynamic-code audit | macOS + iOS build | Required patches are AOT/static; no W+X requirement, LiveRecomp/JIT/TCC/user executable code, forbidden entitlements, writable-text linker route, or unexpected executable writable segment |
| 8 | BananaPad boot to title | macOS, iPad Sim, iPhone Sim | Native shell reaches title with Metal, audio, input, static patches, RSP, clean log; first-frame loading state clears |
| 9 | ROM import/reimport/remove | macOS + both Sims | Correct ROM imports atomically; wrong/truncated ROM rejected; reimport preserves prior valid data on failure; remove stops runtime and preserves saves/settings |
| 10 | First-play loop | macOS hands-on + iPad Sim hands-on | Adventure file, Training Grounds, DK Isles, first Golden Banana, Jungle Japes objective, save, exit/relaunch/load complete |
| 11 | Jungle Japes | macOS hands-on | Required route/boss/progression, Kong interactions, audio/render/input/save and load transitions pass |
| 12 | Angry Aztec | macOS hands-on | Required route/boss/progression and relevant Kong/vendor/temple/transition systems pass |
| 13 | Frantic Factory | macOS hands-on | Required route/boss/progression, factory rendering/audio and arcade access/return pass |
| 14 | Gloomy Galleon | macOS hands-on | Required route/boss/progression, swimming/water/boat/render/audio behavior pass |
| 15 | Fungi Forest | macOS hands-on | Required route/boss/progression, time/lighting/cutscene and loading behavior pass |
| 16 | Crystal Caves | macOS hands-on | Required route/boss/progression, heavy effects/particles/audio and transitions pass |
| 17 | Creepy Castle | macOS hands-on | Required route/boss/progression, camera/lighting/audio and transitions pass |
| 18 | Hideout Helm, K. Rool, credits | macOS hands-on | Required gates, timed Helm sequence, final fight phases, credits, post-credit return and completed-save reload pass |
| 19 | All Kongs, moves, vendors, tag system | macOS + iPad Sim | Five Kongs, tag barrels, required Cranky/Funky/Candy/Snide flows, weapons/instruments/moves and persistence work |
| 20 | Menu overlay and file/options paths | all three | File select/options/pause/native utility transitions work; input suppression and return leave no stale mapping or held input |
| 21 | Minecart, race, bonus, critter classes | macOS + iPad Sim | At least one representative of each class loads, plays, completes/fails/retries as applicable, returns, saves, and can be followed by another class |
| 22 | Boss class | macOS | Required bosses load, play, defeat/retry, return, progress and save without stale overlay/patch/audio state |
| 23 | Donkey Kong arcade / Nintendo Coin | macOS hands-on + iPad Sim hands-on | Arcade class loads, controls/audio/rendering work, required objective/coin is obtained, return and save pass |
| 24 | Jetpac / Rareware Coin | macOS hands-on + iPad Sim hands-on | Jetpac class loads, controls/audio/rendering work, required score/coin is obtained, return and save pass |
| 25 | EEPROM save and compatibility | macOS + iPad Sim | Blank/create/repeated write/relaunch/erase/recovery/termination/slot isolation pass; actual `Eep16k` host format documented; intended desktop compatibility verified |
| 26 | Audio continuity and routes | macOS + iPad Sim + physical later | Music/voices/UI/weapons/instruments/arcade/Jetpac/transitions/credits have correct pitch and no sustained underrun/static; route/interruption/resume evidence captured |
| 27 | Baseline timing/rendering | macOS + physical later | Original framing/cadence measured; HUD/effects/fog/depth/water/cutscenes/frame pacing/memory remain within documented baseline |
| 28 | Enhanced modes | macOS + both Sims + physical later | Each exposed high-FPS/widescreen/HUD/analog-camera/draw-distance/lighting/story setting works, persists, reports identity, and passes relevant gameplay; failed modes remain default-off/hidden |
| 29 | DK64 touch overlay and chords | iPad Sim hands-on + iPhone Sim hands-on | Every required control and Z chord works with independent fingers; stick/camera/first-person/swimming/vehicle contexts, edit/reset/safe areas and no stuck input pass |
| 30 | Three-dot menu/settings/controller | both Sims | Menu hierarchy works; settings persist/apply honestly; controller P1 handoff, touch hide/show, disconnect/reconnect, mapping, input clear, and native-UI suppression pass |
| 31 | Lifecycle, orientation, memory, diagnostics, icon | both Sims + package | Background/foreground, interruption, landscape reversal, memory warning, renderer/audio return, clean stop, bounded privacy report, app-icon asset/provenance/presentation pass |
| 32 | Repeated transitions and 90-minute soak | macOS + iPad Sim | Repeated world/menu/special-class/save/native-UI cycles complete; stable memory, overlays, patches, audio, input and saves; no orphan process |
| 33 | Regression suite, clean clone, audits, and upstream-update rehearsal | fresh directory + isolated candidate | Host/source tests and scripted smoke routes pass; full build reproduces from scripts/public pins/local ROM; repository/no-dynamic-code/Mach-O/package audits are green; the check/stage/patch/regenerate/impact-test/promote-metadata/rollback workflow is rehearsed without mutating the last known-good pin; no undocumented manual step |
| 34 | Exact public candidate | physical iPad + physical iPhone + repo/package | Chris plays exact candidate through first-play and later-game/special fixtures; touch/controller/audio/lifecycle/sustained play pass; source/binary rights decisions and audits pass; hash recorded and explicitly approved |

Rows 1–33 are the technical candidate bar. Row 34 is not implied by Simulator success. Public source and public binary/IPA releases are separate decisions and may have different outcomes.

## 11. Evidence, journal, and reporting

Maintain in `docs/`:

- `JOURNAL.md`: append-only and dated. Every session records lowest unmet goal, hypothesis, exact step/commands, result, evidence, interpretation, blocker analysis, and next step.
- `STATUS.md`: current goal, bring-up rung, matrix state, current known-good commands/artifact hashes, active profile/save, and open defects. Keep current.
- `RIGHTS-STATUS.md`: private/public authorization, GPL/dependency inventory, copied-file provenance, app-icon provenance, source topology, binary decision, and approvals needed.
- `DEPENDENCIES.md` plus `dependencies.lock.json`: every repository/revision/submodule/license/patch, promoted/last-observed/candidate upstream identity, patch-set hash, and update history.
- `UPSTREAM-SYNC.md`: upstream checks, release/tag/commit/submodule diffs, impact category, generated hash deltas, patch-rebase state, affected goals/matrix rows, migration tests, promotion/deferment/rejection, and rollback evidence.
- `ROM-INPUTS.md`: standard/decompressed boundary, exact local hashes/lengths, normalization/decompression commands, and no-distribution rule. Do not include bytes.
- `UPSTREAM-BASELINE.md`: immutable initial `1.0.1` source-build record plus append-only promoted-baseline records with artifact, entitlements, settings, screenshots, save/config compatibility, known issues, generated identities, and comparison commands.
- `SOURCE-MAP.md`: game/runtime/reference path map and ownership.
- `AOT-AND-PATCHES.md`: generated code identities, patch classification, dispatch/static conversion, removed dynamic paths, audits, and gameplay regressions.
- `OVERLAYS.md`: complete compressed-code/section manifest, observed sequences, stale/lookup defects, and evidence.
- `RSP.md`: microcode identity, generation, handler, task/audio behavior, failures, and profiles.
- `SAVE-AND-ACCESSORIES.md`: actual EEPROM/save contract, compatibility, writes/recovery, accessory/rumble/gyro behavior.
- `INPUT.md`: guest control semantics, touch/controller mapping, chord matrix, layout versions, and ownership/lifecycle tests.
- `PERF.md`: cadence, renderer dimensions/settings, profiles, frame pacing, audio queue, memory, thermals, enhancement tests, and soak history.
- `KNOWN-ISSUES.md`: reproducible current defects, severity, affected goal/matrix rows, workaround, owner/next experiment.
- `RELEASE-READINESS.md`: exact source/artifact hashes, matrix summary, device evidence, audits, notices, icon provenance, rights decisions, and explicit go/no-go.
- `artifacts/`: local ignored screenshots, videos, profiles, logs, entitlement/Mach-O dumps, crash captures, package listings, and save hashes, organized by date/goal/target.

Evidence standards:

- A source read proves source intent only.
- A generated directory proves generation only.
- A link proves compilation only.
- A process/PID proves launch only.
- A screenshot proves one frame only.
- A configured overlay/save/control proves configuration only.
- A scripted input route proves that script on that build; rows marked hands-on still require real interaction.
- A Simulator proves only that Simulator/OS/build.
- A later-game fixture proves only the exercised fixture state.
- An upstream binary proves comparison behavior, not BananaPad behavior.
- A different artifact proves nothing about the candidate.

Honesty rule: **if it was not run and observed, it is not done.** Do not convert source availability, upstream success, or a GO decision into gameplay, performance, persistence, physical-device, legal, or release claims.

## 12. Public release, GPL, game rights, provenance, and wording

This section is an engineering release gate, not legal advice.

### 12.1 Current state

At the audited revisions:

- Donkey Kong 64: Recompiled exposes GPL-3.0 licensing for its integration source.
- SunPad exposes GPL-3.0 licensing for its source.
- PaperPad documents a separate rights/dependency boundary; inspect the actual license/provenance of every copied file and dependency.
- Nintendo/Rare game copyrights, trademarks, ROM data, art, audio, and translated game logic are not relicensed by those integration repositories.

Therefore:

- private local feasibility work may proceed under Chris's direction;
- public BananaPad source must satisfy GPL-3.0 and every other exact dependency/license obligation;
- public source and public translated binary/IPA are separate decisions;
- no public release is authorized by this PRD alone.

### 12.2 Preferred source topology

Use a separate `bananapad` integration repository containing only:

- original BananaPad Apple/runtime integration code;
- rights-compatible copied/adapted code with retained notices and provenance;
- deterministic scripts;
- patch files against exact public revisions;
- tests and documentation;
- original BananaPad artwork;
- license and third-party notices.

It may clone/fetch the pinned DK64Recompiled, PaperPad, SunPad, runtime, and renderer sources into ignored `ref/` directories. Do not publish the user ROM, decompressed ROM, generated game/patch/RSP source, saves, or private evidence.

Because BananaPad derives from/reuses GPL-3.0 code, the public integration source will normally need a GPL-3.0-compatible license and corresponding-source compliance. Confirm the exact combined-work implications rather than guessing.

### 12.3 Source and package boundary

Repository and expanded package audits must find no:

- standard or decompressed ROM;
- extracted Nintendo/Rare assets, audio, models, textures, strings, screenshots not explicitly approved, or game-data archives;
- generated N64Recomp game code;
- generated patch code/binary/data or RSP output when those outputs are treated as ROM-derived/private by the release decision;
- saves, private fixtures, crash memory, or private diagnostic logs;
- app-container data or imported ROM filenames/paths;
- signing identities, provisioning profiles, credentials, tokens, team IDs not intended for source, or machine-specific secrets;
- unexpected contents of `ref/`, `generated/`, build caches, or local artifacts;
- forbidden dynamic-code entitlements, writable executable segments, runtime compilers, or user executable mod loaders;
- unapproved upstream launcher/game artwork or copied app icons.

A ROM-free app may still include statically translated game logic. **ROM-free is not automatically binary-distribution clearance.** GPL compliance and game-rights clearance are separate gates.

### 12.4 App-icon provenance

`PROVENANCE.md` must identify the original source/process, master hash, edits, author/tool, date, and rights statement. The release review must compare the packaged icon to that approved master and confirm no Nintendo/Rare/Donkey Kong character, logo, controller design, screenshot, or upstream launcher art was copied.

### 12.5 Third-party notices and corresponding source

For the exact candidate:

- enumerate DK64Recompiled, N64ModernRuntime, N64Recomp/RSPRecomp, RT64, SDL2, RmlUi/RecompFrontend code retained (if any), miniz/zlib, xxHash, fonts, Apple shell/reference code, and every transitive shipped library;
- include required license texts/notices in source and package;
- document source offer/corresponding-source route where GPL requires it;
- identify modifications and exact revisions;
- remove unused desktop libraries/assets rather than carrying their obligations blindly.

### 12.6 Approved description wording

Use this substance only once publication is authorized:

> BananaPad is an unofficial native Apple port built from the open-source Donkey Kong 64: Recompiled project and an ahead-of-time static recompilation of a user-supplied Donkey Kong 64 (US/NTSC-U 1.0) Nintendo 64 ROM. It uses N64Recomp, N64ModernRuntime, and RT64 for the recompilation, runtime, and rendering stack. Users must supply their own legally obtained supported ROM. BananaPad is not affiliated with, endorsed by, or sponsored by Nintendo, Rare, Microsoft, or their partners.

Do not describe BananaPad as official. Do not say “emulator-free” as a legal or quality claim. Do not imply that ROM ownership, GPL source, static recompilation, or a ROM-free package automatically grants redistribution permission.

### 12.7 Public-candidate gate

A public candidate requires all of the following in `RELEASE-READINESS.md`:

- D1–D11 and matrix rows 1–33 green;
- exact source revision, dependency-lock hash, generated-input identities, and candidate hashes;
- an upstream check performed during candidate preparation: the newest stable release is either promoted or explicitly deferred in `UPSTREAM-SYNC.md` with categorized differences, known bugs left outstanding, and rationale;
- Chris's physical iPad/iPhone acceptance of that exact artifact;
- repository, entitlement, Mach-O, dynamic-code, privacy, app-icon, and package audits green;
- required GPL/corresponding-source and third-party notices complete;
- explicit source-release decision;
- explicit binary/unsigned-IPA release decision;
- no unresolved severity-1 progression, static-code, save, crash, audio, privacy, package, or rights issue;
- Chris's explicit final authorization.

## 13. Risk register

| Risk | Standing | Response |
|---|---|---|
| Upstream desktop build permits JIT/unsigned executable memory and disables executable/library protections | Confirmed in audited macOS entitlements/build; primary mobile blocker | Inventory exact consumer; compile required patches statically; enable no-dynamic-code runtime; remove writable-text linker route; entitlement/Mach-O/runtime audits |
| Static patch system may depend on runtime code patching/mod APIs | Confirmed architecture, exact required behavior unproven | Patch manifest; classify correctness/enhancement/mod; static libraries or writable data dispatch; per-patch gameplay regression; no silent removal |
| Public upstream CI uses private `extra` checkout | Confirmed workflow convenience; public clean-clone completeness unproven | Identify every file; replace with user-ROM-derived/public pinned generation; D11 requires no opaque private input |
| Runtime/build decompression boundary is non-obvious and public runtime function contains placeholder/TODO | Confirmed source condition | Trace standard ROM, decompressed build ROM, generated sections, runtime reads; deterministic hashes and source map; no filename-based assumptions |
| Multiple compressed code classes share destination RAM | Confirmed; stale mapping risk | Generated manifest; explicit active class; load/use/return logs; sequential class tests including arcade/Jetpac; no arbitrary range widening |
| Arcade and Jetpac are required progression gates | Confirmed game path and explicit upstream code classes | Dedicated matrix rows to obtain both coins and return/save; do not accept title-only evidence |
| Upstream multiplayer is WIP/non-functional | Confirmed upstream setting | Keep disabled/hidden; safe absence path; separate PRD for repair |
| DK64 `Eep16k` differs from likely original save profile and may carry extra data | Confirmed upstream choice; actual host format/compatibility unproven | Preserve first; document actual bytes/format; repeated/termination/recovery tests; explicit desktop migration |
| DK64 fork and PaperPad runtime/RT64 pins may diverge | Confirmed different source graphs | Start from working DK64 pin; compare patch sets; choose one documented integration strategy; one revision change at a time; full affected matrix |
| RecompFrontend/RmlUi settings are intertwined with game hooks | Confirmed desktop architecture | Build BananaPad-owned settings bridge matching exact values/defaults; native menu tests; temporarily hide unsupported setting rather than no-op |
| Touch requires many simultaneous Z-modified actions | Core DK64 input characteristic | SunPad independent-finger architecture + PaperPad N64 snapshot; explicit chord matrix; iPhone/iPad hands-on; aggressive held-state clearing |
| Analog camera can conflict with C-Up/right-stick mappings | Confirmed upstream warning/behavior | Mode-aware input bridge; right analog suppression state tests; preserve all C buttons; diagnostics and reset defaults |
| Audio route/static issues on Apple | Upstream macOS issue plus mobile session risk | RSP/audio queue instrumentation; PaperPad Apple audio mechanisms; AVAudioSession route/interruption tests; macOS HDMI/Bluetooth retest; no buffer guessing |
| High frame rate/widescreen may expose timing/UI/cutscene defects | Upstream feature, Apple/mobile matrix unproven | Stable original baseline; per-mode identity; scene matrix; default-off/hide failing modes; no blanket support claim |
| RT64 Metal memory/lifetime on iPhone/iPad | PaperPad path proven for another N64 game; DK64 load unproven | Port exact resource/lifetime fixes; physical memory/thermal profile; repeated background/orientation/scale changes; 90-minute soak |
| Full-game regression cost is high | Inherent | One fresh route to credits plus ignored staged fixtures and scripted smokes; fixtures never replace fresh proof; exact special-class matrix |
| App icon or UI assets accidentally reuse protected game art | Avoidable release risk | Original generic BananaPad art; provenance/master hash; no upstream launcher art; package audit and visual review |
| GPL/dependency compliance is mistaken for game-binary clearance | Material legal/release risk | Separate source and binary decisions; license inventory/corresponding source; explicit rights gate; no auto-publish |
| Toolchain/upstream drift after a brand-new release | High; repository active | Keep `1.0.1` as archived initial anchor, not permanent freeze; track promoted/observed/candidate pins; scripted isolated staging; external patch series; categorized diff; regeneration; affected tests; full candidate matrix; explicit promotion/deferment and one-step rollback |
| Simulator/device gap | Certain | Physical iPad/iPhone exact-artifact tests for touch, audio, heat, memory, refresh, controller, sleep, and sustained play; no inferred device claims |
| “Very quick build” causes skipped hardening | Planning risk | Preserve fast integration bias but enforce G2–G5 and no-dynamic-code evidence before mobile promotion; do not trade architecture for a title-screen shortcut |
