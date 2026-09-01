# BananaPad goal-based loop

Operating loop for the autonomous build of BananaPad. The requirements live in `docs/PRD.md`; this document is how you run. Written 31 Aug 2026.

## The goal stack

Work the next unmet goal in the execution order below. A goal is met only when its evidence exists in `docs/` per PRD Section 11. DK64Recompiled is the accepted game implementation; BananaPad does not re-qualify the upstream game by playing it to completion. After the shared native feasibility gate (G5), all active engineering effort goes to the Simulator-safe G10 touch/menu shell, iPad and iPhone acceptance (G8/G9), mobile lifecycle/data/controller behavior, packaging, and updateability. Reopen game-route investigation only for a named regression introduced by BananaPad or by a newly staged upstream pin.

**Current checkpoint and active goal (2026-09-01):** DK64Recompiled is accepted and its boot/play/save proof is complete. Stop launching or playing DK64 merely to reconfirm that baseline. The locally executable G10/G7/G11 work is green: PaperPad's touch UI and persistent three-dot menu remain byte-identical, DK64 touch/controller/native-UI contracts pass, iPhone/iPad Simulator and universal `iphoneos` builds audit cleanly, the ROM-free private IPA is reproducible, README/handoff documentation is current, and the guided patch-driven upstream-update lane has built and safely rejected an actual newer `main` without disturbing the promoted product. Rollback archives the candidate checkout, metadata, generated inputs, and both Apple build trees; a clean same-pin restore and the full non-game product gate pass. Existing sequential Simulator evidence covers both form factors, saves, lifecycle, orientations, controls, and the menu. The active remaining product gate is G12: sign and run this exact candidate on physical iPad and iPhone for multi-finger chords, real-controller handoff, audible route/interruption behavior, sustained thermal/memory behavior, and physical icon presentation. These results must not be invented from Simulator evidence. Never boot more than one Simulator, and leave none booted after each test.

