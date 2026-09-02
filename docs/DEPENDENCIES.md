# BananaPad dependencies

Last updated: 2026-09-02

`dependencies.lock.json` is the machine-readable source of truth. All source checkouts live under ignored `ref/`, are used read-only, and have push disabled. A moving branch is never a build input.

| Input | Exact starting pin | Purpose |
|---|---|---|
| Donkey Kong 64: Recompiled | `1.0.1` / `c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43` | Game source of truth and archived initial desktop baseline |
| PaperPad | `74b6e45830a06c7f274c5ac1ddd7c625bc13a557` | README/docs quality, verbatim applicable touch UI/three-dot menu, and N64 Apple substrate |
| SDL2 | `5d249570393f7a37e037abf22cd6012a4cc56a71` (2.32.10) | PaperPad-pinned static controller/window/input substrate; mobile builds use an exactly patched generated checkout to prevent iOS controller presses duplicating Apple TV remote keyboard events |
| SunPad | `e43f0ea6b797e5110787171957c9dc3c6213269c` | Additional product-shell, lifecycle, diagnostics, and acceptance mechanisms required by the PRD |
| N64ModernRuntime | `45bd0180f85c89c19ae45d30190be54c9d577904` | DK64 runtime baseline |
| N64Recomp | `81213c1831fab2521a6a5459c67b63437d67e253` | Nested runtime source boundary; the released host generation tool pin will be reconciled separately |
| RecompFrontend | `6d187f7964a44801a4095287acc23a043033aff3` | Desktop comparison only |
| RT64 | `cc6d137a3cca95faa018f24ebb5ca765dbfa7cf2` | Renderer/Metal baseline |
| dk64_decomp | `2431154b417d4e80a6bfaf38291213c059be59f7` | Decompression, symbols, and headers |
| vcpkg | `114d9fe62faf35856b45cf55cb93b57028a45d63` | Upstream desktop dependency graph |
| N64Recomp/RSPRecomp host tools | `2b6f05688de2abc7d86da5b4a89b84c2c6acbabe` | Exact released DK64 generator pin, kept separate from the runtime's nested revision |

The complete recursive DK64 submodule graph is validated from the pinned Git links and a canonical recursive-manifest SHA-256. SDL2 is an explicit BananaPad lock input because PaperPad intentionally keeps its own source checkouts ignored rather than embedding them in the PaperPad Git repository. BananaPad's clone lane therefore downloads the exact PaperPad SDL2 pin into that expected ignored location and disables its push URL; a pre-existing unexplained local checkout is never assumed. `scripts/prepare-bananapad-sdl2.sh` clones that clean pin locally into ignored generated state and applies `patches/sdl2/ios-controller-uipress-duplication.patch` exactly. Simulator/device builds reject any unexplained source state and never edit the pinned reference in place.

The release packager collects the complete license/notice file set found in the
exact pinned DK64Recompiled recursive tree plus the pinned SDL2 license. It
retains their relative paths under `Licenses/`, bundles BananaPad's source and
rights pointers, and audits the result before producing a checksum.

The promoted external compatibility patch series hashes to `27fe62fb92bf639e0427766c2aed8361ce6a550911887d15ae3ad38d663c581c`. It currently contains one Xcode 26 declaration fix for RT64's pinned `hlsl++`; it is replayed outside the pristine reference checkout. The desktop comparison also packages Homebrew SDL3 explicitly because `sdl2-compat` loads it dynamically and CMake's bundle scanner cannot discover that relationship.

## Update policy

Normal builds use only the promoted pin. Discovery updates `lastObserved`; evaluation uses an ignored isolated candidate; promotion is a reviewed lock/patch change after regeneration and impact-selected tests. The initial `1.0.1` baseline record is append-only and remains available after later promotions.

The supported operator entry point is:

```sh
scripts/manage-upstream.sh check
scripts/manage-upstream.sh evaluate-latest
scripts/manage-upstream.sh status
scripts/manage-upstream.sh promote
```

Use `scripts/manage-upstream.sh evaluate TAG_OR_COMMIT review-label` for a selected fix and `rollback-candidate` to reject the staged candidate recoverably. The manager orchestrates the lower-level lane below; it does not weaken the qualification gate:

```sh
scripts/check-upstream.sh
scripts/stage-upstream-update.sh TAG_OR_COMMIT review-label
scripts/test-upstream-update.sh
scripts/promote-upstream-update.sh --rehearsal   # same-pin proof only
scripts/promote-upstream-update.sh --apply       # newer candidate, only after a passing full validation record
scripts/rollback-upstream-update.sh --candidate
```

A newer candidate deliberately stops at `needs-full-validation`; the scripts do not auto-promote a build that has not been regenerated, audited, played, and checked for save/config compatibility.
