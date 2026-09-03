# BananaPad rights status

Last updated: 2026-09-03

## Current authorization

**Chris has explicitly authorized public source publication and public upload of the exact audited Preview 2 ROM-free unsigned IPA. The repository is public and the approved release is `v0.1.0-preview.2`.**

This authorization covers the exact source tag, GitHub prerelease, IPA, and checksum named in the Preview 2 release notes. It does not authorize ROMs, saves, generated private game inputs, screenshots containing unreviewed game material, signing assets, or user/device data.

Preview 2 publication is complete. The hosted IPA and checksum were downloaded without GitHub authentication, matched the audited local artifacts byte-for-byte, and passed fresh checksum, ZIP, package, and no-dynamic-code audits.

## Current boundary

- The user supplies a legally obtained Donkey Kong 64 US/NTSC-U 1.0 ROM. The original, normalized copy, decompressed build ROM, generated game/patch/RSP code, saves, crash memory, private logs, and app-container data remain local and ignored.
- Donkey Kong 64: Recompiled exposes GPL-3.0 source at the pinned revision. That license does not relicense Nintendo/Rare game material or automatically clear a translated binary for distribution.
- SunPad exposes GPL-3.0 source at the pinned revision.
- PaperPad documents a per-file and per-dependency rights boundary rather than a blanket license for the combined tree. Every copied/adapted file must retain provenance and applicable notices.
- PaperPad touch UI and its three-dot menu are an explicit user-directed implementation reference. The tracked copied/adapted-file inventory and exact revision are recorded in `SOURCE-MAP.md`.
- BananaPad artwork must be original and must not copy protected game art, characters, logos, screenshots, or another project's icon.

## Decisions still required

Future releases require the same exact-artifact authorization and hosted-byte verification.

This document is an engineering gate, not legal advice.