- **G0. Environment, references, and safety ready.** The local repository is named `bananapad`; the current git state is recorded; `ref/dk64-recompiled`, `ref/paperpad`, and `ref/sunpad` are pinned, read, treated as read-only, and have push disabled; the Xcode/CMake/Ninja/recompiler toolchain is verified; `RIGHTS-STATUS.md` states `private-only` or a stronger explicitly approved state; ROM/AOT/save/log/package safety checks exist.
- **G1. Exact ROM and deterministic generated inputs.** The original Donkey Kong 64 ROM is preserved; an ignored normalized big-endian working copy matches SHA-1 `cf806ff2603640a748fca5026ded28802f1f4a50`; the upstream decompressor deterministically creates `donkeykong64.decompressed.us.z64`; N64Recomp, RSPRecomp, symbol inputs, generated game functions, generated static patches, and `rsp/n_aspMain.cpp` are all reproduced from pinned inputs with hashes recorded.
- **G2. Initial upstream baseline and synchronization lane reproduced.** Donkey Kong 64: Recompiled `1.0.1` builds on Apple Silicon macOS, imports the standard ROM, reaches gameplay, writes and reloads a save, and remains archived as the initial comparison anchor. BananaPad also has a scripted upstream-update lane that records the promoted pin, discovers newer stable tags or selected fix commits, stages them in isolation, reapplies the BananaPad patch stack, regenerates game/patch/RSP output, runs the affected tests, and can promote or roll back without mutating the last known-good state.
- **G3. Mobile-safe execution model proven.** `AOT-AND-PATCHES.md`, `OVERLAYS.md`, `RSP.md`, and `SAVE-AND-ACCESSORIES.md` describe the actual execution model. The game and required patch functions are ahead-of-time native code; runtime patching uses writable data/function tables only; LiveRecomp/JIT/TCC/user-code loading and writable-executable pages are absent from the mobile profile; all required compressed-code overlays and the `n_aspMain` RSP path are accounted for; the upstream `Eep16k` save behavior is preserved intentionally.
- **G4. Hardened BananaPad macOS core boots.** The BananaPad-owned macOS app builds and reaches the title through Metal using the same static core intended for iOS/iPadOS. It does not require the upstream JIT/unsigned-executable-memory/disabled-library-validation entitlements, the writable-text linker workaround, or the desktop RmlUi launcher. Video, audio, input, overlays, static patches, and clean exit are evidenced.
- **G5. macOS interactive feasibility.** Import/verify ROM → title/intro → select an Adventure file → exercise bounded gameplay input, save write/reload, audio, and clean exit through the same hardened static core intended for mobile. This gate is complete and proves the shared core boots and plays; it does not create a continuing obligation to replay upstream game progression. (PRD D4)
- **G6. Upstream game baseline accepted.** DK64Recompiled is treated as the working game source of truth. BananaPad preserves its generated game/patch/RSP inputs, overlay map, save contract, and input semantics. A bounded boot/play/save/reload smoke proves the Apple integration; a full fresh-save playthrough is not a BananaPad gate. (PRD D5–D6)
- **G7. Mobile integration stability.** Original-mode rendering/audio/input/save behavior is stable on the Apple shell; exposed enhancements are retained only when their settings apply honestly. Lifecycle, native UI suppression, controller ownership, ROM/save safety, repeated app transitions, memory behavior, and sustained mobile operation are green. (PRD D7, D10)
- **G8. iPad Simulator core accepted.** With every other Simulator shut down, the iPad Simulator builds and completes the interactive platform loop—verified ROM → title → file creation → gameplay input → save write → terminate/relaunch → visible reload—with the same AOT core, static patches, overlay model, Metal renderer, save format, and no-dynamic-code profile. Simulator performance is diagnostic only.
- **G9. iPhone Simulator core accepted.** After shutting down the iPad Simulator, the iPhone Simulator completes the same interactive platform loop with the same core. Compact safe areas, both landscape orientations, touch reachability, native UI behavior, and lifecycle resume are evidenced.
- **G10. PaperPad Apple shell complete.** PaperPad's pinned touch UI and persistent three-dot menu remain byte-identical while its N64/RT64 ROM, input, Metal, AOT-only, package-safety, and shutdown mechanisms connect to DK64. SunPad may supply complementary loading, diagnostics, controller, provenance, and evidence ideas without altering that UI contract. DK64-specific multi-touch chords, camera controls, ROM management, saves, controller handoff, audio interruptions/routes, loading states, and an original BananaPad app icon work on both form factors. (PRD D8–D9)
- **G11. Technical matrix, clean-clone pipeline, and upstream-update rehearsal green.** PRD matrix rows 1–33 pass against the exact candidate; host regressions, scripted smoke routes, no-dynamic-code audits, repository/package audits, clean-clone reproduction, and an isolated upstream candidate stage/rebase/regenerate/test/rollback rehearsal are green. No undocumented manual build or upstream-sync step remains.
- **G12. Physical candidate accepted.** Chris tests the exact signed or locally re-signed candidate on a physical iPad and iPhone. First-play, later-game fixture, touch chords, controller handoff, save/reload, audio routes, background/foreground, sustained play, thermal/memory behavior, icon presentation, and artifact hashes are recorded. Simulator evidence cannot satisfy this goal.
- **G13. Public release authorized.** GPL and dependency obligations, PaperPad/SunPad reuse rights, game-source and binary boundaries, app-icon provenance, third-party notices, source/package audits, and separate source-release and binary/IPA decisions are recorded. Only then may a public repository, tag, source archive, binary, or unsigned IPA be published.

G2 is the initial upstream comparison and synchronization gate. G4 and G5 are the hard mobile-architecture and playability gates. After G5, execute the usable G10 touch/menu slice → G8 → G9 → remaining G10/G7 mobile integration work → G11. Do not spend BananaPad sessions replaying upstream DK64 progression unless a named Apple-specific regression requires it. G12 and G13 are mandatory for a public binary. There is no fallback to a title-screen demo, controller-only mobile build, dynamic-code sideload build, untested enhancement build, or “ROM-free therefore cleared” release.

`RIGHTS-STATUS.md = private-only` does not block G1–G11. It blocks publication and G13.

## The loop

Repeat until the current authorized terminal goal is met:

