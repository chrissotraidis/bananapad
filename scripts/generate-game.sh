#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

"$BANANAPAD_ROOT/scripts/check-prerequisites.sh" >/dev/null
"$BANANAPAD_ROOT/scripts/verify-sources.sh" >/dev/null
"$BANANAPAD_ROOT/scripts/build-host-tools.sh" >/dev/null

upstream="${BANANAPAD_UPSTREAM_SOURCE:-$BANANAPAD_ROOT/ref/dk64-recompiled}"
decompressed_rom="${BANANAPAD_DECOMPRESSED_ROM:-$BANANAPAD_ROOT/generated/rom/donkeykong64.decompressed.us.z64}"
host_tools="${BANANAPAD_HOST_TOOLS:-$BANANAPAD_ROOT/generated/build/host-tools}"
n64recomp="$host_tools/N64Recomp"
rsprecomp="$host_tools/RSPRecomp"
aot_root="${BANANAPAD_AOT_ROOT:-$BANANAPAD_ROOT/generated/aot}"
sets_root="$aot_root/game-sets"

[[ -e "$upstream/.git" ]] || die "upstream source checkout is missing: $upstream"
[[ -f "$decompressed_rom" ]] || die "decompressed ROM is missing; run scripts/decompress-rom.sh first"
[[ -x "$n64recomp" && -x "$rsprecomp" ]] || die "host recompilers are missing: $host_tools"

identity="$({
  git -C "$upstream" rev-parse HEAD
  git -C "$BANANAPAD_ROOT/ref/toolchain/n64recomp-host" rev-parse HEAD
  shasum -a 256 "$n64recomp" "$rsprecomp" "$decompressed_rom" \
    "$upstream/us.toml" "$upstream/n_aspMain.toml" \
    "$upstream/DK64Syms/dump.toml" "$upstream/DK64Syms/data_dump.toml"
} | shasum -a 256 | awk '{print $1}')"

mkdir -p "$sets_root"
work_a="$(mktemp -d "$aot_root/.game-a.XXXXXX")"
work_b="$(mktemp -d "$aot_root/.game-b.XXXXXX")"
cleanup() {
  case "$work_a" in "$aot_root"/.game-a.*) ;; *) die "unsafe first generation cleanup path" ;; esac
  case "$work_b" in "$aot_root"/.game-b.*) ;; *) die "unsafe second generation cleanup path" ;; esac
  rm -rf -- "$work_a" "$work_b"
}
trap cleanup EXIT

generate_once() {
  local workspace="$1"
  cp "$upstream/us.toml" "$workspace/us.toml"
  cp "$upstream/n_aspMain.toml" "$workspace/n_aspMain.toml"
  ln -s "$upstream/DK64Syms" "$workspace/DK64Syms"
  ln -s "$decompressed_rom" "$workspace/donkeykong64.decompressed.us.z64"
  mkdir -p "$workspace/rsp"
  (cd "$workspace" && "$n64recomp" us.toml && "$rsprecomp" n_aspMain.toml)
  unlink "$workspace/DK64Syms"
  unlink "$workspace/donkeykong64.decompressed.us.z64"
  (
    cd "$workspace"
    find RecompiledFuncs rsp -type f -print | LC_ALL=C sort | while IFS= read -r path; do
      printf '%s  %s\n' "$(shasum -a 256 "$path" | awk '{print $1}')" "$path"
    done
  ) >"$workspace/manifest.sha256"
  printf '%s\n' "$identity" >"$workspace/input-identity.sha256"
}

generate_once "$work_a"
generate_once "$work_b"
cmp -s "$work_a/manifest.sha256" "$work_b/manifest.sha256" || die "game/RSP generation is not deterministic"

set_dir="$sets_root/$identity"
if [[ -e "$set_dir" ]]; then
  cmp -s "$work_a/manifest.sha256" "$set_dir/manifest.sha256" || die "existing game set does not match regenerated output: $identity"
else
  mv "$work_a" "$set_dir"
fi
ln -sfn "game-sets/$identity" "$aot_root/current-game"

note "input-identity=$identity"
note "game-files=$(find "$set_dir/RecompiledFuncs" -type f | wc -l | tr -d ' ')"
note "game-manifest-sha256=$(shasum -a 256 "$set_dir/manifest.sha256" | awk '{print $1}')"
note "rsp-sha256=$(shasum -a 256 "$set_dir/rsp/n_aspMain.cpp" | awk '{print $1}')"
note "deterministic=yes"
