#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

[[ $# -ge 1 && $# -le 2 ]] \
  || die "usage: $0 <device-uuid-or-name> [--install]"
device="$1"
mode="${2:-}"
[[ -z "$mode" || "$mode" == "--install" ]] \
  || die "second argument must be --install"

require_command codesign
require_command jq
require_command plutil
require_command xcrun

app="${BANANAPAD_DEVICE_APP:-$BANANAPAD_ROOT/generated/build/bananapad-ios-device/Release/BananaPad.app}"
executable="$app/BananaPad"
[[ -x "$executable" ]] || die "device app is missing; build a signed device app first"

codesign --verify --deep --strict "$app" \
  || die "device app is not validly signed; rebuild with BANANAPAD_DEVELOPMENT_TEAM"
"$BANANAPAD_ROOT/scripts/audit-ios-package.sh" "$app"

signing_details="$(codesign -dvv "$app" 2>&1)"
signing_team="$(printf '%s\n' "$signing_details" | sed -n 's/^TeamIdentifier=//p' | head -n 1)"
[[ -n "$signing_team" && "$signing_team" != "not set" ]] \
  || die "signed app does not expose an Apple team identifier"

bundle_id="$(plutil -extract CFBundleIdentifier raw "$app/Info.plist")"
[[ "$bundle_id" == "com.chrissotraidis.bananapad" ]] || die "unexpected bundle identifier"

timestamp="$(date -u '+%Y%m%dT%H%M%SZ')"
executable_hash="$(shasum -a 256 "$executable" | awk '{print $1}')"
receipt_root="${BANANAPAD_PHYSICAL_RECEIPT_ROOT:-$BANANAPAD_ROOT/generated/validation/physical-device}"
receipt_dir="$receipt_root/$timestamp-${executable_hash:0:12}"
mkdir -p "$receipt_dir"
device_json="$receipt_dir/device-details.json"

xcrun devicectl device info details \
  --device "$device" \
  --timeout 30 \
  --quiet \
  --json-output "$device_json"
jq -e '.info.outcome == "success" and (.result | type == "object")' "$device_json" >/dev/null \
  || die "devicectl did not resolve the requested physical device"

installed=false
if [[ "$mode" == "--install" ]]; then
  "$BANANAPAD_ROOT/scripts/install-bananapad-ios-device.sh" "$device" --launch
  installed=true
fi

bundle_manifest_hash="$({
  cd "$(dirname "$app")"
  find "$(basename "$app")" -type f -print0 \
    | LC_ALL=C sort -z \
    | while IFS= read -r -d '' file_path; do
        printf '%s\n' "$file_path"
        shasum -a 256 "$file_path"
      done
} | shasum -a 256 | awk '{print $1}')"

lock_hash="$(shasum -a 256 "$BANANAPAD_LOCK" | awk '{print $1}')"
patch_hash="$(patch_series_hash)"
product_hash="$(product_source_hash)"
root_revision="$(git -C "$BANANAPAD_ROOT" rev-parse HEAD)"
root_state_hash="$(git -C "$BANANAPAD_ROOT" status --porcelain=v1 --untracked-files=all | shasum -a 256 | awk '{print $1}')"

jq -n \
  --arg schema "bananapad-physical-preflight-v1" \
  --arg createdAt "$timestamp" \
  --arg requestedDevice "$device" \
  --arg bundleIdentifier "$bundle_id" \
  --arg signingTeam "$signing_team" \
  --arg appPath "$app" \
  --arg executableSha256 "$executable_hash" \
  --arg bundleManifestSha256 "$bundle_manifest_hash" \
  --arg dependencyLockSha256 "$lock_hash" \
  --arg patchSeriesSha256 "$patch_hash" \
  --arg productSourceSha256 "$product_hash" \
  --arg rootRevision "$root_revision" \
  --arg rootStateSha256 "$root_state_hash" \
  --argjson installedAndLaunched "$installed" \
  --slurpfile deviceDetails "$device_json" \
  '{
    schema: $schema,
    createdAt: $createdAt,
    requestedDevice: $requestedDevice,
    installedAndLaunched: $installedAndLaunched,
    app: {
      path: $appPath,
      bundleIdentifier: $bundleIdentifier,
      signingTeam: $signingTeam,
      executableSha256: $executableSha256,
      bundleManifestSha256: $bundleManifestSha256
    },
    source: {
      rootRevision: $rootRevision,
      rootStateSha256: $rootStateSha256,
      dependencyLockSha256: $dependencyLockSha256,
      patchSeriesSha256: $patchSeriesSha256,
      productSourceSha256: $productSourceSha256
    },
    deviceDetails: $deviceDetails[0].result,
    decision: "pending-hands-on-acceptance"
  }' > "$receipt_dir/preflight.json"

cat > "$receipt_dir/ACCEPTANCE.md" <<EOF
# BananaPad physical acceptance — $timestamp

Preflight receipt: preflight.json

Executable SHA-256: $executable_hash

Bundle-manifest SHA-256: $bundle_manifest_hash

Signing team: $signing_team

Requested device: $device

Record Pass, Fail, or Not run for every item. Attach screenshots, recordings,
diagnostics, save hashes, and Instruments exports in this directory. Do not
convert a Simulator result or a different binary into evidence for this receipt.

## Identity and first launch

- [ ] App icon is legible and correct in the active appearance.
- [ ] Package contains no ROM; owned DK64 US 1.0 ROM imports through the three-dot menu.
- [ ] First launch reaches playable original/stable mode.
- [ ] Existing/later-game save or fixture loads without corruption.

## Touch and persistent three-dot menu

- [ ] Stick, A, B, Z, L, R, Start, D-pad, and every C direction are reachable.
- [ ] Independent-finger Z+A and Z+B chords work.
- [ ] Independent-finger Z+C-Up, Z+C-Down, Z+C-Left, and Z+C-Right chords work.
- [ ] Slide-in/out, cancellation, and both landscapes leave no held input.
- [ ] Persistent three-dot menu remains available and clears gameplay input.
- [ ] Settings, layout edit/reset, diagnostics, ROM management, and Done work.
- [ ] Device-specific opacity/layout settings persist after relaunch and respect safe areas.

## Physical controller

- [ ] Connect gives the controller P1 and hides only gameplay touch controls.
- [ ] Both sticks, face/shoulder buttons, Start, D-pad, and camera mapping work.
- [ ] Disconnect while held returns to neutral and restores touch controls.
- [ ] Reconnect reclaims P1 without duplicated or stuck input.

## Lifecycle, audio, saves, and sustained operation

- [ ] Background/foreground clears input during gameplay, menu, Settings, and ROM management.
- [ ] Speaker, headphones, Bluetooth, route changes, volume, and interruptions recover cleanly.
- [ ] Save writes, app termination/relaunch, and visible reload pass; before/after save hashes recorded.
- [ ] At least 30 minutes on this form factor passes without corruption, stuck input, or sustained audio faults.
- [ ] Required 90-minute release soak records memory, thermal state, battery, audio, and rendering observations.

## Result

Tester: ____________________

Device/OS: ____________________

Start/end time: ____________________

Save hash before/after: ____________________

Defects/evidence paths: ____________________

Decision: **PENDING**
EOF

note "physical-device preflight created: $receipt_dir/preflight.json"
note "hands-on worksheet created: $receipt_dir/ACCEPTANCE.md"
if [[ "$installed" == false ]]; then
  note "preflight only; rerun with --install to install and launch this exact signed app"
fi