1. **Pick** the next unmet goal in the declared execution order. Choose the smallest concrete step that could advance it.
2. **Check state before acting.** Read `docs/STATUS.md`, the last `JOURNAL.md` entry, the relevant technical inventory, `git status`, running processes, booted Simulators, input hashes, source pins, active save, and build caches. Do not rebuild or regenerate what a verified cache already holds.
3. **Execute** one bounded step.
4. **Test immediately.** Run the relevant check as soon as the step completes. Compilation is not launch; launch is not title; title is not gameplay; gameplay is not persisted progression; Simulator is not device acceptance.
5. **Capture evidence.** Put the screenshot, log excerpt, profile, hash, entitlement dump, package listing, or capture under the dated local artifacts path. Append one dated journal entry: goal, hypothesis, step, command, result, evidence path, interpretation, and next step.
6. **Update** `docs/STATUS.md` and the affected inventory (`UPSTREAM-SYNC.md`, `AOT-AND-PATCHES.md`, `OVERLAYS.md`, `RSP.md`, `SAVE-AND-ACCESSORIES.md`, `INPUT.md`, `PERF.md`, `KNOWN-ISSUES.md`, or `RIGHTS-STATUS.md`) if state changed.
7. **Continue.** If the step failed, enter the unblocking ladder before retrying.

## Process hygiene — hard rules

- **One Simulator at a time.** Before booting a Simulator, run `xcrun simctl list devices booted`; shut down every booted device, then boot only the intended iPad or iPhone. This is not optional.
- **One game instance at a time.** Before launching on any target, terminate every prior BananaPad, DK64Recompiled, Simulator app, runtime process, host test, or stale helper. Multiple instances corrupt save/config evidence and create false renderer/audio/input bugs.
- **Kill before relaunch, always.** Never layer a new run on a hung, crashed, or half-terminated run.
- **Harden macOS before promotion.** Do not use iOS/iPadOS to discover failures that can be exposed on the shared hardened macOS core. G4 and G5 stay ahead of G8–G10.
- **One variable at a time.** During static-patch conversion, overlay work, RSP/audio work, input work, timing work, and optimization, change one thing, rerun the same evidence-producing test, and journal the result.
- **Clean up after crashes.** Check for booted Simulators, orphan processes, locked save/config files, stale Metal captures, partial logs, and temporary imports before another run.
- **Never touch original inputs.** The original ROM and all `ref/` checkouts are read-only. Work from ignored normalized/generated copies and deterministic patch applications. Hash-check whenever state is uncertain.
- **Never leak game data.** Original or decompressed ROMs, generated game/AOT code, generated patch code/binaries, extracted game assets, saves, crash memory, private logs, screenshots not approved for publication, and app-container contents never enter a commit, issue, upload, or public package.
- **No destructive cleanup.** Never run `git clean -fdx`, blanket `rm -rf` against the project root, destructive resets, or commands that can erase ignored ROMs, references, generated output, saves, or evidence. Inspect paths first.
- **Respect unknown work.** Do not overwrite or reset modifications you did not create. Isolate your changes or write a handoff.
- **Pin before patching.** Verify the exact upstream, PaperPad, SunPad, runtime, RT64, N64Recomp, and RSPRecomp revisions before applying a patch. A patch applying with fuzz is not evidence of correctness.
- **Pins are anchors, not a permanent fork.** `1.0.1` is the initial reproducibility anchor. The promoted upstream pin may advance after the synchronization gate passes; never confuse reproducibility with freezing out upstream bug fixes.
- **Preserve the known-good upstream behavior.** First reproduce `1.0.1`; then maintain a written, machine-readable delta from the currently promoted upstream pin. Do not discard working DK64 logic merely because PaperPad or SunPad uses a different architecture.
- **No silent reference carryover.** Paper Mario-specific N64 fixes and Sunshine/GameCube-specific controls, performance modes, file extraction, and runtime patches are hypotheses until DK64 reproduces the need.
- **No silent stubs.** A stub is permitted only for an optional external device, disabled multiplayer path, or named desktop-only subsystem whose expected result is understood. Never stub progression, overlays, static patches, saves, audio, bosses, arcade, Jetpac, or input merely to advance a screen.
- **Timebox repetition.** The same command failing the same way twice is a blocker. Stop repeating it and enter the unblocking ladder. Never run an unchanged third attempt.
- **No publication by momentum.** A technically green build remains private until G13. Do not create or push the `bananapad` remote, release, tag, package, screenshot set, generated file, or IPA without explicit authorization.

