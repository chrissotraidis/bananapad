# BananaPad rights status

Last updated: 2026-09-02

## Current authorization

**Chris has authorized the current source rollup and push to the existing private `main` branch, plus creation and audit of the exact first ROM-free unsigned IPA candidate. Repository visibility and public IPA upload remain separate actions and are not changed by this release-preparation pass.**

This status permits the requested private-source merge/push, release documentation, and local candidate creation/audit. It blocks a visibility change or public upload of a tag, release archive, screenshot set, or IPA until Chris authorizes that exact publication action. ROM-derived/private inputs remain non-publishable in every case.

## Current boundary

- The user supplies a legally obtained Donkey Kong 64 US/NTSC-U 1.0 ROM. The original, normalized copy, decompressed build ROM, generated game/patch/RSP code, saves, crash memory, private logs, and app-container data remain local and ignored.
- Donkey Kong 64: Recompiled exposes GPL-3.0 source at the pinned revision. That license does not relicense Nintendo/Rare game material or automatically clear a translated binary for distribution.
- SunPad exposes GPL-3.0 source at the pinned revision.
- PaperPad documents a per-file and per-dependency rights boundary rather than a blanket license for the combined tree. Every copied/adapted file must retain provenance and applicable notices.
- PaperPad touch UI and its three-dot menu are an explicit user-directed implementation reference. The tracked copied/adapted-file inventory and exact revision are recorded in `SOURCE-MAP.md`.
- BananaPad artwork must be original and must not copy protected game art, characters, logos, screenshots, or another project's icon.

## Decisions still required

1. Audit and record the exact source commit and local IPA candidate.
2. Decide whether the repository should become public and whether the exact IPA may be attached to a public release.
3. If approved, verify the hosted source and IPA bytes against the local audited artifacts.

This document is an engineering gate, not legal advice.
