#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

[[ $# -ge 1 && $# -le 2 ]] \
  || die "usage: $0 <device-uuid-or-name> [--launch]"
device="$1"
mode="${2:-}"
[[ -z "$mode" || "$mode" == "--launch" ]] \
  || die "second argument must be --launch"

app="${BANANAPAD_DEVICE_APP:-$BANANAPAD_ROOT/generated/build/bananapad-ios-device/Release/BananaPad.app}"
[[ -d "$app" ]] || die "device app is missing; run build-bananapad-ios-device.sh first"
codesign --verify --deep --strict "$app" \
  || die "device app is not validly signed; rebuild with BANANAPAD_DEVELOPMENT_TEAM"
"$BANANAPAD_ROOT/scripts/audit-ios-package.sh" "$app"

xcrun devicectl device install app --device "$device" "$app"
if [[ "$mode" == "--launch" ]]; then
  xcrun devicectl device process launch \
    --terminate-existing \
    --device "$device" \
    com.chrissotraidis.bananapad
fi

note "installed BananaPad on device: $device"
