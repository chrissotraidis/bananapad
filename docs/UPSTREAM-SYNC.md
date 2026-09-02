# DK64Recompiled upstream synchronization

Last updated: 2026-09-02 20:15 JST

## Identities

| Role | Identity | State |
|---|---|---|
| Promoted | tag `1.0.1`, `c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43` | Initial reproducibility anchor; normal build input |
| Last observed stable | tag `1.0.2`, `9177e21a3f633e834779573783b399750f20e7fe` | Observed and mechanically evaluated 2026-09-02 |
| Last observed `main` | `fe291083` | Observed 2026-09-02; not selected or promoted |
| Candidate | none | The successful `1.0.2` rehearsal was archived recoverably after a subsequent Xbox/iPadOS input repair changed the Apple product identity; restage with `evaluate-latest` before qualification |

## 2026-09-02 stable 1.0.2 rehearsal

`scripts/manage-upstream.sh evaluate-latest` selected the real stable `1.0.2` tag in an isolated worktree without changing the promoted `1.0.1` checkout, dependency lock, hardware app, ROM, or saves. The first replay found an overly broad trailing context line in the BananaPad `main.cpp` patch after upstream added CLI `argc`/`argv`; narrowing that hunk preserved the intended native-shell guard and applies cleanly to both versions. The next macOS link exposed that RT64's new Application Support helper was listed only in the iOS source set. Moving that existing Objective-C++ source into the shared Apple native-shell source set fixed both macOS and mobile without duplicating the implementation.

The final candidate replay passed exact patch application, deterministic ROM/game/patch/RSP generation, macOS build, iPhone/iPad Simulator build, code signing verification, exact PaperPad branding/touch/ROM contracts, and the ROM-free iOS package audit. Identities are recursive manifest `c5bf0f1fbc15d6044312816c9c8803b0e074f4837a851f0c86b89237e85feb18`, recursive worktree `08a83782323421d4b9f684faa8518011881b1956e95526b93ca942ada142085d`, patch series `a9c05e4fa8d4f06816c1ea0a3144bbfd185890bd8453a73eeadb412a2b24f5c3`, macOS executable `05ad6d3a71349ab042e16201c0576de5d97a02da1b3be8c95deea9e8b807282b`, and Simulator executable `12e963eac4685900621554d245af735f7eb691e088d487a388e985d64311c560`.

The manager correctly returned `needs-full-validation`. `1.0.2` changes game patches and N64ModernRuntime in addition to camera inversion, analog camera, swimming axes, audio, pause-menu interpolation, HUD/lightning rendering, and new-file startup. It therefore needs the named gameplay, audio, settings, save/reload, and exact-candidate Simulator qualification before promotion. A subsequent Xbox/iPadOS input repair changed the Apple product hash, so the now-stale candidate was archived recoverably under `generated/upstream/rollbacks/20260902T111456Z`; `1.0.1` remains the known-good promoted product and `evaluate-latest` will stage a fresh identity when qualification resumes.

## 2026-09-01 real upstream-drift rehearsal

The guided manager evaluated actual newer upstream `main` commit `1b22409b5297dbb710843cc4493d9b7a4a303bdc`, not merely the promoted pin. It cloned the complete recursive source graph into an isolated worktree, applied the external BananaPad patch series without fuzz, deterministically regenerated the changed game inputs, built the Apple macOS support core and iOS/iPadOS Simulator app, and passed no-dynamic-code and package audits. No Simulator was booted and DK64 was not launched.

The candidate produced game-manifest SHA-256 `a03d80b5be4cfe5c9beab8e380a73dd3ba0f34ab12af12244d82c96c32803846` and Simulator executable SHA-256 `5e1ccc954965e95f6da6ffe85bff9ade31df631003d0f2affc9079235688f6cc`; product source remained `d7e4873026331e89acbee9e30d91f5daf5b5de8023b011650f040783040fc0cb`. The manager correctly returned `needs-full-validation` because the commit is a genuinely newer, untagged runtime pin. It did not promote `main`. Rollback archived the candidate recoverably under `generated/upstream/rollbacks/20260901T132438Z`.