## Upstream synchronization — hard rules

`1.0.1` is the initial reproducibility anchor, not a permanent ceiling. BananaPad must be able to consume later DK64Recompiled stable releases and selected upstream bug-fix commits without rebuilding the Apple shell from scratch or losing the last known-good build.

- **Track three identities.** `dependencies.lock.json` and `docs/UPSTREAM-SYNC.md` record the **promoted** upstream pin used by BananaPad, the **last observed** upstream stable tag/`main` commit, and an optional isolated **candidate** pin under evaluation. Only the promoted pin drives normal builds.
- **Check at meaningful boundaries.** Run `scripts/check-upstream.sh` at G2 completion, at the start of each major goal transition, whenever a blocker may already be fixed upstream, and before any release candidate. Ordinary local debugging does not require merging whatever appeared on `main` that day.
- **Stage, never overwrite.** `scripts/stage-upstream-update.sh <tag-or-sha>` creates an ignored worktree/candidate state, updates only candidate lock metadata, reapplies the exact BananaPad patch series, regenerates game/patch/RSP output, and builds both the upstream macOS comparison and BananaPad hardened core. The promoted checkout, lock, generated hashes, save fixtures, and artifact remain untouched.
- **Keep BananaPad thin.** Upstream game/runtime source stays in pinned references or isolated worktrees. BananaPad-owned Apple shell, platform adapters, static-patch bridge, tests, and deterministic patch files live outside the vendor tree. Do not copy the whole upstream source into `port/` and diverge manually.
- **Categorize every upstream delta.** Classify changes as game logic, correctness patch, enhancement, overlay/decompression, RSP/audio, save/config format, input/settings, runtime/renderer, frontend-only, build/CI, or documentation. This impact map determines the lowest reopened goal and required tests.
- **Bug fixes may move ahead of a full release.** When an exact upstream commit fixes a named BananaPad blocker, stage that commit or minimal reviewed range even before the next stable tag. Record provenance and do not silently absorb unrelated `main` changes.
- **Regenerate from source.** An upstream pin change invalidates generated game, patch, RSP, manifests, and caches unless hashes prove otherwise. Never carry generated output across pins by assumption.
- **Promote only with evidence.** During development, a focused upstream fix may pass the affected macOS routes plus the highest known-good smoke. Before it becomes a technical or public candidate, rerun the complete applicable matrix, no-dynamic-code/Mach-O/package audits, save/config migration, clean-clone reproduction, and physical-device gates as required.
- **Preserve rollback.** Promotion is a single reviewable lock/patch update. Keep the previous promoted lock, patch-set hash, generated identities, artifact hash, known-good command, and compatible save backup so one revert restores the prior state.
- **No unattended auto-merge.** “Easy to update” means scripted, isolated, reviewable, and reversible. It does not mean automatically tracking upstream `main`, accepting new submodule pins blindly, or shipping an untested release.

## AOT, patch, and overlay discipline — hard rules

