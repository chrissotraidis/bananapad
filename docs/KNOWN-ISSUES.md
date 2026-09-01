# Known issues

## Open

| Severity | Goal | Issue | Current evidence / next experiment |
|---|---|---|---|
| High | G3/G5 | N64Recomp reports an ambiguous shared-overlay `jal` at `0x80024000` and an indirect tail call in `recomp_entrypoint`. | Deterministic output and complete static tables exist. Exercise consecutive menu/minecart/bonus/race/critter/boss/arcade/Jetpac transitions and inspect overlay breadcrumbs. |
| Medium | G3/G7 | `recomp_on_new_file_start` is compiled as an event stub but absent from the ten-name registered base-event list. | Compare clean/new/dirty file routes and trace the generated event reference at the promoted pin. |
| Medium | G3/G5 | Released patch compilation emits pointer, signedness, unused-value, attribute, and possible `sp1A4` initialization warnings. | Classify each warning against the exact patch function and run its owning gameplay route before suppressing anything. |
| Medium | G3/G6 | Full RSP/audio behavior and route-change matrix is not complete. | Instrument queue depth/underruns and exercise the scenes in `RSP.md` on macOS before mobile-device claims. |
| Medium | G3/G5 | Interrupted-write, erase, explicit desktop import/export, and cross-version save round trips remain. | Use disposable save fixtures and verify primary/backup hashes and exact `0x800` length. |
| Low | G4 | The pinned PaperPad SDL2 macOS archive was built with a newer deployment version than BananaPad's macOS 14 link target, producing linker warnings. | Rebuild the pinned SDL2 archive with an explicit macOS 14 deployment target and repeat the macOS smoke. |

## Resolved during targeted G8 regression (2026-08-31)

- The graphics-thread `EXC_BAD_ACCESS` at `0x750`, and the later map-load `SIGBUS` initially correlated with an old iPad save folder, shared one intermittent RT64 startup cause. DK64 can expose canonical F3DEX2 2.07 text hash `0x8C1C9814E75E1B4B` or alternate text hash `0x8EDC2B2BC4D1E3B6` with the same data hash `0xF8649121FAB40A06` and embedded `RSP Gfx ucode F3DEX fifo 2.07` identity. BananaPad now waits to signal SP completion until after native `send_dl()` and, only in `BANANAPAD_NATIVE_SHELL`, recognizes that exact alternate hash as F3DEX2 2.07. Upstream desktop behavior is unchanged. Working executable `606cc86d18007d9b6aef9dd732ae51537dc8187d7a0bdc04af8984f98eb3a636` passed one 20-second smoke plus four ordinary relaunches with the previously suspect state; clean replayed executable `77d18de47a9e5ac6fb0239d6703aba5f8048a34826c12f60c2271e272b0bb3fd` then passed separate iPad and iPhone locked-ROM smokes with no new crash report. The prior save-corruption classification is retracted; save compatibility remains independently unaccepted until a game-visible write/reload test passes.
- Simulator evidence is now immutable per app/worktree/run under ignored `generated/validation/ios-simulator-runs/`. Candidate testing selects an exact matching receipt instead of trusting the overwriteable latest-run pointer.

## Resolved during G3

- Removing LiveRecomp initially skipped allocation of the fixed base-event table and produced `event index out of bounds`; the no-dynamic profile now creates the empty AOT base-event dispatch table.
- The initial supplied graphics-thread crash was first classified against an older executable and did not reproduce during five runs of the then-current candidate. Later ordinary launches did reproduce the same `0x750` signature in that candidate; the targeted G8 resolution above supersedes the earlier timing-sensitive conclusion.

## Resolved during G4

- The hardened Apple no-dynamic-code runtime initially hung during clean termination because the host joined a guest game thread parked inside the single-session DK64 execution loop. The Apple static profile now finishes the host-owned event, cleaner, and saving threads, flushes streams, and exits without waiting for that unrecoverable guest thread. Two exact-artifact macOS runs, including a post-input run, exited within 250 ms of the termination request.
