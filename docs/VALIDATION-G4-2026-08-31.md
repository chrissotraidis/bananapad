# G4 validation — hardened BananaPad macOS core

Date: 2026-08-31 11:17 CDT
Result: **pass**

## Claim

The hardened BananaPad Apple static profile boots DK64 natively on this Apple Silicon Mac before mobile acceptance work. It renders through Metal, runs the DK64 audio path, accepts native input, executes the ahead-of-time game/patch/overlay path, exposes diagnostics, and exits cleanly without desktop launcher or dynamic-code dependencies.

## Exact artifacts

- Upstream: tag `1.0.1`, commit `c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43`.
- Recursive source manifest: `bebfa8f085ae40eafed4ca3d79fbbd7bf5566114a550b11878fba181c7ffc088`.
- Patched recursive worktree: `dc7ebbe93fc49cca1c4988a4f1ee3a524b9218289576465d361df757446177ff`.
- BananaPad patch file: `3cd32de52cbc137ead6d69864da715dcf11d1dd9e7f44282f3bab2e611ae17a9`.
- Complete patch series: `a334b8e31bb06d4ce4b4b4e321b3255cee61b970024ad807be4e956604e963a3`.
- Hardened macOS executable: `64ce990a3935619909ca972f30cdae927a799561b819520499c778ab31a8b80a`.
- Hardened macOS app aggregate: `3b780de86c4cc3694a387484cd0882036c00612a6e982ecda5d5c3e7ad922928`.
- Same-source iPad Simulator executable: `47cf2d83e266422ae5980de8b1daabb7cdff9dd4f8291479448886078c18d69a`.
- Promoted dependency lock: `6be868adab31ee27b27923b72358680b7608ea32a1a5c54bf0aabaa4d799104b`.

## Native macOS evidence

The exact hardened macOS app direct-booted DK64 and rendered the DK Rap through the Apple M2 Metal device. Attached diagnostics recorded SDL's Cocoa backend, recomp heap initialization, ROM DMA, global-overlay dispatch, and `func_global_asm_805FBFF4 Started`. A process sample showed an active AudioQueue callback and CoreAudio I/O threads.

Native Return/Start input was delivered to the foreground app and the visible state advanced into the DK64/Dolby boot sequence. Evidence is preserved locally at:

- `generated/evidence/bananapad-macos/g4-current-static-core-window.png`, SHA-256 `c1a11cd16935b85952cb61c80f4530788ae6c5a7fe8d1312c53c11e2f0ef1f4e`;
- `generated/evidence/bananapad-macos/g4-before-start-input.png`, SHA-256 `925e52eee6ae74c5106e9c6352ef6f4ddfdb3dda3f3a3c613c8df26529bc556f`;
- `generated/evidence/bananapad-macos/g4-after-start-input.png`, SHA-256 `177963bec7a1c2a543adb94edc539d3a38a89153f44118dd007d3298de370f63`.

The no-dynamic-code audit passed. After a shutdown defect was isolated and repaired, two exact-artifact runs—including a post-input run—exited within 250 ms of a normal termination request. No BananaPad process remained.

## Simulator regression after macOS acceptance

Only after the macOS core was stable, the same refreshed patch was built for the isolated iPad Pro Simulator. The app installed, received the verified private ROM in its app container, launched as PID `75039`, visibly rendered DK64 with the PaperPad touch overlay and three-dot menu, and survived the 20-second smoke.

The ignored receipt is `generated/validation/ios-simulator-last-run.json`. The visible screenshot is `generated/evidence/bananapad-ios/g4-simulator-static-core.png`, SHA-256 `dfe8b3a6c670ae5ce48f73bf9a2b2c6d2473141d747aba20a006257d55034a79`.

The exact candidate passed `check-no-dynamic-code.sh`, `audit-ios-package.sh`, `audit-mobile-execution-model.sh`, and `test-upstream-update.sh`. Promotion rehearsal, promotion, rollback, and re-promotion reproduced the promoted lock byte-for-byte: old SHA-256 `e789b5e3ecf3cd1be5f55b968535daf3ab1183d0b1738541d20a857445444f6c`; new SHA-256 `6be868adab31ee27b27923b72358680b7608ea32a1a5c54bf0aabaa4d799104b`. Recoverable snapshots are under ignored `generated/upstream/promotions/20260831T161623Z`, `generated/upstream/promotions/20260831T161638Z`, and `generated/upstream/rollbacks/20260831T161701Z`.

## Interpretation

G4 is met. The lowest unmet goal is G5: the complete macOS first-play and save/reload acceptance route. The successful iPadOS Simulator regression supports portability but does not replace G5 and is not physical-device evidence.
