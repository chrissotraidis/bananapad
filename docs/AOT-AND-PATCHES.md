# Ahead-of-time game and patch model

## Accepted mobile profile

BananaPad builds the DK64 game functions, the released DK64 patch ELF output, and the audio RSP output ahead of time into one signed arm64 application. `N64MODERN_NO_DYNAMIC_CODE=ON` is a required build input on macOS and iPadOS. The mobile profile does not initialize LiveRecomp, scan executable mods, load native mod libraries, regenerate functions, or rewrite native text.

The complete machine-readable inventory is [AOT-PATCH-MANIFEST.json](AOT-PATCH-MANIFEST.json). Regenerate it with:

```sh
./scripts/generate-execution-manifests.py
```

At the pinned `1.0.1` source and G1 generated identity, the patch output contains:

| Item | Count |
|---|---:|
| Generated functions | 221 |
| Ordinary patch-support functions | 51 |
| Replacement functions | 158 |
| Export functions | 1 |
| Generated event stubs | 11 |
| Registered base-event names | 10 |
| Manual host-function bindings | 71 |
| Upstream patch translation units | 18 |

The manifest records every name, address/offset, ROM size, source hash, patch translation unit, event, export, and manual host binding. Source classifications are either `required-baseline-correctness` or `retained-upstream-enhancement`; desktop frontend/config glue and runtime executable-mod support are not part of the native shell.

## Registration and dispatch

`src/main/register_patches.cpp` registers the embedded patch data and generated static `SectionTableEntry` arrays with `recomp::overlays::register_patches`, then registers exports, events, and manual host symbols. `librecomp/src/overlays.cpp` copies patch bytes into writable data, loads already-compiled function pointers into a writable `func_map`, and resolves guest calls through that data map. It does not copy or generate host instructions and does not make native text writable.

The game output is likewise a compile-time set of native C functions plus generated section tables. Overlay changes replace entries in writable function/section-address maps. This is data dispatch, not native code patching.

## Dynamic-code removal

The no-dynamic profile excludes these mechanisms from the linked application:

- `LiveRecompilerCodeHandle` and `DynamicLibraryCodeHandle`;
- LiveRecomp initialization and generated-code ownership;
- native mod-library loading;
- `patch_func`, regeneration lists, hook-driven function regeneration, and code-mod loading;
- texture-pack executable-module registration;
- `.offline.nrm`, `mod_binary.bin`, TCC, and LiveRecomp artifacts.

The broad imports `dlopen`/`dlsym` may still be contributed by SDL or Apple support libraries. `mprotect` remains in librecomp for non-executable emulated-RDRAM reservation/protection. Those imports are not accepted as evidence by themselves; the audit rejects the actual code-mod/JIT symbols, strings, libraries, entitlements, linker routes, and writable-executable Mach-O protections.

Run the complete check with:

```sh
./scripts/audit-mobile-execution-model.sh
```

## Exact generated identity

- Patch C SHA-256: `1ed9b7473450699578d964b1d88f64263bd48a7e3c6663ef5e2fdd116976d1f8`
- Patch map SHA-256: `609409f864622d8e76b0bb48ef74adad153fd4b1e3791e5afd6e7a8e3f0ed923`
- Patch binary SHA-256: `50a403238b22af54af24a2c62c2130a327aaf410a414708acf6165d90e7cea49`
- Generated patch table SHA-256: `fc0abc68291909f4906ca7f04d15da99833d692404d8f2a704013d96f65f1445`

## Event discrepancy retained for audit

The generated event section includes `recomp_on_new_file_start`, but the generated registered `event_names` array does not. This is recorded as an exact upstream-pin fact, not silently normalized. The other ten names are registered. Gameplay evidence must determine whether the unregistered stub is intentionally unused or a released enhancement defect.

## Remaining behavioral evidence

The architecture and static registration pass on macOS and Simulator. Per-function route coverage is not inferred from compilation: overlay gameplay, enhancements, full audio, saves, and complete-game behavior remain attached to their ordered gameplay gates and known-issues entries.
