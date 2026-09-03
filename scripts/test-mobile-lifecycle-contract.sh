#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

uikit_events="$BANANAPAD_ROOT/ref/paperpad/ref/SDL2/src/video/uikit/SDL_uikitevents.m"
core_audio="$BANANAPAD_ROOT/ref/paperpad/ref/SDL2/src/audio/coreaudio/SDL_coreaudio.m"
touch_ui="$BANANAPAD_ROOT/apple/app/ios_main.mm"
native="$BANANAPAD_ROOT/apple/core/bananapad_native.cpp"
audio_sink="${BANANAPAD_WORKSPACE:-$BANANAPAD_ROOT/worktrees/bananapad-static-macos}/src/main/main.cpp"

for source_file in "$uikit_events" "$core_audio" "$touch_ui" "$native" "$audio_sink"; do
  [[ -f "$source_file" ]] || die "mobile lifecycle input is missing: $source_file"
done

for notification in \
  UIApplicationWillResignActiveNotification \
  UIApplicationDidEnterBackgroundNotification \
  UIApplicationWillEnterForegroundNotification \
  UIApplicationDidBecomeActiveNotification \
  UIApplicationDidReceiveMemoryWarningNotification; do
  rg -q "$notification" "$uikit_events" \
    || die "SDL UIKit lifecycle observer is missing $notification"
done

rg -q 'SDL_OnApplicationDidReceiveMemoryWarning' "$uikit_events" \
  || die "iOS memory warning is not forwarded to SDL"
rg -q 'AVAudioSessionInterruptionNotification' "$core_audio" \
  || die "SDL CoreAudio interruption observer is missing"
rg -q 'AudioQueuePause' "$core_audio" \
  || die "SDL CoreAudio does not pause for interruptions"
rg -q 'AudioQueueStart' "$core_audio" \
  || die "SDL CoreAudio does not restart after interruptions"
rg -q 'applicationBecameActive' "$core_audio" \
  || die "SDL CoreAudio lacks foreground recovery for omitted interruption-end events"

rg -q 'UIApplicationWillResignActiveNotification' "$touch_ui" \
  || die "touch UI does not observe application deactivation"
rg -q '_touchRoles\.clear\(\)' "$touch_ui" \
  || die "touch ownership is not cleared at lifecycle boundaries"
rg -q 'g_touch_taps\.clearAll\(\)' "$touch_ui" \
  || die "latched touch taps are not cleared at lifecycle boundaries"
rg -q 'SDL_APP_DIDENTERFOREGROUND' "$native" \
  || die "controller ownership is not reconciled on foreground return"
rg -q 'controller_requires_neutral' "$native" \
  || die "controller input is not neutral-gated across lifecycle boundaries"

rg -q 'queued_audio_microseconds\(\)' "$audio_sink" \
  || die "the native audio sink does not measure output queue duration"
rg -q 'queued_frames \* 1000000 / output_sample_rate' "$audio_sink" \
  || die "queued output audio is not converted with the output sample rate"
rg -q 'decimation_events' "$audio_sink" \
  || die "the upstream sample-dropping path is not instrumented"
rg -q 'prequeue_zero' "$audio_sink" \
  || die "audio queue starvation is not instrumented"
rg -q 'boundary_peak_ppm' "$audio_sink" \
  || die "audio block-boundary discontinuities are not instrumented"

note "mobile lifecycle/audio substrate contract: pass"
