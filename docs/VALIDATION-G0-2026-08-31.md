# G0 validation — 2026-08-31

Goal: environment, references, and safety ready.

## Result

**Pass.** This validation establishes readiness only. It does not prove G1 generation, a product build, launch, gameplay, persistence, Simulator behavior, physical-device behavior, or release clearance.

## Host

| Item | Observed |
|---|---|
| Host | macOS 26.5, Apple Silicon arm64 |
| Xcode | 26.6 (`17F113`) |
| Metal Toolchain | installed (`17F109`) |
| CMake / Ninja | 3.27.1 / 1.13.2 |
| Git / jq | 2.41.0 / 1.7.1-apple |
| Python | 3.13.0 selected; minimum enforced is 3.11 |
| Rust / Cargo | 1.97.1 / 1.97.1 |
| GNU cpp | `cpp-16` present |

## References

| Reference | Verified pin | State |
|---|---|---|
| DK64Recompiled | `c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43` | detached, tracked-clean, recursive manifest verified, push disabled |
| PaperPad | `74b6e45830a06c7f274c5ac1ddd7c625bc13a557` | detached, tracked-clean, push disabled |
| SunPad | `e43f0ea6b797e5110787171957c9dc3c6213269c` | detached, tracked-clean, push disabled |
| N64Recomp host tools | `2b6f05688de2abc7d86da5b4a89b84c2c6acbabe` | detached, tracked-clean, recursive manifest verified, push disabled |

- DK64 recursive manifest SHA-256: `bebfa8f085ae40eafed4ca3d79fbbd7bf5566114a550b11878fba181c7ffc088`
- Host-tool recursive manifest SHA-256: `27357f050f3dc6be8470d1471c2487557941d4a0161404019788a46e9d62ad6b`
- Latest observed stable: `1.0.1` / `c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43`
- Observed upstream `main`: `ee0455d131e0e2198821d35a88033b18524d75ba`

## Recompiler build

The released workflow pin configured with AppleClang/Ninja and built both executables:

| Tool | SHA-256 |
|---|---|
| `N64Recomp` | `1ce3c89269e2c609bdd056d11f03b8470b30eeae3d09c217193a2e71fbd4ecdf` |
| `RSPRecomp` | `637e517911d9461d4cb45d9e59de11102a10629ad83fb548f2465c49dfa1b792` |

One duplicate-static-library linker warning was observed and recorded in `JOURNAL.md`; the executables linked successfully.

## Commands passed

```sh
scripts/check-prerequisites.sh
scripts/verify-sources.sh
scripts/check-repo-safety.sh
scripts/check-upstream.sh
bash -n scripts/*.sh scripts/lib/*.sh
jq empty dependencies.lock.json
git diff --check
```

`scripts/check-no-dynamic-code.sh` also passed against `/bin/ls` as a benign Mach-O smoke of the audit machinery. A BananaPad artifact must pass the same audit later; this smoke is not candidate evidence.

## Safety boundary

- `ref/`, `worktrees/`, `generated/`, builds, artifacts, ROM/save/log/crash/signing/package extensions, and generated recompilation outputs are ignored.
- The repository audit scans publishable tracked/untracked files for forbidden paths/extensions, N64 ROM magic, oversized files, personal paths, private-key markers, and likely tokens.
- The package audit scans expanded `.app`/`.ipa` contents and invokes the no-dynamic-code entitlement/Mach-O/string audit.
- `RIGHTS-STATUS.md` is `private-only`; no publication is authorized.
- The original ROM has been identified and hashed but not modified.
