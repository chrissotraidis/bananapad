# BananaPad v0.1.0-preview.3

Developer Preview 3 is a focused response to the physical-iPhone feedback on
Issue #2. It remains a ROM-free unsigned arm64 IPA for iOS and iPadOS 15 or
newer and includes the Preview 2 audio correction.

## Assets

- `BananaPad-v0.1.0-preview.3-unsigned.ipa`
- `BananaPad-v0.1.0-preview.3-unsigned.ipa.sha256`
- SHA-256: `ad8efa113b34d3cb80ca330a9fbb8a67297245b6b5ad78f7e0af9aeb48cd882f`
- Size: 7,479,560 bytes
- App executable SHA-256: `8d7085f3082ab0647257bd5d2ea785fd47002c6b8d00e111727f7bd6b6e59e40`
- Product-source SHA-256: `b4b4fc8dec848055b84ca265094db13be96feaaaaf9a5a4c022062737ce04b1e`

The IPA is unsigned and must be re-signed with the user's own Apple Account.
It does not include Donkey Kong 64, a ROM, extracted assets, generated private
inputs, saves, logs, a provisioning profile, or signing material. BananaPad
does not require JIT.

## Z-lock timing adjustment

- Engaging Z lock now takes 0.75 seconds instead of one second.
- Releasing an active Z lock now takes 0.35 seconds, making it deliberately
  faster than engagement in response to the reporter's feedback.
- The default-on Settings switch, visible locked state, light haptic, normal
  short taps, and safety clearing behavior are unchanged.

## Verification

The adjusted timing and state selection pass the touch-input contract. The
device and Simulator targets compile as build 3. The device app passes the
arm64 iPhoneOS, iOS 15, both-device-family, privacy, ROM/save/private-data,
signing-residue, personal-path, system-dependency, and no-dynamic-code audits.
Two independent deterministic package runs are byte-for-byte identical, and
ZIP integrity passes.

## Retest requested

Please test both directions on a physical iPhone: hold Z for 0.75 seconds to
lock it, then hold it for 0.35 seconds to release it. Issue #2 remains open
until the reporter confirms that both timings feel right.