- **No writable-executable mobile path.** iOS/iPadOS builds must not depend on `com.apple.security.cs.allow-jit`, `com.apple.security.cs.allow-unsigned-executable-memory`, `com.apple.security.cs.disable-executable-page-protection`, disabled library validation, a writable-text linker wrapper, TCC, LiveRecomp, runtime C compilation, downloaded code, or user-supplied executable mods.
- **Writable data is not writable code.** Static function-pointer/dispatch tables may be writable data. Native text pages may not become writable. Prove the distinction with source inspection and entitlement/Mach-O/runtime audits.
- **Compile required patches ahead of time.** Inventory every upstream patch, export, import, event, binary-data section, and replaced function. Classify it as baseline correctness, retained enhancement, desktop-only UI/mod support, or optional experiment. Required behavior must be statically linked or re-expressed as a narrow native hook with a regression.
- **Preserve both ROM boundaries.** The user selects the standard verified ROM at runtime. The build pipeline derives an ignored decompressed ROM for N64Recomp/RSPRecomp generation. Never ask the user to import the decompressed build artifact into the app.
- **Treat every indirect-call failure as an overlay/patch incident until disproven.** Record target address, source function, active overlay, last load, static-patch identity, and current dispatch-table state.
- **Exercise every named compressed-code class.** `global_asm`, `menu`, `minecart`, `bonus`, `race`, `critter`, `boss`, `arcade`, and `jetpac` require observed load/use/return evidence. The upstream `multiplayer` overlay remains disabled for baseline unless separately authorized, but its disabled path must be safe.
- **Do not weaken overlay ranges to suppress an assertion.** Reconcile generated sections and the upstream decompressed-ROM mapping. A load that happens to avoid crashing once is not proof that overlapping or return transitions are correct.
- **RSP is part of the product.** `n_aspMain` generation and registration remain bound to the upstream source, and ordinary gameplay audio plus iOS interruption/route/resume behavior require evidence. No silent HLE or audio-disable fallback.
- **Preserve the upstream save contract.** The runtime declares `Eep16k`; do not infer byte count from the enum name. Record the actual persisted format, compatibility, extra-data use, write boundaries, and desktop-to-BananaPad migration behavior before changing it.

## Touch, controller, and native-UI discipline — hard rules

- **DK64 chords must be physically usable.** Test at minimum Z+A, Z+B, Z+C-Up, Z+C-Down, Z+C-Left, and Z+C-Right with independent fingers. The overlay must not serialize touches or lose the held Z state when a second or third finger arrives.
- **All baseline N64 controls remain reachable.** Left stick, A, B, Z, R, Start, all four C directions, L, and D-pad exist. L/D-pad may be de-emphasized in defaults but remain available in layout editing and controller mapping.
- **Camera modes remain coherent.** The C cluster supports original camera behavior. If upstream Analog Camera is enabled, the right analog touch region and physical right stick must feed that path without stealing C-Up or leaving suppressed state behind.
- **Clear held input at every boundary.** Opening/closing the three-dot menu, file picker, alert, share sheet, controller handoff, interruption, orientation change, backgrounding, ROM replacement/removal, runtime stop, or crash recovery clears all touch/controller state.
- **Controller ownership is stable.** A connected physical controller owns P1, touch gameplay controls hide when configured, disconnect releases all held input, and the returning sole controller reclaims P1 without restarting the controller subsystem.
- **Native UI never drives gameplay.** While a native menu, picker, alert, report flow, or editor is active, game input is suppressed except for an explicitly tested resume action.

## Unblocking ladder

When blocked, escalate through these in order. Journal each rung used.

