# BananaPad release readiness

Last updated: 2026-09-02 20:15 JST

Decision: **GO for public BananaPad Preview 1**. The user explicitly authorized public source publication and upload of the exact audited ROM-free unsigned IPA. The root GPL text, adapted-file provenance inventory, BananaPad-specific notices, deterministic packager, and expanded package audit are part of the release. Broader hands-on device acceptance remains a separate product-quality gate and is stated as preview work.

## Exact current identity

- Promoted DK64Recompiled source: tag `1.0.1`, commit `c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43`.
- Dependency lock SHA-256: `89e300c9723973fbf71eae0f1796db7e88a442256a95085103705b8ab2929576`.
- Current external BananaPad patch-series SHA-256: `a9c05e4fa8d4f06816c1ea0a3144bbfd185890bd8453a73eeadb412a2b24f5c3`; the promoted upstream pin remains `1.0.1` while stable `1.0.2` is isolated for qualification.
- BananaPad product-source SHA-256: `4d223ee7f4bd8ed536b2238616c2ac1a23ae3584f66a5869197b0afc349a0d8a`.
- The last isolated `1.0.2` build/audit Simulator executable was `12e963eac4685900621554d245af735f7eb691e088d487a388e985d64311c560`; that candidate was archived after the later Xbox input repair changed the product identity and must be restaged before qualification.
- Branding-accepted Simulator executable SHA-256: `96b80b1a61b796634de558c7eca5ae0a5d1be706506206d07a8a606f0b353b22`; its three-dot action sheet, accessibility label, and native Settings sheet use BananaPad naming.
- Signed physical-iPad executable SHA-256: `0cf47f413d544a59d6fd7b96b4838a4325b03044bd40f217226b47711f1b5abd`; arm64, iOS 15 minimum, and both iPhone/iPad families. Package/no-dynamic-code/signature audits, exact generated SDL patching, in-place install, preserved ROM/save/preferences, launch, and visible DK64 rendering pass on the attached iPad. The SDL-level Xbox A duplicate-Start repair awaits the user's direct jump/pause retest.
- Exact unsigned release executable SHA-256: `ee876b51aec617563963ee898c6ec36f87a3dffbfc10c2dc2636182c8a7a0442`; clean arm64 iPhoneOS build, iOS 15 minimum, iPhone/iPad families, no personal build paths, no forbidden dynamic-code behavior, and no signature/profile.
- Exact public IPA: `BananaPad-v0.1.0-preview.1-unsigned.ipa`, 7,479,430 bytes, SHA-256 `a7f3a7a280770644bb175553c2d70c5af032959fd1e425d89b164f721b53d55e`. Two independent deterministic package runs are byte-identical; ZIP integrity, complete licenses/notices/install/rights content, ROM/save/private/signing exclusion, Mach-O, privacy, dependency, and no-dynamic-code audits pass. The anonymously downloaded hosted IPA and checksum match the audited local files byte-for-byte, and the hosted IPA independently passes the checksum, ZIP, package, and no-dynamic-code audits.
- Release identity: remote `main` and dereferenced tag `v0.1.0-preview.1` both resolved to release commit `4eeaed3299328fa1a5dd1cb216b1ed20bc749055` at publication time.
- Last full touch/play/save/reload candidate executable SHA-256: `f4fab84e2b0b99c8cba45ccfd576f256810eebd660f25fbf00805564b910f182`; the current delta is confined to ROM-management safety and native-modal controller suppression, not game code.
- Archived `1.0.2` rehearsal worktree SHA-256: `08a83782323421d4b9f684faa8518011881b1956e95526b93ca942ada142085d`.
- BananaPad-branded PaperPad-derived `ios_main.mm` SHA-256: `75759c9137c416d19df7612b8abe4beb892553d6ee7fe752776c0d7aa526fb39`; the fidelity gate allows only the reviewed product-label substitutions.
- Rights state: public source, tag, prerelease, exact IPA, and checksum publication are explicitly authorized. Private game/user/signing inputs remain prohibited.

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
| 8 | BananaPad boot to title | Met | macOS, iPad Simulator, and iPhone Simulator boot via Metal with audio/input/static code; only one Simulator ran at a time. The signed universal iPhoneOS target also installed in place, launched, remained alive, and visibly rendered DK64 on the attached iPad. |
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
| 25 | EEPROM save/compatibility | Partial | Independent iPad/iPhone 2,048-byte creation and visible reload pass. A CRC-checked importer remapped a private 101% donor into Game 2, proved every byte outside that logical slot unchanged, loaded it in a disposable iPad Simulator, and passed exact hardware readback while preserving the original backup. Erase, interrupted write recovery, and cross-version/desktop round trips remain. |
| 26 | Audio continuity/routes | Partial | Metal/CoreAudio startup and ordinary audio work. Pinned SDL2 observes AVAudioSession interruptions, pauses/restarts its AudioQueue, and retries on foreground when iOS omits interruption-end. Simulator/physical audible interruption and route-change evidence remain. |
| 27 | Baseline timing/rendering | Partial | Native original-mode rendering/gameplay is stable for current smokes and interaction. Scene measurements, long-run memory, and physical baselines remain. |
| 28 | Enhanced modes | Partial | Resolution/aspect/settings contracts and 3x/4x native route are verified. Per-mode gameplay, persistence, timing, and physical qualification remain. |
| 29 | Touch overlay/chords | Partial | Every control mask, independent ownership, merging, cancellation, clamping, and lifecycle release pass compiled contracts; stick/A/B and iPad Z/R/C/swimming are game-visible. Physical independent-finger Z chords remain hands-on. |
| 30 | Three-dot/settings/controller | Partial | Byte-identical menu/settings UI, persistence contracts, controller notification bridge, touch auto-hide, and native-modal controller suppression pass. Real controller takeover/disconnect/reconnect remains physical acceptance. |
| 31 | Lifecycle/orientation/memory/diagnostics/icon | Partial | The exact current iPad executable completed three background/foreground cycles, retained the open three-dot menu and native Settings, restored the overlay after dismissal, resumed rendering, and rendered in both landscapes. Input clear/neutral rearm, both phone landscapes, diagnostics UI, clean stop, original icon master/provenance/package asset, and privacy/package audits pass. SDL2 forwards all UIKit lifecycle and memory-warning events. Observed memory warning, audible audio interruption/routes, and physical icon/appearance presentation remain. |
| 32 | Repeated lifecycle/native-UI transitions and soak | Partial | Three exact-candidate iPad Home→foreground cycles pass, including open-menu and open-Settings transitions plus renderer recovery. Three clean terminate/relaunch cycles then survived initialization with no new crash report. Longer sustained operation, memory pressure, and physical sustained-play evidence remain. |
| 33 | Regression/clean clone/audits/update rehearsal | Met | Product contracts, same-pin candidate replay, exact smokes, audits, promotion/rollback/re-promotion, and isolated clean Git snapshot `2ad0ffb4c8595b359f1681b142832c9f9c50c434` pass. The snapshot independently downloaded all public pins, normalized the external private ROM, reproduced generated manifests, and built/audited hardened macOS and Simulator apps. The current source additionally builds/audits as an unsigned arm64 iPhoneOS app without packaging a ROM. The physical-device preflight contract also proves that a signed/connected run will create an artifact-, source-, and device-bound pending receipt and complete G12 worksheet without auto-claiming acceptance. |
| 34 | Exact public candidate | Met | Root GPL text, copied/adapted-file provenance, notices, deterministic packaging, expanded auditing, public-source decision, exact IPA decision, official release identity, anonymous hosted download, byte comparison, checksum, and hosted re-audit are complete. Broader physical iPad/iPhone acceptance remains separate preview work. |

## Green qualification commands

Run the current exact-candidate checks without booting a Simulator:

```sh
scripts/validate-product-candidate.sh
```

The command validates the current clean build, PaperPad fidelity, touch/settings/native-input contracts, renderer ordering, release-readiness identity, repository safety, upstream replay, no-dynamic-code, package state, and whitespace. Historical runtime receipts remain bound to the exact executables that produced them and are not relabeled as the current build; this command does not launch DK64 or manufacture physical-device evidence.

## Remaining release blockers

Preview 1 has no remaining publication blocker. Continue the Apple-shell matrix independently: controller reconnect, audio interruption/routes, memory pressure, and sustained iPad/iPhone operation. Preview status must not imply those unobserved checks passed.
