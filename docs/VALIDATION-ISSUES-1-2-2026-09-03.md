# Issues #1 and #2 validation — 2026-09-03

This pass implements the default-on one-second Z lock requested in Issue #2 and corrects the audio queue-duration unit mismatch implicated by Issue #1. It adds bounded audio telemetry without replacing DK64Recompiled's resampler or claiming physical-device audible acceptance.

## Z lock

- `Hold Z to Lock` is present in the three-dot menu's Settings sheet and defaults to on when no preference exists.
- A continuous one-second Z touch toggles the active lock. A second one-second hold toggles it off. Short taps and ordinary holds retain their existing behavior.
- Opening native UI, disabling touch controls, connecting a controller, cancelling input, or resigning active clears the active lock through the existing `clearInput` boundary. The saved feature preference remains unchanged.
- The locked Z control remains visually pressed and a light haptic marks each toggle.
- On the iPhone 17 Pro Max Simulator, accessibility exposed the switch with value `1`; changing it to `0` and back to `1` applied and restored the setting.

The touch, native-settings, native-UI suppression, and mobile-lifecycle contracts pass. The actual timed touch gesture and Z-modified gameplay chords still require physical touch acceptance.

## Audio finding and correction

`SDL_GetQueuedAudioSize` returns bytes in the device's output format. The inherited catch-up calculation divided those bytes by the game's input sample rate. The exercised runtime reported 22,050 Hz input and 48,000 Hz output, so the nominal 100 ms threshold activated at:

`100 ms × 22,050 / 48,000 = 45.9375 ms`

The sink now calculates queue duration from the 48 kHz output rate. It retains the upstream catch-up valve but records every activation, along with the actual SDL format, submission gaps, queue minimum/peak, starvation counts, boundary/within-block sample deltas, and conversion/queue errors.

## Simulator evidence

- Target: iPhone 17 Pro Max Simulator, iOS 26.5.
- App executable SHA-256: `1d2df153054b6a2e5c4a46b6f36d9d1043c4c2ac17fe1cd035db9536a7330bdb`.
- Smoke receipt worktree SHA-256: `52feca0132d8b270d014429ad06ccfbf9d12305fdfb1d9fecd2bd1003f1e748e`.
- SDL: CoreAudio, requested/obtained 48,000 Hz stereo, 256 samples.
- 81 approximately two-second telemetry windows contained 4,908 submissions, 3,608,056 input frames, and 7,854,032 output frames.
- Maximum queue depth: 79.708 ms. Every window crossed the old effective 45.94 ms threshold.
- Decimation events: 0. Queue/conversion errors: 0. Over-100-ms submissions: 0.
- One startup submission saw an empty/under-5-ms prequeue; no later window did.
- Maximum submission gap: 47.629 ms.
- Maximum block-boundary delta: 0.086400; maximum within-block delta: 0.137027. No boundary exceeded the run's ordinary within-block maximum.
- The process remained alive through the extended run and was then terminated normally; the Simulator was returned to its original shutdown state.

This is strong structural evidence that the old rate mismatch repeatedly exposed normal queue levels to sample dropping and that the corrected build avoids that path. It is not evidence that a human can no longer hear a pop on the reporter's iPhone 15 Pro Max. The remaining acceptance step is an in-place physical-iPhone build and listening retest, followed by a shared diagnostics report if any pop remains.
