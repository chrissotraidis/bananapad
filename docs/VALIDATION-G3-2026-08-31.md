# G3 validation — mobile-safe execution model

Date: 2026-08-31 10:48 CDT
Result: **pass**

## Claim

BananaPad's game code, DK64 patch code, and audio RSP are compiled ahead of time into signed arm64 applications. Runtime selection and overlay replacement mutate data tables containing already-compiled function pointers; native text is never generated or made writable. The mobile profile excludes LiveRecomp, TCC, runtime compilation, executable mods, native mod libraries, code regeneration, and writable-executable mappings.

The complete human-readable and machine-readable accounts are:

- `AOT-AND-PATCHES.md` and `AOT-PATCH-MANIFEST.json`;
- `OVERLAYS.md` and `OVERLAYS.json`;
- `RSP.md` and `RSP-MANIFEST.json`; and
- `SAVE-AND-ACCESSORIES.md` and `SAVE-MANIFEST.json`.

## Exact candidate

- Upstream: tag `1.0.1`, commit `c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43`.
- Recursive source manifest: `bebfa8f085ae40eafed4ca3d79fbbd7bf5566114a550b11878fba181c7ffc088`.
- Patched recursive worktree: `721fa2509e7e280a13b9a573f5685a792e09c37f1cabe7a957139c8137ad6d56`.
- BananaPad patch file: `62d291e06ff0846b3ff06edabf6ddf4574701cb787592e25656e1b7d5066a765`.
- Complete patch series: `a9be9a2d1b7a7def90b6936f1305613774cdde07899c43fbcfbe35d859bfffcb`.
- Hardened macOS executable: `ac321e8f397e945e6bda8e5f04160a03cd02c8f067dce06ac4f5cf7cdbc0f005`.
- Clean iPad Simulator executable: `73870abcc55c5973ba7804e136097fbd5f0f8ffdfa6f0a1db708a06c277aa2b0`.
- Runtime ROM: standard 32 MiB US ROM, SHA-1 `cf806ff2603640a748fca5026ded28802f1f4a50`; no ROM-derived input is tracked.

The clean candidate built successfully, installed in the isolated iPad Pro Simulator, launched as PID 61128, rendered DK64, and survived the 20-second automated smoke. The ignored receipt is `generated/validation/ios-simulator-last-run.json`.

## Executable proof

The exact candidate passed:

```sh
BANANAPAD_WORKSPACE="$PWD/worktrees/dk64-upstream-candidate" \
BANANAPAD_SIMULATOR_APP="$PWD/generated/build/bananapad-ios-candidate/Release/BananaPad.app" \
BANANAPAD_SIMULATOR_BUILD_DIR="$PWD/generated/build/bananapad-ios-candidate" \
  ./scripts/audit-mobile-execution-model.sh
```

That command regenerates and validates the four manifests; checks all 12 AOT sections, ten compressed classes, the shared overlay replacement boundary, 221 generated patch functions, 158 replacements, 11 generated event stubs, ten registered events, and 71 manual host bindings; verifies the exact `n_aspMain` and `Eep16k` contracts; requires `N64MODERN_NO_DYNAMIC_CODE=ON` in both build caches; rejects writable-text/custom-linker routes; audits both Mach-O applications; audits the iOS package; and binds the Simulator receipt to the executable and ROM identities.

The same candidate also passed `scripts/test-upstream-update.sh`. Promotion rehearsal did not mutate the lock. Promotion, rollback, and re-promotion produced byte-identical promoted-lock SHA-256 `e789b5e3ecf3cd1be5f55b968535daf3ab1183d0b1738541d20a857445444f6c`; the prior promoted lock was restored during rollback as `ef5078b439253ec1013b45f8a151b9664d62adc771dc9aa70f78c0f623162c35`.

## Accounting results

- All generated game and patch sections have fixed AOT tables.
- All ten compressed-code classes have exact compressed triggers, decompressed offsets, runtime destinations, sizes, and AOT function counts.
- The nine replaceable classes deliberately share `0x80024000`; a load replaces data-map entries rather than patching native text.
- The fixed RSP path accepts `M_AUDTASK` and returns statically linked `n_aspMain`; there is no HLE/audio-disable fallback.
- `Eep16k` is intentionally preserved as a 2,048-byte, 8-byte-block EEPROM file contract with temporary and backup files.
- The mobile artifacts have no forbidden dynamic-code entitlements, executable-mod/JIT symbols or strings, or writable-executable Mach-O segments.

## Scope boundary and remaining risks

G3 proves architecture and complete accounting; it does not infer later gameplay acceptance from compilation. Observed load/use/return coverage for each special overlay belongs to G6, the full RSP/audio matrix and interrupted/cross-version save tests belong to G6–G7, and first-play acceptance remains macOS-first in G5 before Simulator first-play in G8.

The ambiguous shared-overlay `jal`, indirect tail call, unregistered `recomp_on_new_file_start` stub, patch compiler warnings, and the one-off initial Simulator SIGSEGV remain explicit entries in `KNOWN-ISSUES.md`. None provides a hidden dynamic-code route or an unaccounted executable section.

## Interpretation

G3 is met. The lowest unmet goal is G4: formally verify the already-running hardened macOS core's video, audio, input, overlay/static-patch participation, and clean exit using the same static profile. Physical iPad or iPhone testing is not part of G4.
