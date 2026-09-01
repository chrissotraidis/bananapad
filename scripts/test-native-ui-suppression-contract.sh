#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

monitor="$BANANAPAD_ROOT/apple/app/native_ui_state.mm"
native="$BANANAPAD_ROOT/apple/core/bananapad_native.cpp"
patch="$BANANAPAD_ROOT/patches/bananapad/bananapad-integration.patch"

for source_file in "$monitor" "$native" "$patch"; do
  [[ -f "$source_file" ]] || die "native-UI suppression input is missing: $source_file"
done

rg -q 'UIApplicationWillResignActiveNotification' "$monitor" \
  || die "inactive transition does not synchronously suppress input"
rg -q 'applicationState != UIApplicationStateActive' "$monitor" \
  || die "inactive application state is not suppressed"
rg -q 'application\.connectedScenes' "$monitor" \
  || die "native-UI detection does not inspect active window scenes"
rg -q 'rootViewController\.presentedViewController != nil' "$monitor" \
  || die "presented native UI is not detected"
rg -q 'BananaPad_IsNativeUIInputSuppressed' "$native" \
  || die "game input adapter does not consume native-UI state"
rg -q '\*buttons = 0;' "$native" \
  || die "suppressed controller buttons are not cleared"
rg -q 'controller_requires_neutral' "$native" \
  || die "controller input does not require a neutral state after native UI"
rg -q 'controller_is_neutral' "$native" \
  || die "controller neutral-rearm check is missing"
rg -q 'native_ui_state\.mm' "$patch" \
  || die "iOS build does not compile the native-UI monitor"

note "native UI/controller suppression contract: pass"
