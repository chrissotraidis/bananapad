#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

require_command clang++
require_command rg

ui="$BANANAPAD_ROOT/apple/app/ios_main.mm"
native="$BANANAPAD_ROOT/apple/core/bananapad_native.cpp"
test_source="$BANANAPAD_ROOT/scripts/test-touch-tap-latch.cpp"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/bananapad-touch-test.XXXXXX")"
cleanup() {
  [[ "$test_dir" == "${TMPDIR:-/tmp}/bananapad-touch-test."* ]] || die "refusing unsafe touch-test cleanup path"
  rm -rf "$test_dir"
}
trap cleanup EXIT

clang++ -std=c++20 -Wall -Wextra -Werror "$test_source" -o "$test_dir/touch-tap-latch-test"
"$test_dir/touch-tap-latch-test"

for binding in \
  '"d_up".*0x0800' '"d_down".*0x0400' '"d_left".*0x0200' '"d_right".*0x0100' \
  '"c_up".*0x0008' '"c_down".*0x0004' '"c_left".*0x0002' '"c_right".*0x0001' \
  '"a".*0x8000' '"b".*0x4000' '"z".*0x2000' '"l".*0x0020' \
  '"r".*0x0010' '"start".*0x1000'; do
  rg -q "$binding" "$ui" || die "missing N64 touch binding: $binding"
done

rg -q 'self\.multipleTouchEnabled = YES' "$ui" || die "multi-touch is not enabled"
rg -q 'std::unordered_map<UITouch\*, int> _touchRoles' "$ui" || die "touches are not tracked independently"
rg -q 'g_touch_buttons\.load.*\|' "$ui" || die "held and latched touch buttons are not combined"
rg -q 'g_touch_taps\.clearAll\(\)' "$ui" || die "touch latches are not released on input clear"
rg -q 'kZLockHoldSeconds = 1\.0' "$ui" || die "Z lock does not use the one-second hold contract"
rg -q 'if \(_zLocked\) buttons \|= kZButtonMask' "$ui" || die "locked Z is not published to the N64 input snapshot"
rg -q '_zLocked = NO' "$ui" || die "locked Z is not cleared at safety boundaries"
rg -q 'Hold Z to Lock' "$ui" || die "the default-on Z lock setting is missing"
rg -q 'settings\[@"zLockEnabled"\] == nil \|\|' "$ui" || die "Z lock is not enabled by default"
rg -q 'Hold Z to lock:' "$BANANAPAD_ROOT/apple/app/diagnostics.mm" || die "diagnostics omit the Z-lock preference"
rg -q 'UIApplicationWillResignActiveNotification' "$ui" || die "background input release is missing"
rg -q 'out_buttons \|= touch_buttons' "$native" || die "touch buttons are not merged with other input"
rg -q 'PaperPad_SetPhysicalControllerConnected\(controller != nullptr \? 1 : 0\)' "$native" \
  || die "physical-controller connect/disconnect is not forwarded to the touch overlay"
rg -q 'PaperPad_SetPhysicalControllerConnected\(1\)' "$native" \
  || die "an already-attached controller is not forwarded to the touch overlay"
rg -q 'std::clamp\(out_x, -1\.0f, 1\.0f\)' "$native" || die "combined touch/controller X is not clamped"
rg -q 'std::clamp\(out_y, -1\.0f, 1\.0f\)' "$native" || die "combined touch/controller Y is not clamped"

note "touch input contract: pass"