The release-readiness contract then exposed a rollback defect: the checkout and metadata had been archived, but candidate-generated inputs and macOS/iOS build directories remained at their canonical paths. `rollback-upstream-update.sh` now archives all five candidate components together, and `test-update-evidence-contract.sh` enforces that behavior. The rejected newer-main checkout, metadata, generated inputs, macOS build, and iOS build are all present in that recovery archive. A fresh same-pin evaluation subsequently reconstructed executable `b9c1d2a90d5dd47ec945413e642a827ca5b9d0836e403de29c75cfd242517955` and passed the complete non-game product-candidate gate.

Post-rollback verification reproduced the pre-rehearsal dependency lock `c6b661c21b3a7698972197dfe41f149b6089cecbc95126f89d74469628aecd0d`, normal Simulator executable `739fecd9aed836bf235c15ddfac2f80b50babd88fe4850e410e4d79524505117`, and normal device executable `2519ee937149d35d367a0b823ac1831a37f710492c9fdcf3658119de5675c2f5`. This proves the update path handles real upstream drift while preserving the installed/known-good product. A future stable tag or deliberately selected fix still receives the named affected-route qualification before promotion.

## 2026-09-01 mobile-shell same-pin promotion

The active goal no longer replays the accepted DK64Recompiled game baseline. An attempted no-ROM “shell smoke” was removed after it exposed an invalid harness assumption: ROM setup intentionally waits for native import, so `simctl launch` cannot serve as a non-game completion receipt. Same-pin maintenance now uses the correct evidence boundary—clean iOS/iPadOS build plus exact PaperPad UI, touch/three-dot-menu, ROM-management, renderer-order, package, no-dynamic-code, patch-replay, generated-input, and archived-baseline contracts. Runtime smoke remains available only for a genuinely newer pin with a named compatibility risk.

The replay also found and corrected an integration-patch hunk count (`+67` to `+68`) without changing the applied Apple source. Fresh isolated identities are: recursive manifest `bebfa8f085ae40eafed4ca3d79fbbd7bf5566114a550b11878fba181c7ffc088`, recursive worktree `d1bbe0dd4c04a8a793648cdcdc4b690064f9e725418211c06326c1eb1c896a70`, patch series `8f9e051ed2d643a39a4618acd0c31f3072317732bd29ade1a8687256e91b9505`, product source `d7e4873026331e89acbee9e30d91f5daf5b5de8023b011650f040783040fc0cb`, and clean Simulator executable `b9c1d2a90d5dd47ec945413e642a827ca5b9d0836e403de29c75cfd242517955`. PaperPad `ios_main.mm` remains SHA-256 `feb4e78539e4473bff324d402c158de08b9a7eb7f5038787f2dedf0038472c44`.

`test-upstream-update.sh` and promotion rehearsal passed without booting a Simulator. Promotion, actual rollback, and re-promotion reproduced dependency-lock SHA-256 `c6b661c21b3a7698972197dfe41f149b6089cecbc95126f89d74469628aecd0d`; the rollback restored `0dd7c242d09f2c377ca7d47da255a65388cd8fbd5fac3add0c7bff4cc3eba3c3`. Recoverable snapshots are `generated/upstream/promotions/20260901T123427Z` and `generated/upstream/promotions/20260901T123504Z`. No Simulator or game process remains.

## 2026-08-31 discovery

`git ls-remote` confirmed that `1.0.1` remains the newest stable tag. On 2026-09-01, `main` advanced from `ee0455d131e0e2198821d35a88033b18524d75ba` to `1b22409b5297dbb710843cc4493d9b7a4a303bdc`. The two commits improve D-pad descriptions for Jetpac/Donkey Kong arcade use and add one `us.toml` instruction patch that initializes `$s5` in `func_global_asm_80601D24`. These are categorized as desktop frontend documentation/input-description plus a potential game-correctness patch. They are recorded but not promoted: no newer stable release exists and BananaPad has no named defect requiring an unreviewed `main` advance. The deterministic same-pin staging rehearsal remains green; the next synchronization milestone is a newer stable tag or a narrowly selected fix with an owning regression.

### 2026-09-01 touch/startup replay candidate

The complete BananaPad delta was refreshed after connecting SDL controller state to the byte-identical PaperPad overlay and after classifying a remaining intermittent native RT64 startup failure. In addition to ordering SP completion after `send_dl()`, the native-shell RT64 profile now recognizes exact F3DEX2 2.07 alternate text hash `0x8EDC2B2BC4D1E3B6` with the already-known data hash `0xF8649121FAB40A06`. This mapping is compiled only for `BANANAPAD_NATIVE_SHELL`; desktop RT64 behavior is unchanged, and a contract test guards both the mapping and compile boundary.

