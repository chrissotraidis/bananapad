#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

rom_path=""
target="all"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --rom)
      [[ $# -ge 2 ]] || die "--rom requires an absolute path"
      rom_path="$2"
      shift 2
      ;;
    --target)
      [[ $# -ge 2 ]] || die "--target requires prepare, macos, simulator, device, or all"
      target="$2"
      shift 2
      ;;
    *) die "usage: scripts/bootstrap-bananapad.sh --rom /absolute/path/to/private-rom [--target prepare|macos|ios|simulator|device|all]" ;;
  esac
done

[[ -n "$rom_path" && "$rom_path" = /* && -f "$rom_path" ]] || \
  die "provide the absolute path to a legally obtained DK64 US 1.0 ROM with --rom"
case "$target" in prepare|macos|ios|simulator|device|all) ;; *) die "--target must be prepare, macos, simulator, device, or all" ;; esac

"$BANANAPAD_ROOT/scripts/check-prerequisites.sh"
"$BANANAPAD_ROOT/scripts/clone-sources.sh"
"$BANANAPAD_ROOT/scripts/check-repo-safety.sh"
normalized_rom="$BANANAPAD_ROOT/generated/rom/donkeykong64.us.z64"
if [[ -f "$normalized_rom" && "$rom_path" -ef "$normalized_rom" ]]; then
  [[ "$(stat -f '%z' "$normalized_rom")" == "$(lock_value '.rom.size')" ]] || die "cached normalized ROM has the wrong size"
  [[ "$(shasum -a 1 "$normalized_rom" | awk '{print $1}')" == "$(lock_value '.rom.sha1')" ]] || die "cached normalized ROM has the wrong SHA-1"
  note "reusing the already-verified private normalized ROM"
else
  "$BANANAPAD_ROOT/scripts/prepare-rom.sh" --rom "$rom_path"
fi
"$BANANAPAD_ROOT/scripts/build-host-tools.sh"
"$BANANAPAD_ROOT/scripts/decompress-rom.sh"
"$BANANAPAD_ROOT/scripts/generate-game.sh"
"$BANANAPAD_ROOT/scripts/generate-patches.sh"

mac_app=""
ios_app=""
device_app=""
ipa=""
if [[ "$target" != prepare ]]; then
  "$BANANAPAD_ROOT/scripts/build-bananapad-static-macos.sh"
  mac_app="$BANANAPAD_ROOT/generated/build/bananapad-static-macos/BananaPad.app"
  "$BANANAPAD_ROOT/scripts/check-no-dynamic-code.sh" "$mac_app"
fi

if [[ "$target" == ios || "$target" == simulator || "$target" == all ]]; then
  "$BANANAPAD_ROOT/scripts/build-bananapad-ios-simulator.sh" --build
  ios_app="$BANANAPAD_ROOT/generated/build/bananapad-ios-simulator/Release/BananaPad.app"
  "$BANANAPAD_ROOT/scripts/check-no-dynamic-code.sh" "$ios_app"
  "$BANANAPAD_ROOT/scripts/audit-ios-package.sh" "$ios_app"
fi

if [[ "$target" == device || "$target" == all ]]; then
  "$BANANAPAD_ROOT/scripts/build-bananapad-ios-device.sh"
  device_app="$BANANAPAD_ROOT/generated/build/bananapad-ios-device/Release/BananaPad.app"
  "$BANANAPAD_ROOT/scripts/package-unsigned-ipa.sh" "$device_app"
  ipa="$BANANAPAD_ROOT/generated/packages/BananaPad-v0.1.0-preview.3-unsigned.ipa"
fi

receipt_dir="$BANANAPAD_ROOT/generated/validation"
receipt="$receipt_dir/bootstrap-last-run.json"
mkdir -p "$receipt_dir"
mac_hash=""
ios_hash=""
device_hash=""
ipa_hash=""
[[ -z "$mac_app" ]] || mac_hash="$(shasum -a 256 "$mac_app/Contents/MacOS/BananaPad" | awk '{print $1}')"
[[ -z "$ios_app" ]] || ios_hash="$(shasum -a 256 "$ios_app/BananaPad" | awk '{print $1}')"
[[ -z "$device_app" ]] || device_hash="$(shasum -a 256 "$device_app/BananaPad" | awk '{print $1}')"
[[ -z "$ipa" ]] || ipa_hash="$(shasum -a 256 "$ipa" | awk '{print $1}')"
tmp="$(mktemp "$receipt_dir/bootstrap-last-run.XXXXXX")"
jq -n \
  --arg target "$target" \
  --arg upstream_commit "$(lock_value '.upstream.promoted.commit')" \
  --arg product_hash "$(product_source_hash)" \
  --arg rom_sha1 "$(lock_value '.rom.sha1')" \
  --arg game_manifest_hash "$(shasum -a 256 "$BANANAPAD_ROOT/generated/aot/current-game/manifest.sha256" | awk '{print $1}')" \
  --arg patch_manifest_hash "$(shasum -a 256 "$BANANAPAD_ROOT/generated/aot/current-patches/manifest.sha256" | awk '{print $1}')" \
  --arg mac_app "$mac_app" \
  --arg mac_hash "$mac_hash" \
  --arg ios_app "$ios_app" \
  --arg ios_hash "$ios_hash" \
  --arg device_app "$device_app" \
  --arg device_hash "$device_hash" \
  --arg ipa "$ipa" \
  --arg ipa_hash "$ipa_hash" \
  --arg completed_at "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
  '{schemaVersion:2,result:"pass",target:$target,upstreamCommit:$upstream_commit,productSourceSha256:$product_hash,romSha1:$rom_sha1,generatedGameManifestSha256:$game_manifest_hash,generatedPatchManifestSha256:$patch_manifest_hash,macosApp:$mac_app,macosExecutableSha256:$mac_hash,iosSimulatorApp:$ios_app,iosSimulatorExecutableSha256:$ios_hash,iosDeviceApp:$device_app,iosDeviceExecutableSha256:$device_hash,unsignedIpa:$ipa,unsignedIpaSha256:$ipa_hash,completedAt:$completed_at}' > "$tmp"
chmod 600 "$tmp"
mv "$tmp" "$receipt"
"$BANANAPAD_ROOT/scripts/audit-bootstrap-receipt.sh" "$receipt"

note "BananaPad bootstrap complete: $target"
note "receipt: $receipt"
[[ -z "$mac_app" ]] || note "macOS app: $mac_app"
[[ -z "$ios_app" ]] || note "iOS/iPadOS Simulator app: $ios_app"
[[ -z "$device_app" ]] || note "unsigned iOS/iPadOS device app: $device_app"
[[ -z "$ipa" ]] || note "ROM-free unsigned IPA: $ipa"
note "No Simulator was booted or launched; runtime receipt validation begins with build-bananapad-ios-simulator.sh --run on exactly one booted target."
