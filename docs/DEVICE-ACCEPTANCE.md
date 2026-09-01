# BananaPad physical-device acceptance

Use this checklist only after the exact candidate is installed on one physical device at a time. Simulator evidence already accepts boot, gameplay, touch layout, save/reload, and lifecycle resume; this pass is for behavior Simulator automation cannot establish honestly.

Create an artifact-bound private receipt and worksheet before each device pass:

```sh
scripts/preflight-bananapad-device-acceptance.sh DEVICE-UDID --install
```

The command rejects an invalid signature, re-audits the ROM-free package, resolves the explicitly named physical device, installs/launches only when `--install` is supplied, and writes `preflight.json` plus `ACCEPTANCE.md` under ignored `generated/validation/physical-device/`. Use a separate receipt for iPad and iPhone. A preflight decision is always `pending-hands-on-acceptance`; only observed results may change the documented G12 decision.

## Candidate identity

- Record the source revision, `dependencies.lock.json` SHA-256, product-source SHA-256, signed app/IPA SHA-256, bundle identifier, signing team, iOS/iPadOS version, and device model.
- Verify the app contains no ROM and imports only the user-owned DK64 US 1.0 ROM.
- Confirm the home-screen icon is BananaPad's bundled AppIcon and is legible in the device's active appearance.
- Test iPad and iPhone sequentially. Do not keep a Simulator or second game instance running during save evidence.

## Touch and three-dot menu

1. Import/verify the ROM, reach gameplay, and confirm stick, A, B, Z, R, Start, every C direction, L, and D-pad are reachable.
2. With independent fingers, verify Z+A, Z+B, Z+C-Up, Z+C-Down, Z+C-Left, and Z+C-Right. Held Z must remain active while the second control changes.
3. Slide into and out of the stick/buttons; cancel touches; rotate between both landscape orientations; confirm no control remains held.
4. Open the persistent three-dot menu during gameplay. Gameplay controls must hide, held input must clear, and Settings, layout edit/reset, diagnostics, ROM management, and Done must work.
5. Adjust opacity and layout, relaunch, and confirm the device-specific layout persists without moving controls outside the safe area.

## Controller ownership

1. Connect one supported controller during gameplay. It must own P1, hide touch gameplay controls when configured, and leave the three-dot menu available.
2. Exercise both sticks, A/B, Z/L/R, Start, D-pad, and C/right-stick camera behavior.
3. Disconnect while holding an input. DK must return to idle and touch controls must return without restarting the game.
4. Reconnect and confirm the sole controller reclaims P1 with no duplicated or stuck input.

## Lifecycle, audio, and persistence

1. Background/foreground during idle movement, a held button, menu display, Settings, and ROM management. Every return must clear stale input and restore the correct UI.
2. Exercise speaker, headphones, Bluetooth audio, interruption, route change, and volume changes without losing or duplicating audio.
3. Create or advance a save, terminate the app, relaunch, and visibly reload it. Record the 2,048-byte save hash before and after.
4. Run at least 30 minutes on each form factor and the later 90-minute release soak. Record thermal state, memory warnings/termination, audio underruns, rendering corruption, and battery behavior.

## Evidence and decision

Store screenshots, screen recordings, diagnostics, hashes, and the completed matrix under the private dated evidence path. Record pass/fail per row in `docs/JOURNAL.md` and update `docs/STATUS.md`. Physical acceptance does not authorize publication; G13 rights and release approval remain separate.
