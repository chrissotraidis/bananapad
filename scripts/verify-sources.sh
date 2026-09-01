#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

check_reference() {
  local path="$1"
  local expected="$2"
  local actual push_url dirty

  [[ -d "$path/.git" ]] || die "missing reference checkout: $path"
  actual="$(git -C "$path" rev-parse HEAD)"
  [[ "$actual" == "$expected" ]] || die "$path is at $actual, expected $expected"
  dirty="$(git -C "$path" status --porcelain --untracked-files=no)"
  [[ -z "$dirty" ]] || die "$path has tracked modifications"
  push_url="$(git -C "$path" remote get-url --push origin 2>/dev/null || true)"
  [[ "$push_url" == "DISABLED" ]] || die "$path push URL is not disabled"
  note "verified $path @ $actual"
}

check_reference "$BANANAPAD_ROOT/ref/dk64-recompiled" "$(lock_value '.references.dk64Recompiled.commit')"
check_reference "$BANANAPAD_ROOT/ref/paperpad" "$(lock_value '.references.paperpad.commit')"
check_reference "$BANANAPAD_ROOT/ref/paperpad/ref/SDL2" "$(lock_value '.references.sdl2.commit')"
check_reference "$BANANAPAD_ROOT/ref/sunpad" "$(lock_value '.references.sunpad.commit')"
check_reference "$BANANAPAD_ROOT/ref/toolchain/n64recomp-host" "$(lock_value '.references.n64RecompHostTools.commit')"

submodule_state="$(git -C "$BANANAPAD_ROOT/ref/dk64-recompiled" submodule status --recursive)"
if printf '%s\n' "$submodule_state" | grep -Eq '^[+-U]'; then
  die "DK64 recursive submodules are missing or do not match the promoted gitlinks"
fi

manifest_hash="$(printf '%s\n' "$submodule_state" | sed 's/^[ +-U]//' | LC_ALL=C sort | shasum -a 256 | awk '{print $1}')"
expected_manifest_hash="$(lock_value '.upstream.recursiveManifestSha256')"
[[ "$manifest_hash" == "$expected_manifest_hash" ]] || die "recursive manifest hash $manifest_hash does not match $expected_manifest_hash"

note "verified DK64 recursive manifest: $manifest_hash"

host_tool_state="$(git -C "$BANANAPAD_ROOT/ref/toolchain/n64recomp-host" submodule status --recursive)"
if printf '%s\n' "$host_tool_state" | grep -Eq '^[+-U]'; then
  die "N64Recomp host-tool submodules are missing or do not match the pinned gitlinks"
fi
host_tool_hash="$(printf '%s\n' "$host_tool_state" | sed 's/^[ +-U]//' | LC_ALL=C sort | shasum -a 256 | awk '{print $1}')"
expected_host_tool_hash="$(lock_value '.references.n64RecompHostTools.recursiveManifestSha256')"
[[ "$host_tool_hash" == "$expected_host_tool_hash" ]] || die "host-tool manifest hash $host_tool_hash does not match $expected_host_tool_hash"
note "verified N64Recomp host-tool manifest: $host_tool_hash"