The refreshed integration patch SHA-256 is `6560adbb4a8b3c8a239f5353329d788c615631fc03f366c7980b0aeacc7dbd5e`; complete patch-series SHA-256 is `501c7555885fe4997eb62173cf95ecd7787633cb7fb3486d06a12334c063eb16`; clean candidate recursive-worktree SHA-256 is `a7d09b22646780518091b3b60c72679d3ea3c5c8c7b95773a4a5115bc0c74155`. The current original-icon product source is `f00692789f60448dc665611a71d43477cdfbd209517c3c5558a156126e15c7b3`; clean executable `f4fab84e2b0b99c8cba45ccfd576f256810eebd660f25fbf00805564b910f182` passed a candidate-bound locked-ROM iPad smoke after deterministic regeneration from the isolated candidate. Receipt schema 4 binds game manifest `ae6c0ed0deb141a8ee15b3eeb62d73099558ea5b4d8f12fbd906661df62615c6`, patch manifest `2fdbd3ea3029ea6a28975b524d51a4a2302042fa1e7f3ea4c04d8347db0b7c35`, decompressed ROM `04bca239f17380aa2a97e8f04715a09f1f05b74df9c057b609558408fd39c91a`, checkout identity, product source, and executable. The preceding runtime-identical executable `77d18de47a9e5ac6fb0239d6703aba5f8048a34826c12f60c2271e272b0bb3fd` carries the full interactive touch/play/save/reload evidence. `test-upstream-update.sh`, candidate-generation, app-icon/package/no-dynamic-code, PaperPad fidelity, touch/controller, native settings/input, renderer ordering, update evidence, repository safety, and whitespace gates pass. The tested patch identity was promoted on 2026-09-01 without changing the upstream source pin; an actual rollback restored the prior lock and re-promotion reproduced the patch identity. No Simulator is booted.

### Native-shell graphics-task ordering candidate

The targeted Simulator crash investigation found a BananaPad integration race rather than an upstream microcode gap. For the native shell only, `sp_complete()` now follows RT64 `send_dl()` so DK64 cannot replace the task's microcode segments while RT64 hashes them. The upstream desktop ordering is unchanged. `scripts/test-renderer-task-order-contract.sh` guards this boundary.

The refreshed integration patch SHA-256 is `43f96da58f0f27952496f4a36ec47282e9544b6a197bdd389d7e5803c6714a65`; complete patch-series SHA-256 is `eecff7a84ee6c898a5c38ce32ed9561714b137f93d9cc3ab9a128854c9d29f49`; fresh candidate recursive-worktree SHA-256 is `fb8ccbba6c9bc7c6e21a04e90549a5ece766526cc1941c3a4f3bbd6955b9063c`. Its clean iOS Simulator executable SHA-256 `a2c41ad830c096e273f55814bc49fd094662a687c3e5782ad372d4b77518609a` survived one locked-ROM 20-second smoke and four further non-debug 12-second relaunches with no new crash report. The exact immutable receipt, no-dynamic-code/package/execution-model audits, and `test-upstream-update.sh` pass. This same-pin candidate remains staged while G5 gameplay continues; the promoted dependency lock is unchanged.

### Manual-resolution settings refresh

The same-pin candidate was recoverably restaged after the settings audit found that the visible 3x/4x choices fell back to Auto in the older ultramodern graphics contract. The externally replayable runtime delta now adds `Resolution::Manual` and `resolution_multiplier`; BananaPad maps 3x/4x to that route, RT64 applies the multiplier, and multiplier-only changes invalidate the render configuration. The byte-identical PaperPad `ios_main.mm` remains unchanged.

The integration patch SHA-256 is `8f16e2067eeea79d0bf23f7dd54e923eb20d66b2f7c14dc398e2fe3f6e52d441`; patch-series SHA-256 is `e6527b2a866a9ee2a7d38e8d16e7e1ce147bd13bdd39bd109ce071a78d62be48`; candidate recursive-worktree SHA-256 is `e998566a4b372e716f9880ec351a6e51eb3130ca2b9a5cae814801acb3c9a3af`. Clean Simulator executable SHA-256 `709a38a6675a9b422a55a36d269522cdddc010f22f2fc5a1bd2bbe6ef1792b7e` survived its locked-ROM 20-second smoke. A real three-dot-menu session confirmed 3.00x and 4.00x, and the corrected telemetry reported `4.00x (1280x960 internal)` after relaunch. `test-upstream-update.sh`, the mobile execution-model/package/no-dynamic audits, renderer-order/native-settings/touch/fidelity contracts, repository safety, and whitespace checks pass. The candidate remains staged and unpromoted while the ordered G5 gameplay route continues.

