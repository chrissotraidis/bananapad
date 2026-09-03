# BananaPad v0.1.0-preview.2

Developer Preview 2 is a focused iPhone and iPad update for the two issues
reported against Preview 1. It remains a ROM-free unsigned arm64 IPA for iOS
and iPadOS 15 or newer.

## Assets

- `BananaPad-v0.1.0-preview.2-unsigned.ipa`
- `BananaPad-v0.1.0-preview.2-unsigned.ipa.sha256`
- SHA-256: `2ab9265e0a9eb980c5be85cea829bec98c38a790e022b47361c8c9e60ad7c762`
- Size: 7,479,552 bytes
- App executable SHA-256: `4849f0d5bcfc1e43ad5ad53452f28c4ef1b0e1b3f0206cc32bd81d98fd912689`
- Product-source SHA-256: `e0cf86eca3f0113716b25055d991df31a4b8234181a45270a08a09b60ff8e400`

The IPA is unsigned and must be re-signed with the user's own Apple Account.
It does not include Donkey Kong 64, a ROM, extracted assets, generated private
inputs, saves, logs, a provisioning profile, or signing material. BananaPad
does not require JIT.

## Fixes

- Added a default-on touch Z lock. Hold Z continuously for one second to lock
  it; hold it again for one second to unlock it. The locked button remains
  visibly pressed and provides light haptic feedback.
- Added **Hold Z to Lock** under the three-dot menu's Settings sheet. Turning
  the setting off restores momentary-only Z behavior.
- Corrected the inherited audio queue-duration calculation to use the actual
  output device rate. The exercised DK64 path supplies 22.05 kHz audio while
  iOS outputs at 48 kHz; the old mismatch could trigger sample dropping at
  about 45.94 ms of real queued output instead of the intended 100 ms.
- Added bounded audio diagnostics for the requested/obtained format, queue
  depth, starvation, submission gaps, sample dropping, block boundaries, and
  conversion or queue errors.

## Verification

The device app passed the arm64 iPhoneOS, iOS 15, both-device-family, privacy,
ROM/save/private-data, signing-residue, personal-path, system-dependency, and
no-dynamic-code audits. Two independent deterministic package runs were
byte-for-byte identical, and ZIP integrity passed.

An extended Simulator run before the release-number-only rebuild observed 81
two-second audio windows with no sample dropping, no conversion/queue errors,
and no sustained queue starvation. Every window crossed the old effective
45.94 ms threshold, providing direct evidence that the prior calculation could
damage otherwise normal buffering.

## Retest requested

The Z-lock gesture and the audio fix still need reporter confirmation on a
physical iPhone. If an audible pop remains, reproduce it and immediately use
**••• → Share Diagnostics & Logs…** so the new audio telemetry can identify the
next failure mode. Review the report before attaching it, and never share ROMs,
saves, signing files, or other private data.