1. **Read the actual error and full context.** Use the runtime log, unified log, crash report, complete build output, entitlement dump, overlay/static-patch breadcrumbs, RSP/audio counters, save log, and the first causal error—not the final cascade line.
2. **Check the current project state.** Confirm ROM hashes, decompressed-ROM hash, root revision, dependency lock, generated-code identity, applied patches, active save, current overlay, build profile, and whether the failure reproduces from the last known-good command.
3. **Compare with promoted and candidate DK64Recompiled.** Run or inspect the currently promoted upstream pin, preserve `1.0.1` as the archived initial baseline, and check `docs/UPSTREAM-SYNC.md` for a newer stable tag or exact fix commit. Read `BUILDING.md`, `us.toml`, `patches.toml`, `decompressor.cpp`, `register_patches.cpp`, `register_overlays.cpp`, `recomp_api.cpp`, `main.cpp`, config/input code, release notes, and known issues. Determine whether BananaPad introduced the failure or upstream has already fixed it.
4. **Check PaperPad.** Read the exact N64/RT64 Apple build, AOT/no-dynamic-code patch, ROM manager, N64 input bridge, Metal lifetime fix, controller ownership, diagnostics, package audit, and shutdown mechanism. Port only the game-neutral mechanism.
5. **Check SunPad only for a complementary mechanism.** Read its loading, shared controller/diagnostics tests, and app-icon provenance patterns when PaperPad does not already supply the needed mechanism. Never replace or reinterpret PaperPad's protected touch UI or three-dot menu.
6. **Check the toolchain source.** Inspect the pinned N64Recomp/RSPRecomp, N64ModernRuntime patch/mod/overlay/save/audio code, RT64 Metal backend, SDL2 Apple paths, and exact PaperPad patches at the pinned commits.
7. **Research a named question.** Use primary sources first: upstream source/issues/releases, N64Recomp/N64ModernRuntime/RT64 source history, Apple developer documentation, and established recomp projects. Research must answer a specific blocker and return to an experiment.
8. **Reduce the problem.** Examples: upstream desktop baseline; static core without RecompFrontend; required patches without user mods; title before first-play; one overlay; one Z chord; speaker audio before route changes; original 4:3 before widescreen; original cadence before high frame rate; iPad Simulator before iPhone.
9. **Route around narrowly.** Replace one dynamic patch route with a static dispatch entry, one desktop service with a native Apple service, one broken audio route handler, or one specific miscompiled function. Preserve behavior, add a regression, and keep the stable path explicit. Do not replace entire subsystems with no-ops.
10. **Park and pivot.** If a blocker survives a working session, write a complete reproducible defect and take the largest step on the same workstream that does not falsify the lowest goal—for example, extract the shell while a static-patch audit is open. Do not mark the blocked goal met.
11. **Stop and hand off only for a real decision/blocker.** Valid stops: wrong/unusable ROM; unavailable required source/symbols; a required patch cannot be represented without forbidden dynamic code and no bounded static route exists; continuing would destroy or leak protected inputs; physical-device action is required; or publication/licensing approval is required. Ordinary compile, renderer, audio, touch, save, overlay, and lifecycle defects have an unblocking path.

## Testing rhythm

- **Per change:** run the smallest build/boot/gameplay/regression check relevant to what changed.
- **Per upstream candidate:** generate the categorized diff, reapply the patch series without fuzz, regenerate all derived outputs, run the affected macOS routes and highest known-good smoke, verify save/config compatibility, and record promotion or rejection in `UPSTREAM-SYNC.md`.
- **Per static-patch change:** prove the intended function is selected, the original behavior is preserved or intentionally changed, no executable page becomes writable, and the matching gameplay route still works.
- **Per overlay change:** exercise load, use, replacement/unload, and return; inspect mapping logs for stale or duplicate functions.
- **Per RSP/audio change:** run music, ambience, Kong voice, UI sound, weapon, instrument, transition, arcade/Jetpac, and route-change checks; inspect queue depth, underruns, pitch, and discontinuities.
- **Per save change:** use a disposable local save; hash/backup before and after; relaunch and verify game-visible state; test compatibility separately. Never commit a fixture.
- **Per input change:** test single touch, two- and three-finger chords, slide-in/out, cancellation, menu suppression, controller takeover, disconnect, and held-state clearing.
- **Per lifecycle change:** background/foreground, interruption, orientation flip, memory warning, renderer return, clean stop, and relaunch on the same process where applicable.
- **Per goal claim:** complete the exact evidence required by PRD Section 11 before changing `STATUS.md` to met.
- **Per session:** run the regressions affected by that session's change. Do not launch DK64 when build, source-fidelity, touch/menu, ROM-management, package, or update-lane contracts completely cover the change; require a game smoke only for a named runtime compatibility risk. End the journal with the exact known-good command, revision, artifact identity, and next lowest goal.
- **Per candidate:** rerun the full applicable matrix against the exact artifact. Do not combine evidence from older builds.
- **Honesty rule:** configured or source-inspected Apple-shell behavior is not acceptance. If a BananaPad-owned touch, menu, controller, ROM/save, lifecycle, audio-route, or packaging path was not run and observed on the applicable target, it is not done.

## Using the three reference projects correctly

