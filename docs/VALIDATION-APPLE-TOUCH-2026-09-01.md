# Apple touch and Simulator validation — 2026-09-01

## Result

The clean-replayed arm64 iOS Simulator gameplay executable boots the locked DK64 US 1.0 ROM on separate iPad and iPhone Simulators, renders through Metal, and visibly shows PaperPad's complete N64 touch overlay and persistent three-dot menu. It opened native Settings and accepted observed touch input through DK64 menus and gameplay. A runtime-identical rebuild containing BananaPad's original provenance-bound icon subsequently passed fresh locked-ROM smokes and direct overlay/menu inspection on both form factors. Only one Simulator was booted at a time, and every target was shut down before switching.

This accepts G8/G9 as Simulator form-factor platform gates: verified ROM, title/file creation, real gameplay input, save write, terminate/relaunch, and visible reload all succeeded independently on both targets. It is not a substitute for G6/G7 full-game qualification or G12 physical multi-touch, controller, audio-route, performance, and device testing.

## Exact candidate

- Executable SHA-256: `77d18de47a9e5ac6fb0239d6703aba5f8048a34826c12f60c2271e272b0bb3fd`
- Product-source SHA-256: `17562f563d4fb2e9b916351597ba8a2759e1a15871953eb51a53c0965c511965`
- Patched upstream worktree SHA-256: `a7d09b22646780518091b3b60c72679d3ea3c5c8c7b95773a4a5115bc0c74155`
- Integration patch SHA-256: `6560adbb4a8b3c8a239f5353329d788c615631fc03f366c7980b0aeacc7dbd5e`
- Complete patch-series SHA-256: `501c7555885fe4997eb62173cf95ecd7787633cb7fb3486d06a12334c063eb16`
- Promoted upstream commit: `c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43`
- PaperPad UI SHA-256: `feb4e78539e4473bff324d402c158de08b9a7eb7f5038787f2dedf0038472c44`; `apple/app/ios_main.mm` is byte-identical to the pinned reference.
- Private ROM: exact locked 33,554,432-byte DK64 US 1.0 identity; no ROM or save is part of this evidence document or repository.

## Current icon-packaged candidate

- Executable SHA-256: `f4fab84e2b0b99c8cba45ccfd576f256810eebd660f25fbf00805564b910f182`.
- Product-source SHA-256: `35024db329d0690338f1cf05c1a2c9c2592f86c419c18ec3756d7f07f3a8bf16`.
- Patched upstream worktree and patch-series identities are unchanged from the gameplay candidate.
- iPad locked-ROM receipt: `generated/validation/ios-simulator-runs/f4fab84e2b0b99c8cba45ccfd576f256810eebd660f25fbf00805564b910f182-a7d09b22646780518091b3b60c72679d3ea3c5c8c7b95773a4a5115bc0c74155-20260901T080731Z-pid36872.json`.
- iPhone locked-ROM receipt: `generated/validation/ios-simulator-runs/f4fab84e2b0b99c8cba45ccfd576f256810eebd660f25fbf00805564b910f182-a7d09b22646780518091b3b60c72679d3ea3c5c8c7b95773a4a5115bc0c74155-20260901T080854Z-pid37598.json`.
- Canonical candidate-path locked-ROM receipt: `generated/validation/ios-simulator-runs/f4fab84e2b0b99c8cba45ccfd576f256810eebd660f25fbf00805564b910f182-a7d09b22646780518091b3b60c72679d3ea3c5c8c7b95773a4a5115bc0c74155-20260901T081349Z-pid39633.json`.
- Direct captures: `generated/validation/screenshots/icon-candidate-ipad-smoke.png`, SHA-256 `c4afd3969e79607e48b57010d6e3f2a1b530342eaace82da914436eee003ab93`; `generated/validation/screenshots/icon-candidate-iphone-smoke.png`, SHA-256 `7da623573167f171e25963bf6eb51026f1d86ea7472ac62793ca5d11e8614eab`.
- The app-icon asset, source master, prompt, processing record, exclusions, and hashes are recorded in `apple/app/Assets.xcassets/AppIcon.appiconset/PROVENANCE.md` and guarded by `scripts/test-app-icon-contract.sh`.
- The first canonical-path launch reproduced the already-recorded intermittent `SIGBUS` in `func_global_asm_80650E20`; the immediately repeated identical executable passed. The incident report is retained at `~/Library/Logs/DiagnosticReports/BananaPad-2026-09-01-031245.ips`. This does not invalidate the four successful current-package smokes, but it remains a known startup reliability item rather than being concealed as a touch/UI failure.

## iPad evidence

