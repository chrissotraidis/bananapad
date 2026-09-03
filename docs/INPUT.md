# BananaPad input inventory

## Baseline native mappings

The macOS native runner retains PaperPad's keyboard mapping: Z/X are N64 A/B, Return is Start, left Shift is Z, Q/E are L/R, I/K/J/L are the C buttons, W/S/A/D are the D-pad, and the arrow keys are the analog stick. Physical controllers and the Apple touch shell feed the same N64 button/axis snapshot rather than a separate gameplay implementation.

## iPhone and iPad touch controls

The Apple shell keeps PaperPad's pinned N64 overlay presentation while adapting its input behavior for DK64. It exposes the analog stick, D-pad, A, B, Z, L, R, Start, and all four C directions. Phone and tablet defaults are independent, safe-area aware, locally persistent, editable, and resettable. Each `UITouch` owns its own role, so holding Z while pressing A, B, or a C direction does not serialize or release the first finger. Short taps are latched long enough for the emulated input poll to observe them. Holding Z continuously for one second toggles a visible Z lock; holding it again unlocks it. The `Hold Z to Lock` setting is on by default and can be disabled from the three-dot menu's Settings sheet.

The persistent three-dot button remains available while gameplay controls are hidden. Opening the menu, Settings, layout editor, diagnostics, or ROM manager suppresses gameplay input and clears held and Z-locked touch state. Backgrounding, interruption, cancellation, orientation changes, runtime stop, and physical-controller transitions also clear state. The SDL controller adapter forwards its actual attached-controller state to `PaperPad_SetPhysicalControllerConnected`; Simulator's synthetic MFi controller is deliberately ignored by the PaperPad source so automated touch checks remain possible.

Observed on exact executable `77d18de47a9e5ac6fb0239d6703aba5f8048a34826c12f60c2271e272b0bb3fd`: both iPad and compact iPhone touch Start/A created Game 1, reached treehouse gameplay, moved DK with the virtual stick, jumped with A, attacked with B, wrote 2,048-byte saves, and visibly restored their files after terminate/relaunch. On iPad, Z visibly crouched; C-left/right rotated the original camera; C-up/down changed camera distance; R recentered the camera; and Home→foreground after a B tap resumed with DK idle rather than replaying held input. In the Training Grounds pool, B produced the forward swim stroke and virtual-stick direction steered DK along the bank. L is reachable and contract-proven but has no visible baseline effect at this early DK state. On iPhone the editor opened and returned through Reset/Done, Home→foreground resume restored the live overlay, and both landscape orientations reflowed the complete control set within the safe area. The compiled contract covers all masks and simultaneous ownership; physical multi-finger chords and real-controller handoff remain hands-on acceptance items.

## Desktop acceptance aliases

Accessibility-backed Computer Use can press a key but cannot keep a modifier-only key held across calls. Native macOS acceptance runs may therefore set `BANANAPAD_TEST_KEY_TAP_FRAMES` to an integer from 1 through 240 before launch:

- T/G/F/H emit four-frame up/down/left/right analog taps for bounded navigation.
- 1/2/3/4 emit up/down/left/right analog input for the requested number of frames.
- 5/6/7/8 atomically emit A plus up/down/left/right analog input for the requested number of frames.
- 9/0/-/= atomically hold A for the requested duration while tapping up/down/left/right analog input for four frames. These provide a long jump with a precise directional correction for floating-barrel entry.
- U emits N64 A for the requested number of input frames.
- V emits N64 Z for the requested number of input frames.
- the ordinary arrow-key analog bindings use the requested duration.

The digit aliases exist because the accessibility bridge rejects the documented arrow-key spellings; they are not user-facing controls. The seam is deliberately absent from iOS/iPadOS. It is inactive when the variable is absent, empty, invalid, outside 1–240, or resolves to the normal four-frame duration. Normal macOS controls remain four-frame keyboard taps. These aliases are an acceptance transport only: evidence must still show the unmodified game route and must reject debugger-induced clock catch-up in timed challenges.

Run `scripts/test-native-input-contract.sh` after editing the native input adapter.
Run `scripts/test-paperpad-ui-fidelity.sh` and `scripts/test-touch-input-contract.sh` after editing the Apple touch/controller boundary.
