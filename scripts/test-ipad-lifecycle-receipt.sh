#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

receipt="$BANANAPAD_ROOT/generated/validation/ipad-lifecycle-last-run.json"
app="$BANANAPAD_ROOT/generated/build/bananapad-ios-simulator/Release/BananaPad.app"
evidence="$BANANAPAD_ROOT/generated/evidence/g10/ipad-lifecycle-20260901"

[[ -f "$receipt" ]] || die "iPad lifecycle receipt is missing"
[[ -x "$app/BananaPad" ]] || die "receipt-bound Simulator app is missing"
jq -e '
  .result == "pass" and
  .observed.backgroundForegroundCycles >= 3 and
  .observed.terminateRelaunchCycles >= 3 and
  .observed.terminateRelaunchInitializationSurvival == "pass" and
  .observed.newCrashReports == 0 and
  .observed.menuOpenBackgroundForeground == "pass" and
  .observed.nativeSettingsOpenBackgroundForeground == "pass" and
  .observed.touchOverlayRestoredAfterSettingsDone == "pass" and
  .observed.renderingResumedAfterEachCycle == "pass" and
  .observed.landscapeLeft == "pass" and
  .observed.landscapeRight == "pass" and
  .observed.oneSimulatorAtATime == true
' "$receipt" >/dev/null || die "iPad lifecycle receipt is incomplete"

expected_executable="$(jq -r '.executableSHA256' "$receipt")"
actual_executable="$(shasum -a 256 "$app/BananaPad" | awk '{print $1}')"
[[ "$actual_executable" == "$expected_executable" ]] \
  || die "iPad lifecycle executable identity changed"
[[ "$(jq -r '.productSourceSHA256' "$receipt")" == "$(product_source_hash)" ]] \
  || die "iPad lifecycle product-source identity changed"

check_evidence() {
  local json_key="$1"
  local filename="$2"
  local expected actual
  expected="$(jq -r --arg key "$json_key" '.evidence[$key]' "$receipt")"
  [[ "$expected" != null && -n "$expected" ]] || die "missing evidence hash: $json_key"
  [[ -f "$evidence/$filename" ]] || die "missing lifecycle evidence: $filename"
  actual="$(shasum -a 256 "$evidence/$filename" | awk '{print $1}')"
  [[ "$actual" == "$expected" ]] || die "lifecycle evidence changed: $filename"
}

check_evidence menuOpenSHA256 menu-open.png
check_evidence foregroundMenuSHA256 foreground-menu.png
check_evidence cycle2RenderResumedSHA256 cycle-2-render-resumed.png
check_evidence cycle3RenderResumedSHA256 cycle-3-render-resumed.png
check_evidence settingsForegroundRestoredSHA256 settings-foreground-restored.png
check_evidence settingsDoneOverlayRestoredSHA256 settings-done-overlay-restored.png
check_evidence landscapeLeftSHA256 landscape-left.png
check_evidence landscapeRightSHA256 landscape-right.png

note "iPad lifecycle receipt: pass"