- Target: `BananaPad iPad Pro`, iOS 26.5.
- The final clean-replayed executable survived the receipt-producing locked-ROM 20-second smoke with the previously suspect Simulator state.
- Immutable final-candidate receipt: `generated/validation/ios-simulator-runs/77d18de47a9e5ac6fb0239d6703aba5f8048a34826c12f60c2271e272b0bb3fd-a7d09b22646780518091b3b60c72679d3ea3c5c8c7b95773a4a5115bc0c74155-20260901T061907Z-pid91638.json`.
- The final candidate visibly displayed the full overlay and opened the three-dot menu. In the earlier product-source-equivalent interactive session, touch Start skipped the DK Rap/intro and entered the main menu, and touch A selected Adventure and reached an empty file slot.
- The three-dot menu hid gameplay controls and exposed Settings and diagnostics. Settings showed volume, Auto/1x–4x resolution, aspect ratio, enabled touch controls, 55% persisted opacity, layout edit/reset, diagnostics, ROM management, and Done.
- Private ignored screenshots:
  - `generated/validation/ipad-touch-20260901T0047CDT/adventure-file-select-touch-a.png` — SHA-256 `9fd96731181542ae0dc6bb39454a5b3d15ce00998e365f6ae289f973e70bd0aa`
  - `generated/validation/ipad-touch-20260901T0047CDT/three-dot-menu.png` — SHA-256 `4df50791ea88dc753956577d7648daeeca4d2789864a2b4eb906e0ac5fa133cc`
  - `generated/validation/ipad-touch-20260901T0047CDT/settings.png` — SHA-256 `ee1ec416309c2241232cfc0420da00685cc2b3b5504cffd32e35eeb220b529e2`
  - `generated/validation/ipad-staged-candidate-20260901T0120CDT/three-dot-menu.png` — final candidate, SHA-256 `85ebc32ec7ea7ed9a740d6d031c5774c745050359a69e917669649b01a5ca542`

## iPhone evidence

- Target: `iPhone 17 Pro`, iOS 26.5, booted only after the iPad was shut down.
- The same final executable passed a receipt-producing locked-ROM 20-second smoke.
- Immutable final-candidate receipt: `generated/validation/ios-simulator-runs/77d18de47a9e5ac6fb0239d6703aba5f8048a34826c12f60c2271e272b0bb3fd-a7d09b22646780518091b3b60c72679d3ea3c5c8c7b95773a4a5115bc0c74155-20260901T062130Z-pid92762.json`.
- The independent compact landscape layout kept the stick, D-pad, C cluster, A/B/Z/L/R/Start, and three-dot menu reachable inside the phone safe area.
- The three-dot menu and Settings opened; Settings showed the same native controls at the compact size. Touch Start skipped the intro.
- Private ignored screenshots:
  - `generated/validation/iphone-touch-20260901T0049CDT/settings.png` — SHA-256 `c9f3dcdc4fe12def1e49cd260be4daff6a71b08130def23013cd7d37ae8d429c`
  - `generated/validation/iphone-touch-20260901T0049CDT/touch-start-transition.png` — SHA-256 `825507c44d02a3e0675867ccc999e485dc632852533455f7751a4e674e3250dd`
  - `generated/validation/iphone-staged-candidate-20260901T0122CDT/touch-overlay.png` — final candidate, SHA-256 `a680a8010d1a33a10554753087d156603753dae810f7dfe64cf2f147a99fddcf`

## Controller and touch bridge

The native SDL adapter now reports attached-controller state to `PaperPad_SetPhysicalControllerConnected` both when an existing handle remains attached and after device rescanning. The exact PaperPad source performs main-thread overlay visibility changes and deliberately treats CoreSimulator's synthetic MFi controller as disconnected, allowing Simulator touch testing. `scripts/test-touch-input-contract.sh` guards both notification paths in addition to every N64 mask, independent touch ownership, tap latching, merging, analog clamping, and lifecycle release.

## iPhone compact lifecycle follow-up

The same installed app was relaunched with its current app-created 2,048-byte EEPROM file (SHA-256 `6bac2800d45107e251842b177ba1f86878073056c964e404530de3c455a51758`) and remained live. The compact touch layout editor opened and returned through Reset and Done. Sending the app Home and reopening BananaPad resumed the existing game with the full overlay restored. Rotating through both landscape orientations kept the stick, D-pad, C cluster, A/B/Z/L/R/Start, and three-dot menu inside the safe area while DK64 continued rendering.

The ignored opposite-landscape screenshot is `generated/validation/iphone-lifecycle-20260901T0100CDT/opposite-landscape.png`, SHA-256 `377a22f2113613e89205a1643137c47628db9e71130072e196fec40d6fcf28eb`. The Simulator Sleep/Wake control did not visibly suspend the app, so no sleep/wake result is claimed.

## Exact-candidate gameplay and save/reload follow-up

After the clean replay passed both smokes, executable `77d18de47a9e5ac6fb0239d6703aba5f8048a34826c12f60c2271e272b0bb3fd` was exercised interactively on each target, still with only one Simulator booted at a time.

