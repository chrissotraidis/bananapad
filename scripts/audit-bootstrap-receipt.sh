#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

receipt="${1:-$BANANAPAD_ROOT/generated/validation/bootstrap-last-run.json}"
[[ -f "$receipt" ]] || die "bootstrap receipt is missing: $receipt"
jq -e '.schemaVersion == 2 and .result == "pass"' "$receipt" >/dev/null || \
  die "bootstrap receipt has an unsupported schema or failed result"

target="$(jq -r '.target' "$receipt")"
case "$target" in prepare|macos|ios|simulator|device|all) ;; *) die "bootstrap receipt has an invalid target: $target" ;; esac

assert_receipt_value() {
  local field="$1"
  local expected="$2"
  local actual
  actual="$(jq -r --arg field "$field" '.[$field]' "$receipt")"
  [[ "$actual" == "$expected" ]] || die "bootstrap receipt $field mismatch: expected $expected, found $actual"
}

assert_file_hash() {
  local path_field="$1"
  local hash_field="$2"
  local executable_suffix="${3:-}"
  local path expected actual
  path="$(jq -r --arg field "$path_field" '.[$field]' "$receipt")"
  expected="$(jq -r --arg field "$hash_field" '.[$field]' "$receipt")"
  [[ -n "$path" && "$path" != null && -n "$expected" && "$expected" != null ]] || \
    die "bootstrap receipt is missing $path_field/$hash_field"
  case "$path" in "$BANANAPAD_ROOT"/generated/*) ;; *) die "bootstrap receipt points outside generated/: $path" ;; esac
  [[ -e "$path$executable_suffix" ]] || die "bootstrap receipt artifact is missing: $path$executable_suffix"
  actual="$(shasum -a 256 "$path$executable_suffix" | awk '{print $1}')"
  [[ "$actual" == "$expected" ]] || die "bootstrap artifact hash mismatch: $path$executable_suffix"
}

assert_empty_pair() {
  local path_field="$1"
  local hash_field="$2"
  [[ "$(jq -r --arg field "$path_field" '.[$field]' "$receipt")" == "" ]] || \
    die "bootstrap receipt unexpectedly binds $path_field for target $target"
  [[ "$(jq -r --arg field "$hash_field" '.[$field]' "$receipt")" == "" ]] || \
    die "bootstrap receipt unexpectedly binds $hash_field for target $target"
}

assert_receipt_value upstreamCommit "$(lock_value '.upstream.promoted.commit')"
assert_receipt_value productSourceSha256 "$(product_source_hash)"
assert_receipt_value romSha1 "$(lock_value '.rom.sha1')"
assert_receipt_value generatedGameManifestSha256 "$(shasum -a 256 "$BANANAPAD_ROOT/generated/aot/current-game/manifest.sha256" | awk '{print $1}')"
assert_receipt_value generatedPatchManifestSha256 "$(shasum -a 256 "$BANANAPAD_ROOT/generated/aot/current-patches/manifest.sha256" | awk '{print $1}')"

if [[ "$target" == prepare ]]; then
  assert_empty_pair macosApp macosExecutableSha256
else
  assert_file_hash macosApp macosExecutableSha256 /Contents/MacOS/BananaPad
fi

if [[ "$target" == ios || "$target" == simulator || "$target" == all ]]; then
  assert_file_hash iosSimulatorApp iosSimulatorExecutableSha256 /BananaPad
else
  assert_empty_pair iosSimulatorApp iosSimulatorExecutableSha256
fi

if [[ "$target" == device || "$target" == all ]]; then
  assert_file_hash iosDeviceApp iosDeviceExecutableSha256 /BananaPad
  assert_file_hash unsignedIpa unsignedIpaSha256
  "$BANANAPAD_ROOT/scripts/audit-ios-package.sh" "$(jq -r '.iosDeviceApp' "$receipt")" >/dev/null
  "$BANANAPAD_ROOT/scripts/audit-ios-package.sh" "$(jq -r '.unsignedIpa' "$receipt")" >/dev/null
else
  assert_empty_pair iosDeviceApp iosDeviceExecutableSha256
  assert_empty_pair unsignedIpa unsignedIpaSha256
fi

note "bootstrap receipt audit: pass ($target)"
