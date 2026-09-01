# G2 validation — 2026-08-31

Goal: initial upstream baseline and synchronization lane reproduced.

## Result

**Incomplete.** The pinned upstream app builds, is deeply signature-valid, launches, and recognizes the exact supported ROM. The isolated stage/test/promotion-rehearsal/rollback lane passes. G2 is not accepted because gameplay and save/reload have not yet been observed.

## Build and packaging evidence

| Item | Evidence |
|---|---|
| Source | tag `1.0.1`, commit `c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43` |
| Generated inputs | G1 content-addressed game, patch, and RSP sets |
| App bundle SHA-256 | `7bebbc99e7d9ad97b776e9de8d86f30709ab93f230e2f5c95d2ee00408e2c983` |
| Executable SHA-256 | `d62a33da97d175e5bcac5b7f5bd15fc88063c3518465656087b099671260c99a` |
| Architecture | native thin arm64; deployment target 14.0; SDK 26.5 |
| Deep signature | `codesign --verify --deep --strict` passed |
| Build wrapper SHA-256 | `31ec6325339878d928ebe2b30f496638ce0ecf945d1eda7c7eb4f0677e7a3291` |

The first compile stopped at RT64's pinned `hlsl++` because Xcode 26 no longer indirectly declares `labs`. The recorded one-line `<stdlib.h>` patch (`c8d709ff3abf745cda14fa1150b35bff76aeec9815190348f5e7fd751199f86d`) fixed that exact error in the disposable worktree. The first launch then stopped because Homebrew `sdl2-compat` dynamically loads SDL3, which BundleUtilities cannot infer from Mach-O dependencies. Explicitly packaging/signing `libSDL3.0.dylib` plus its expected `libSDL3.dylib` name fixed launch.

Link warnings that Homebrew libraries were built for macOS 26 while the comparison target declared macOS 14 remain recorded. They make this host-built bundle unsuitable as deployment evidence for older macOS versions.

## Dynamic-code boundary

The comparison app intentionally fails `scripts/check-no-dynamic-code.sh`. Its signature contains:

- `com.apple.security.cs.allow-jit`;
- `com.apple.security.cs.allow-unsigned-executable-memory`;
- `com.apple.security.cs.disable-executable-page-protection`; and
- `com.apple.security.cs.disable-library-validation`.

Its `__TEXT` segment also has maximum protection `rwx`. This is the exact upstream behavior BananaPad must replace; it is not a regression or an accepted product architecture.

## Launch and ROM acceptance

The unseeded app reached the launcher and displayed `Load ROM`. An exact 33,554,432-byte, mode-`0600` normalized copy was then placed at the app's own storage contract, `Application Support/DK64Recompiled/DK64.z64`; it retained SHA-1 `cf806ff2603640a748fca5026ded28802f1f4a50` and SHA-256 `b6347d9f1f75d38a88d829b4f80b1acf0d93344170a5fbe9546c484dae416ce3`. After a clean restart the launcher displayed `Start Game`, proving the runtime accepted the exact identity.

Private screenshots are ignored at `generated/evidence/g2/launcher-load-rom.png` (SHA-256 `e5e56d63d7d164e1876d555c90f5871843d2a052da681eaea2183500957a8202`) and `launcher-start-game.png` (SHA-256 `93a137395ced1208d1c6024bca665555a234d5d6f88a3648407e1c90dc30abd7`). This proves launch and stored-ROM recognition, not the native picker interaction.

The Metal canvas does not complete the computer-control accessibility-state handshake. No blind click was used and no gameplay claim is inferred. All launched game processes were terminated after evidence capture; no Simulator was booted.

## Archived comparison contract

`docs/UPSTREAM-BASELINE.md` now separates source-derived and observed evidence for the launcher, ROM path, SDL keyboard/controller defaults, Metal renderer boundary, 48 kHz audio path, `Eep16k` save format, asynchronous backup-aware persistence, desktop security exceptions, and observed build/runtime defects. `scripts/audit-upstream-baseline.sh` binds those assumptions to the promoted source and rebuilt artifact and passed with:

- source `1.0.1` / `c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43`;
- app SHA-256 `7bebbc99e7d9ad97b776e9de8d86f30709ab93f230e2f5c95d2ee00408e2c983`;
- native arm64, bundle ID `com.github.dk64recompiled`, valid deep signature;
- the expected desktop RWX/dynamic-code profile;
- exact stored ROM verified; and
- expected save path absent.

Absence of the save remains a failed G2 exit condition, not a successful empty-save test.

## Synchronization rehearsal

The following passed end to end against the same pin:

```sh
scripts/stage-upstream-update.sh c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43 g2-same-pin
scripts/test-upstream-update.sh
scripts/promote-upstream-update.sh --rehearsal
scripts/rollback-upstream-update.sh --candidate
```

The candidate recursive manifest matched `bebfa8f085ae40eafed4ca3d79fbbd7bf5566114a550b11878fba181c7ffc088`; the external patch series matched `27fe62fb92bf639e0427766c2aed8361ce6a550911887d15ae3ad38d663c581c`; promotion did not alter the lock; rollback moved all candidate state into a recoverable ignored archive and removed the active candidate.

The full cycle was repeated after strengthening the lane to bind recursive tracked and untracked worktree state across every nested submodule. The staged state digest was `d68627960485cd09a1401bfe15a4ed7a608e690d66c8d1d5409377c4274db479`; testing and promotion both recomputed it successfully, and the candidate was recoverably archived under ignored `generated/upstream/rollbacks/20260831T064155Z`. The dependency lock remained SHA-256 `407856c6684461ec64373c4cec6f8416a2ccb8aed2d0a63337433af8bf20f938` through this strengthened rehearsal.

## Remaining exit evidence

G2 remains open until one exact upstream process is observably driven through `Start Game`, meaningful gameplay is exercised, a save is produced, the process is terminated cleanly, and a fresh launch visibly reloads compatible progress.

`scripts/validate-upstream-play-session.sh` (SHA-256 `076cbf12c7e831e4030bf4b44cac5ca2fec01e1a5d1630ddaf6484bba11d4d33`) provides a bounded private state machine for this remaining route. It preflights the exact source/artifact/ROM, records the pre-save state, rejects a missing, unchanged, all-zero, or non-2048-byte result, stores a mode-`0600` private backup, relaunches the exact app, and requires a PNG plus written observation of restored progress. Help, syntax, inactive status, privacy setup, artifact audit, process absence, and Simulator absence are verified. The success path has intentionally not been claimed or simulated.

After repeated app-path, bundle-ID, and foreground state timeouts across three consecutive goal turns, G2 is blocked pending either a real hands-on session per `docs/G2-HANDS-ON.md` or explicit authorization to use alternate macOS input synthesis. Source inspection, a synthetic save, or a blind click cannot substitute for the required evidence.