On iPad, touch Start/A created Game 1 and the complete mandatory new-file cinematic reached playable DK's treehouse. Repeated edge taps on the virtual stick moved/turned DK; touch A visibly jumped and touch B visibly attacked. The app wrote primary and backup 2,048-byte EEPROM files. Primary SHA-256 was `6d16991320b7786abc8e8fe3f0f4964052a71d24ca48aef256062523be159fe1`. After terminate/relaunch, touch navigation visibly reopened Game 1 at `0%`, `000` Golden Bananas, and `00:04`. Evidence: `generated/validation/ipad-first-play-20260901T0136CDT/reloaded-game1.png`, SHA-256 `fda4bcc73a05aef9ae67e8cd1150560db3905526bad4ea0baa7f27d080507e71`.

The iPad was then shut down before booting iPhone. On iPhone, the compact touch layout independently created Game 1, completed the new-file cinematic, reached treehouse gameplay, moved DK with the virtual stick, jumped with A, and attacked with B. Its primary 2,048-byte EEPROM SHA-256 was `54a04cb7dc031627db84910b72feca2205d75854d138943698874c15e2d2e558`. After terminate/relaunch, compact touch navigation visibly reopened Game 1 at `0%`, `000`, and `00:04`. Evidence: `generated/validation/iphone-first-play-20260901T0145CDT/reloaded-game1.png`, SHA-256 `da49980d376d74a78c02a245186cac78105727cb878e197f80cfd463d18251e7`.

This proves the complete mobile platform loop on the final artifact and accepts G8/G9 under the user-directed goal ordering. Training Grounds, Golden Bananas, Jungle Japes, later worlds, and complete progression remain G6/G7 game-correctness qualification; repeating that route per Simulator is not required unless it exposes a form-factor-specific defect.

## Exact-candidate iPad control and Training Grounds follow-up

The same final executable was resumed on the sole iPad Simulator. In live gameplay, Z visibly put DK into his crouch, C-left and C-right rotated the original N64 camera in opposite directions, C-up and C-down moved between extreme and normal camera distances, and R recentered the camera relative to DK. L was delivered through its visible touch target but has no distinct game-visible effect in this early DK state; its N64 mask remains covered by the compiled input contract. A B tap immediately followed by Simulator Home, then reopening BananaPad, resumed the existing game with DK idle and the overlay restored, providing game-visible support for lifecycle input clearing.

Using only touch Start/A/stick, the route left DK's treehouse balcony, jumped to ground, crossed to the cave, followed its bend, and emerged into the Training Grounds clearing. DK subsequently entered the training pool while approaching the barrel area. No Training Barrel completion, Simian Slam, or persisted progression is claimed. Swimming remained responsive, and the run was terminated before the sole Simulator was shut down. Pool evidence: `generated/validation/ipad-controls-training-20260901T0205CDT/training-pool.png`, SHA-256 `7389bb5913872e0e9acaba4dbce5c3a1aa7c409be0dccf6e63a43cf4928de547`.

A second clean resume reproduced the treehouse-to-cave-to-Training-Grounds route. In the pool, repeated B input produced DK's forward swim stroke and stick direction steered him along the bank. The approached bank was too high to climb directly; the run ended cleanly without claiming a barrel. A later route review established that Cranky's dialogue is the prerequisite for spawning the four barrels. This discarded navigation attempt is neither an input failure nor a product blocker, and no further tutorial-route automation is required for G8/G9.

## Startup incident and resolution

The first iPad smoke reused older Simulator state and exited by `SIGBUS` in `func_global_asm_80650E20` while loading map geometry. Removing the active save appeared to make the fault disappear, but later ordinary launches reproduced the startup failure without that correlation. Console evidence showed RT64 intermittently receiving F3DEX2 2.07 text hash `0x8EDC2B2BC4D1E3B6`, data hash `0xF8649121FAB40A06`, and embedded name `RSP Gfx ucode F3DEX fifo 2.07`; only canonical text hash `0x8C1C9814E75E1B4B` was recognized. The native profile now both orders SP completion after `send_dl()` and recognizes the exact alternate text hash. Working build `606cc86d18007d9b6aef9dd732ae51537dc8187d7a0bdc04af8984f98eb3a636` passed a 20-second smoke and four further ordinary launches with the previously suspect state; the clean replayed final candidate then passed both form factors. No new crash report or rejected-ucode log appeared. The earlier save-corruption hypothesis is retracted, while actual save compatibility remains unclaimed pending game-visible write/reload testing.

## Remaining acceptance

- Physical two- and three-finger Z+A, Z+B, and Z+C-direction chords.
- Remaining L/context behavior, slide-in/out, cancellation, and layout-editing breadth on both form factors, plus Z/R/all C-direction game-visible repetition on iPhone. Stick/A/B are game-visible on both; Z/R/all C directions are now game-visible on iPad.
- Real controller takeover/disconnect/reconnect and held-state clearing.
- Remaining background/foreground breadth, interruption, orientation changes, ROM replacement, progressed-save reload, audio route changes, memory pressure, and sustained play.
- G6/G7 full-game progression/correctness breadth, physical G12, and release authorization G13.
