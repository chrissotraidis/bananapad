# iPadOS Simulator validation — 2026-08-31

## Result

BananaPad builds as an arm64 iOS Simulator app, installs and launches on an iPad Pro Simulator on this Apple Silicon Mac, loads the locked Donkey Kong 64 US 1.0 ROM, renders DK64 through RT64/Metal, and remains live with PaperPad's touch overlay and three-dot menu.

## Exact environment and artifact

- Simulator: iPad Pro 13-inch (M5), iOS 26.5, arm64.
- Bundle identifier: `com.chrissotraidis.bananapad`.
- Deployment target: iOS 15.0.
- Build profile: Release, iPhone Simulator SDK, no dynamic code.
- Repeatable command: `scripts/build-bananapad-ios-simulator.sh --run`.
- Existing-artifact smoke command: `scripts/build-bananapad-ios-simulator.sh --smoke`.
- Verified private ROM identity: 33,554,432 bytes, SHA-1 `cf806ff2603640a748fca5026ded28802f1f4a50`.

## Failures found and repaired

1. Plume called the macOS-only Metal device-location selector in Simulator. The iOS path now reports an integrated device without sending that selector.
2. Simulator Metal rejected RT64's optional debug pipeline because it used 52 buffers where Simulator supports 31. The exact PaperPad Simulator guard now excludes that unused pipeline.
3. Simulator Metal rejected RT64 raster pipelines because they declared 18 samplers where Simulator supports 16. The exact PaperPad iOS software-sampling path now emits no native sampler slots.
4. RT64's generated shaders did not track included `.hlsli` files, so the first incremental build retained stale Metal bytecode. A forced shader regeneration proved the corrected Metal output before relaunch.
5. Simulator returned a null timestamp counter result from `MTLCounterSampleBuffer`. Plume now leaves zeroed timing results intact instead of copying from null.

## UI and interaction evidence

- `generated/evidence/bananapad-ios-simulator/dk64-touch-overlay.png`: live DK64 with the PaperPad N64 overlay and persistent three-dot control.
- `generated/evidence/bananapad-ios-simulator/three-dot-menu.png`: the three-dot menu open over the live game.
- `generated/evidence/bananapad-ios-simulator/paperpad-settings.png`: native PaperPad Settings opened from that menu.
- `generated/evidence/bananapad-ios-simulator/reproducible-script-run.png`: a subsequent build/install/ROM/launch performed by the checked-in script.
- `generated/evidence/bananapad-ios-simulator/clean-candidate-run.png`: DK64 rendering from a fresh isolated upstream candidate after zero-fuzz patch replay.

The native Master Volume slider was changed from 100% to 55%, observed through accessibility state, restored to 100%, and the sheet was closed with its Done button. The touch overlay returned over the still-running game. This establishes real native event delivery, not screenshot-only similarity.

## Clean-candidate proof

The complete BananaPad delta was consolidated into `patches/bananapad/bananapad-integration.patch` and replayed, with the Xcode 26 compatibility patch, against a fresh isolated checkout of upstream `1.0.1` / `c6730d2f244d7b2d9d8c47c94c2eecfa1bfb1a43`. Patch application passed exact forward and reverse checks with no fuzz. The recursively bound candidate worktree SHA-256 was `47bb6c525e5b0936092e53aecda66fb8d480be4199dd38031f774e97c184f224`; the complete patch-series SHA-256 was `c5fe24f048fc3c9452ec19d2ecfef471f76a2820c213695288c332fc8a35f632`.

The clean Xcode build succeeded and produced an arm64 Simulator executable with SHA-256 `b3812118d108c8fae67c9643d0597c7dd5b3cb6dc1a887e1825a412332e79fde`. Generated `RasterPSDynamic.hlsl.metal` contains none of the prohibited native sampler declarations. The app was ad-hoc signed, installed, supplied the exact locked ROM, launched, remained registered through a 20-second initialization window, and visibly rendered DK64 with the touch overlay. The machine-readable receipt is ignored at `generated/validation/ios-simulator-last-run.json`; the screenshot SHA-256 is `42e60b2dd74f691e698a4da9c02a72f22e50f343fe1d48050a1a78cc1927a975`.

## Scope

This validates local Simulator build, installation, launch, Metal execution, ROM loading, UI presence, menu/settings interaction, and repeatability. It does not substitute for physical-device thermal, memory, audio, lifecycle, controller, or signing acceptance.
