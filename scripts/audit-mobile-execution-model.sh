#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

require_command jq
require_command python3
require_command rg
require_command shasum

workspace="${BANANAPAD_WORKSPACE:-$BANANAPAD_ROOT/worktrees/bananapad-static-macos}"
mac_app="${BANANAPAD_MACOS_APP:-$BANANAPAD_ROOT/generated/build/bananapad-static-macos/BananaPad.app}"
receipt="$BANANAPAD_ROOT/generated/validation/ios-simulator-last-run.json"
default_sim_app="$BANANAPAD_ROOT/generated/build/bananapad-ios-simulator/Release/BananaPad.app"
if [[ -z "${BANANAPAD_SIMULATOR_APP:-}" && -f "$receipt" ]]; then
  default_sim_app="$(jq -er 'select(.result == "pass") | .app' "$receipt")"
  case "$default_sim_app" in
    "$BANANAPAD_ROOT"/generated/build/*/Release/BananaPad.app) ;;
    *) die "Simulator smoke receipt names an unsafe app path" ;;
  esac
fi
sim_app="${BANANAPAD_SIMULATOR_APP:-$default_sim_app}"
mac_build_dir="${BANANAPAD_MACOS_BUILD_DIR:-$BANANAPAD_ROOT/generated/build/bananapad-static-macos}"
default_sim_build_dir="${sim_app%/Release/BananaPad.app}"
[[ "$default_sim_build_dir" != "$sim_app" ]] || die "Simulator app must be a Release/BananaPad.app build artifact"
sim_build_dir="${BANANAPAD_SIMULATOR_BUILD_DIR:-$default_sim_build_dir}"

[[ -e "$workspace/.git" ]] || die "prepared BananaPad worktree is missing"
[[ -d "$mac_app" ]] || die "hardened macOS app is missing"
[[ -d "$sim_app" ]] || die "Simulator app is missing"
[[ -f "$mac_build_dir/CMakeCache.txt" ]] || die "macOS build cache is missing"
[[ -f "$sim_build_dir/CMakeCache.txt" ]] || die "Simulator build cache is missing"

"$BANANAPAD_ROOT/scripts/verify-sources.sh" >/dev/null
"$BANANAPAD_ROOT/scripts/generate-execution-manifests.py"

for manifest in \
  "$BANANAPAD_ROOT/docs/OVERLAYS.json" \
  "$BANANAPAD_ROOT/docs/AOT-PATCH-MANIFEST.json" \
  "$BANANAPAD_ROOT/docs/RSP-MANIFEST.json" \
  "$BANANAPAD_ROOT/docs/SAVE-MANIFEST.json"; do
  jq empty "$manifest"
done

[[ "$(jq '.sections | length' "$BANANAPAD_ROOT/docs/OVERLAYS.json")" == 12 ]] || die "unexpected AOT section count"
[[ "$(jq '[.sections[] | select(.compressedRomTrigger)] | length' "$BANANAPAD_ROOT/docs/OVERLAYS.json")" == 10 ]] || die "compressed overlay manifest is incomplete"
[[ "$(jq '[.sections[] | select(.sharedReplacementBoundary == true)] | length' "$BANANAPAD_ROOT/docs/OVERLAYS.json")" == 9 ]] || die "shared overlay replacement boundary changed"

[[ "$(jq '.generated.generatedFunctionCount' "$BANANAPAD_ROOT/docs/AOT-PATCH-MANIFEST.json")" == 221 ]] || die "generated patch function inventory changed"
[[ "$(jq '.generated.replacementFunctions | length' "$BANANAPAD_ROOT/docs/AOT-PATCH-MANIFEST.json")" == 158 ]] || die "replacement patch inventory changed"
[[ "$(jq '.generated.eventFunctions | length' "$BANANAPAD_ROOT/docs/AOT-PATCH-MANIFEST.json")" == 11 ]] || die "patch event-stub inventory changed"
[[ "$(jq '.generated.events | length' "$BANANAPAD_ROOT/docs/AOT-PATCH-MANIFEST.json")" == 10 ]] || die "registered base-event inventory changed"
[[ "$(jq '.generated.manualHostFunctions | length' "$BANANAPAD_ROOT/docs/AOT-PATCH-MANIFEST.json")" == 71 ]] || die "manual host-function inventory changed"

jq -e '.textOffset == "0x02146010" and .textSize == "0x00000C30" and .textAddress == "0x04001080" and .outputFunction == "n_aspMain" and .acceptedTaskType == "M_AUDTASK" and .hleFallback == false' \
  "$BANANAPAD_ROOT/docs/RSP-MANIFEST.json" >/dev/null || die "RSP contract changed"
jq -e '.saveType == "Eep16k" and .hostLengthBytes == 2048 and .blockSizeBytes == 8 and .controllerPak.symbolicReturn == "PFS_ERR_NOPACK"' \
  "$BANANAPAD_ROOT/docs/SAVE-MANIFEST.json" >/dev/null || die "save/accessory contract changed"

rg -q 'N64MODERN_NO_DYNAMIC_CODE:BOOL=ON' "$mac_build_dir/CMakeCache.txt" || die "macOS static build cache is not no-dynamic-code"
rg -q 'N64MODERN_NO_DYNAMIC_CODE:BOOL=ON' "$sim_build_dir/CMakeCache.txt" || die "Simulator build cache is not no-dynamic-code"

if rg -n --glob 'link.txt' --glob 'project.pbxproj' \
  '(segprot[^\n]*__TEXT[^\n]*(rwx|0x7)|-allow_stack_execute|custom.?ld64)' \
  "$mac_build_dir" \
  "$sim_build_dir"; then
  die "writable-text or custom-linker route found"
fi

"$BANANAPAD_ROOT/scripts/check-no-dynamic-code.sh" "$mac_app"
"$BANANAPAD_ROOT/scripts/check-no-dynamic-code.sh" "$sim_app"
"$BANANAPAD_ROOT/scripts/audit-ios-package.sh" "$sim_app"

[[ -f "$receipt" ]] || die "Simulator smoke receipt is missing"
jq -e --arg app "$sim_app" --arg product_hash "$(product_source_hash)" \
  '.result == "pass" and .app == $app and .productSourceSha256 == $product_hash and .smokeSeconds >= 20 and .romSha1 == "cf806ff2603640a748fca5026ded28802f1f4a50"' \
  "$receipt" >/dev/null || die "Simulator smoke receipt does not match this app/ROM"
[[ "$(shasum -a 256 "$sim_app/BananaPad" | awk '{print $1}')" == "$(jq -r '.appExecutableSha256' "$receipt")" ]] || \
  die "Simulator executable changed after the passing smoke test"

note "mobile execution-model audit passed"