### G4 clean-exit patch promotion

The Apple static-profile clean-exit repair refreshed the BananaPad patch file to SHA-256 `3cd32de52cbc137ead6d69864da715dcf11d1dd9e7f44282f3bab2e611ae17a9` and the complete patch series to `a334b8e31bb06d4ce4b4b4e321b3255cee61b970024ad807be4e956604e963a3`. A fresh isolated same-pin candidate had recursive worktree digest `dc7ebbe93fc49cca1c4988a4f1ee3a524b9218289576465d361df757446177ff`; its iPad Simulator executable `47cf2d83e266422ae5980de8b1daabb7cdff9dd4f8291479448886078c18d69a` visibly rendered DK64 and passed the bound smoke and complete audits.

Promotion rehearsal, promotion, actual rollback, and re-promotion passed. The lock moved from SHA-256 `e789b5e3ecf3cd1be5f55b968535daf3ab1183d0b1738541d20a857445444f6c` to `6be868adab31ee27b27923b72358680b7608ea32a1a5c54bf0aabaa4d799104b`, rollback restored the old hash, and re-promotion reproduced the new hash exactly. Recoverable evidence is under ignored `generated/upstream/promotions/20260831T161623Z`, `generated/upstream/promotions/20260831T161638Z`, and `generated/upstream/rollbacks/20260831T161701Z`.

## Same-pin rehearsal result

### G3 static-hardening refresh

The G3 no-dynamic-code changes were mechanically refreshed into the externally owned patch on 2026-08-31. The BananaPad patch SHA-256 is now `62d291e06ff0846b3ff06edabf6ddf4574701cb787592e25656e1b7d5066a765`; the complete series is `a9be9a2d1b7a7def90b6936f1305613774cdde07899c43fbcfbe35d859bfffcb`; and a clean exact application produced recursive patched-worktree SHA-256 `721fa2509e7e280a13b9a573f5685a792e09c37f1cabe7a957139c8137ad6d56`.

That isolated candidate built and ran in the iPad Simulator with executable SHA-256 `73870abcc55c5973ba7804e136097fbd5f0f8ffdfa6f0a1db708a06c277aa2b0`, passed its ROM-bound 20-second smoke, no-dynamic-code audit, iOS package audit, complete execution-model audit, and `test-upstream-update.sh`. Promotion rehearsal, promotion, rollback, and re-promotion passed. The current lock SHA-256 is `e789b5e3ecf3cd1be5f55b968535daf3ab1183d0b1738541d20a857445444f6c`; rollback restored the previous promoted lock `ef5078b439253ec1013b45f8a151b9664d62adc771dc9aa70f78c0f623162c35`, and re-promotion reproduced the current hash exactly. Recoverable promotion snapshots are under ignored `generated/upstream/promotions/20260831T154500Z` and `20260831T154544Z`.

### Full BananaPad patch-lane rehearsal and promotion

On 2026-08-31, the complete working macOS/iPad Simulator integration delta was consolidated into `patches/bananapad/bananapad-integration.patch`. Together with the separate Xcode 26 compatibility patch, the patch-series digest is `c5fe24f048fc3c9452ec19d2ecfef471f76a2820c213695288c332fc8a35f632`.

A fresh isolated `1.0.1` checkout accepted the series with exact forward/reverse checks and no fuzz. Its recursive manifest remained `bebfa8f085ae40eafed4ca3d79fbbd7bf5566114a550b11878fba181c7ffc088`, and its complete patched recursive-worktree digest was `47bb6c525e5b0936092e53aecda66fb8d480be4199dd38031f774e97c184f224`. From that candidate, a clean arm64 iOS Simulator build succeeded; executable SHA-256 `b3812118d108c8fae67c9643d0597c7dd5b3cb6dc1a887e1825a412332e79fde` installed with the locked ROM and survived the automated render-initialization smoke while visibly running DK64.

