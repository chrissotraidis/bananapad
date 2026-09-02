# BananaPad v0.1.0-preview.1

Developer Preview 1 is the first ROM-free unsigned BananaPad IPA candidate for
arm64 iPhone and iPad devices running iOS or iPadOS 15 or newer.

## Candidate assets

- `BananaPad-v0.1.0-preview.1-unsigned.ipa`
- `BananaPad-v0.1.0-preview.1-unsigned.ipa.sha256`
- SHA-256: `a7f3a7a280770644bb175553c2d70c5af032959fd1e425d89b164f721b53d55e`
- Size: 7,479,430 bytes
- App executable SHA-256: `ee876b51aec617563963ee898c6ec36f87a3dffbfc10c2dc2636182c8a7a0442`
- Source rollup commit: `0d509886adc9b2c3b46b8343542d89eeaa383fa5`

The IPA is unsigned and must be re-signed with the user's own Apple Account.
It does not include Donkey Kong 64, a ROM, extracted assets, generated private
inputs, saves, logs, a provisioning profile, or signing material. BananaPad
does not require JIT.

## Highlights

- Native Metal rendering on Apple Silicon.
- Customizable independent-finger iPhone and iPad touch controls.
- Persistent BananaPad three-dot menu, settings, diagnostics, and private ROM
  management.
- Physical-controller support, including the iPadOS Xbox A/Start duplication
  repair in the pinned SDL2 integration.
- CRC-checked private save-slot import tooling for local capture preparation;
  no save files are distributed.
- Scripted, isolated DK64Recompiled update staging and recoverable rollback.

## Verification

Two independent deterministic package runs matched byte-for-byte. The exact
candidate passed ZIP integrity, complete notice/license/install/rights content,
arm64 iPhoneOS 15 metadata, both iPhone/iPad family declarations, privacy,
system-only runtime dependency, no-dynamic-code, ROM/save/private-data, signing,
credential, and personal-build-path audits.

## Preview limits

The signed development build installs, launches, renders DK64, and preserves
the private ROM/save/settings on the tested physical iPad. Broader controller
reconnect, audio interruption/route, memory-pressure, sustained-operation, and
physical-iPhone acceptance remain preview work. Build/install proof is not a
claim that every hardware route has completed acceptance.