- **DK64Recompiled is the game source of truth.** Start at tag `1.0.1` / commit `c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43` as the archived initial anchor; preserve its game logic, patches, overlay mapping, RSP path, save contract, controls, enhancements, and known-good macOS behavior. The normal BananaPad build follows the currently promoted upstream pin, which may advance to later stable tags or selected fix commits through the synchronization gate.
- **PaperPad is the authoritative N64-on-Apple UI and substrate reference.** Pin `ref/paperpad` to `74b6e45830a06c7f274c5ac1ddd7c625bc13a557`. Preserve its applicable touch UI and persistent three-dot menu verbatim. Reuse its AOT-only build shape, `N64MODERN_NO_DYNAMIC_CODE` route, RT64/Metal fixes, ROM manager, N64 input bridge, controller ownership, lifecycle, diagnostics, dependency locks, clean-clone scripts, and package audits where applicable.
- **SunPad is secondary.** Pin `ref/sunpad` to `e43f0ea6b797e5110787171957c9dc3c6213269c`. Use only complementary loading-state, controller-test, diagnostics/reporting, app-icon provenance, and acceptance ideas that do not change PaperPad's touch/menu source. Do not copy GameCube runtime or Sunshine assumptions.
- **Dependency control:** create a BananaPad-owned `dependencies.lock.json`; separately record promoted, last-observed, and candidate DK64 upstream identities; verify recursive revisions; refuse dirty reference trees; disable push URLs; hash the patch series; record every deliberate pin change, test result, promotion, deferment, and rollback.
- **Scripts:** provide a guided `manage-upstream.sh` entry point over deterministic `check`, stage, regenerate, build, test, qualify, promote, and rollback operations, plus deterministic equivalents of `check-prerequisites.sh`, `clone-sources.sh`, `verify-sources.sh`, `prepare-rom.sh`, `build-host-tools.sh`, `generate-game.sh`, `generate-patches.sh`, `build-upstream-macos-baseline.sh`, `build-macos-app.sh`, `build-ios-simulator.sh`, `build-ios-device.sh`, `run-smoke.sh`, `capture-crashes.sh`, `check-no-dynamic-code.sh`, `check-repo-safety.sh`, `audit-ios-package.sh`, and `package-unsigned-ipa.sh`.
- **Logging:** wire boot, ROM identity, generated-code identity, patch profile, overlay, RSP, save, controller, touch, lifecycle, renderer, audio-route, memory, and exit breadcrumbs before the first unstable mobile run.
- **Experiments:** every high-framerate, widescreen, draw-distance, analog-camera, gyro, performance, or renderer experiment is separately identified, default-safe, reversible, and cannot silently replace the proven baseline.
- **Release safety:** repository, entitlement, Mach-O, and package audits remain executable throughout development; passing once at the end is insufficient.

## Session start checklist

1. Read `docs/STATUS.md`, the last `JOURNAL.md` entry, and the inventory for the lowest goal.
2. Run `git status`; preserve unknown work. Record the BananaPad root revision.
3. Run `xcrun simctl list devices booted`; shut down strays. Kill stray BananaPad/DK64/runtime/test processes.
4. Verify the original ROM hash when relevant and confirm generated/decompressed working inputs have not changed unexpectedly.
5. Verify `ref/dk64-recompiled`, `ref/paperpad`, `ref/sunpad`, and all nested toolchain revisions against `dependencies.lock.json`; confirm patches target exact commits.
6. Read `docs/UPSTREAM-SYNC.md`. At a major goal transition, before a candidate, or when a blocker may be fixed upstream, run `scripts/check-upstream.sh` and decide whether to stage an update; never mutate the promoted pin during an unrelated session.
7. Confirm the active save/test fixture and back it up if the session can write it.
8. State the session goal and smallest next step in `JOURNAL.md`.
9. Enter the loop.

## Session end checklist

1. Terminate the game and shut down every Simulator.
2. Run the affected regression suite. Run the highest known-good game smoke only when the change creates a named runtime compatibility risk; otherwise record the non-game mobile-shell evidence that closes the change.
3. Record build/artifact identity, evidence paths, active save state, entitlement/no-dynamic-code result, promoted/observed/candidate upstream identities, open processes (none expected), and remaining defect.
4. Update `STATUS.md` and any changed technical inventory.
5. Run repository safety checks before any commit.
6. Leave one unambiguous next step for the lowest unmet goal.
