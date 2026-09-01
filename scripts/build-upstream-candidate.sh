#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

mode="${1:---build}"
[[ "$mode" == "--build" || "$mode" == "--run" || "$mode" == "--smoke" ]] || \
  die "use --build, --run, or --smoke"

candidate="$BANANAPAD_ROOT/worktrees/dk64-upstream-candidate"
metadata="$BANANAPAD_ROOT/generated/upstream/candidate.json"
mac_build="$BANANAPAD_ROOT/generated/build/bananapad-macos-candidate"
ios_build="$BANANAPAD_ROOT/generated/build/bananapad-ios-candidate"

[[ -e "$candidate/.git" && -f "$metadata" ]] || die "stage an upstream candidate first"
[[ "$(product_source_hash)" == "$(jq -er '.productSourceSha256' "$metadata")" ]] || \
  die "BananaPad product source changed after candidate staging"
if [[ "$(jq -r '.generated.upstreamCommit // empty' "$metadata")" != "$(jq -er '.commit' "$metadata")" ]]; then
  "$BANANAPAD_ROOT/scripts/prepare-upstream-candidate.sh"
fi

commit="$(jq -er '.commit' "$metadata")"
game_set="$(jq -er '.generated.gameSet' "$metadata")"
patch_set="$(jq -er '.generated.patchSet' "$metadata")"
decompressed_rom="$(jq -er '.generated.decompressedRom' "$metadata")"

BANANAPAD_MACOS_PROFILE=static \
BANANAPAD_EXPECTED_COMMIT="$commit" \
BANANAPAD_WORKSPACE="$candidate" \
BANANAPAD_BUILD_DIR="$mac_build" \
BANANAPAD_GAME_SET="$game_set" \
BANANAPAD_PATCH_SET="$patch_set" \
BANANAPAD_DECOMPRESSED_ROM="$decompressed_rom" \
  "$BANANAPAD_ROOT/scripts/build-bananapad-macos.sh"

file_to_c="$mac_build/file_to_c"
spirv_cross_msl="$candidate/build/bin/spirv_cross_msl"
[[ -x "$file_to_c" && -x "$spirv_cross_msl" ]] || die "candidate-native RT64 host tools were not produced"

BANANAPAD_EXPECTED_COMMIT="$commit" \
BANANAPAD_WORKSPACE="$candidate" \
BANANAPAD_BUILD_DIR="$ios_build" \
BANANAPAD_GAME_SET="$game_set" \
BANANAPAD_PATCH_SET="$patch_set" \
BANANAPAD_DECOMPRESSED_ROM="$decompressed_rom" \
BANANAPAD_FILE_TO_C="$file_to_c" \
BANANAPAD_SPIRV_CROSS_MSL="$spirv_cross_msl" \
  "$BANANAPAD_ROOT/scripts/build-bananapad-ios-simulator.sh" "$mode"