The candidate gate then passed the archived macOS comparison contract plus the candidate Simulator receipt. A no-mutation promotion rehearsal preserved dependency-lock SHA-256 `407856c6684461ec64373c4cec6f8416a2ccb8aed2d0a63337433af8bf20f938`. The patch-set promotion advanced the lock to SHA-256 `ef5078b439253ec1013b45f8a151b9664d62adc771dc9aa70f78c0f623162c35`; an actual promotion rollback restored the former hash, and re-promotion restored the new hash exactly. Promotion snapshots are under ignored `generated/upstream/promotions/20260831T141402Z` and `20260831T141454Z`; the candidate checkout/test records were archived recoverably under `generated/upstream/rollbacks/20260831T141503Z`.

This proves the current full BananaPad patch can be replayed, built, Simulator-smoked, promoted, reversed, and restored without changing the immutable initial upstream source anchor. A future upstream tag or selected fix still requires impact categorization, regeneration, and the applicable gameplay/save/matrix tests.

### Earlier infrastructure rehearsals

The full non-destructive lane passed on 2026-08-31:

1. staged `c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43` in an ignored independent clone;
2. initialized and verified its complete recursive graph (`bebfa8f085ae40eafed4ca3d79fbbd7bf5566114a550b11878fba181c7ffc088`);
3. applied the external patch series exactly (`27fe62fb92bf639e0427766c2aed8361ce6a550911887d15ae3ad38d663c581c`);
4. tested it against the reproduced, deeply valid baseline bundle;
5. rehearsed promotion without changing the lock;
6. rolled the candidate back recoverably into ignored evidence; and
7. verified the dependency-lock SHA-256 remained `f356b53a5d9a5416312e3114db8c5c640089559161d63a3c32216f98fddb3d26` during the rehearsal.

The original recoverable checkout and JSON evidence live under ignored `generated/upstream/rollbacks/20260831T062420Z`. After recursive worktree-state binding was added, the entire cycle passed again with digest `d68627960485cd09a1401bfe15a4ed7a608e690d66c8d1d5409377c4274db479`; that checkout and evidence live under `generated/upstream/rollbacks/20260831T064155Z`. This proves mechanics and rollback, not compatibility with an unseen future upstream change.

## Required promotion contract

The supported operator surface is `scripts/manage-upstream.sh`: `check`, `evaluate-latest`, `status`, `promote`, and `rollback-candidate`. `evaluate TAG-OR-COMMIT [LABEL]` handles a deliberately selected fix. These commands orchestrate the lower-level steps below; they do not weaken or bypass them.

1. Discover without mutating the promoted checkout or lock.
2. Select a stable tag or an exact, named fix commit/range.
3. Categorize game logic, correctness, enhancement, overlay/decompression, RSP/audio, save/config, input/settings, runtime/renderer, frontend, build/CI, documentation, dependency, and license changes.
4. Stage in ignored `worktrees/dk64-upstream-candidate` with candidate-only metadata.
5. Run `scripts/prepare-upstream-candidate.sh` to regenerate candidate-local ROM, game, RSP, and patch inputs.
6. Run `scripts/build-upstream-candidate.sh --build`; a same-pin rehearsal needs no Simulator or DK64 launch.
7. For a genuinely newer pin, run only the affected macOS/mobile routes and save/config compatibility checks. If a runtime smoke is required, boot exactly one iPad Simulator, provide the verified ROM, run `--smoke`, then shut it down.
8. For a genuinely newer pin, record those results using `scripts/qualify-upstream-candidate.sh` and rerun the exact-identity test gate.
9. Promote one reviewable lock/patch update or record explicit deferment/rejection.
10. Preserve the prior lock, patch hash, generated identities, known-good artifact/command, and compatible save backup for rollback.

Promotion rechecks the candidate commit, recursive submodule manifest, recursive tracked/untracked worktree digest, patch-series digest, deterministic BananaPad product-source digest, clean iOS package, and exact PaperPad/touch/menu/ROM contracts. A newer pin also requires the applicable runtime evidence and exact-identity qualification described in [upstream candidate qualification](UPSTREAM-CANDIDATE-QUALIFICATION.md); when a Simulator smoke is required, its receipt binds generated game, patch, decompressed-ROM, checkout, product, and executable identities. Any intervening vendor patch, Apple core, touch/menu, app-resource, build-script, generated-input, or app edit invalidates the promotion attempt and requires the affected rebuild and evidence refresh.

There is no unattended tracking or auto-merge of upstream `main`.
