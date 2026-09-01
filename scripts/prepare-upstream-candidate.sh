#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

candidate="$BANANAPAD_ROOT/worktrees/dk64-upstream-candidate"
state_dir="$BANANAPAD_ROOT/generated/upstream"
metadata="$state_dir/candidate.json"
qualification="$state_dir/candidate-qualification.json"
inputs_root="$state_dir/candidate-inputs"
normalized_rom="$BANANAPAD_ROOT/generated/rom/donkeykong64.us.z64"
decompressed_rom="$inputs_root/rom/donkeykong64.decompressed.us.z64"
aot_root="$inputs_root/aot"
decompressor_build="$inputs_root/build/dk64-decompressor"

[[ -e "$candidate/.git" && -f "$metadata" ]] || die "stage an upstream candidate first"
[[ -f "$normalized_rom" ]] || die "verified normalized ROM is missing; run prepare-rom.sh first"

commit="$(jq -er '.commit' "$metadata")"
[[ "$(git -C "$candidate" rev-parse HEAD)" == "$commit" ]] || die "candidate checkout does not match metadata"
[[ "$(recursive_worktree_hash "$candidate")" == "$(jq -er '.recursiveWorktreeSha256' "$metadata")" ]] || die "candidate worktree changed after staging"
[[ "$(patch_series_hash)" == "$(jq -er '.patchSeriesSha256' "$metadata")" ]] || die "patch series changed after staging"
[[ "$(product_source_hash)" == "$(jq -er '.productSourceSha256' "$metadata")" ]] || die "product source changed after staging"

BANANAPAD_UPSTREAM_SOURCE="$candidate" \
BANANAPAD_NORMALIZED_ROM="$normalized_rom" \
BANANAPAD_DECOMPRESSED_ROM="$decompressed_rom" \
BANANAPAD_DECOMPRESSOR_BUILD_DIR="$decompressor_build" \
  "$BANANAPAD_ROOT/scripts/decompress-rom.sh"

BANANAPAD_UPSTREAM_SOURCE="$candidate" \
BANANAPAD_DECOMPRESSED_ROM="$decompressed_rom" \
BANANAPAD_AOT_ROOT="$aot_root" \
  "$BANANAPAD_ROOT/scripts/generate-game.sh"

BANANAPAD_UPSTREAM_SOURCE="$candidate" \
BANANAPAD_AOT_ROOT="$aot_root" \
  "$BANANAPAD_ROOT/scripts/generate-patches.sh"

game_set="$(cd "$aot_root" && pwd)/current-game"
patch_set="$(cd "$aot_root" && pwd)/current-patches"
game_manifest="$(shasum -a 256 "$game_set/manifest.sha256" | awk '{print $1}')"
patch_manifest="$(shasum -a 256 "$patch_set/manifest.sha256" | awk '{print $1}')"
rom_sha256="$(shasum -a 256 "$decompressed_rom" | awk '{print $1}')"
prepared_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

tmp="$(mktemp "$state_dir/candidate.XXXXXX")"
jq \
  --arg decompressed_rom "$decompressed_rom" \
  --arg rom_sha256 "$rom_sha256" \
  --arg game_set "$game_set" \
  --arg game_manifest "$game_manifest" \
  --arg patch_set "$patch_set" \
  --arg patch_manifest "$patch_manifest" \
  --arg prepared_at "$prepared_at" \
  '.schemaVersion = 3
   | .generated = {
       upstreamCommit:.commit,
       decompressedRom:$decompressed_rom,
       decompressedRomSha256:$rom_sha256,
       gameSet:$game_set,
       gameManifestSha256:$game_manifest,
       patchSet:$patch_set,
       patchManifestSha256:$patch_manifest,
       preparedAt:$prepared_at
     }
   | .test = null' "$metadata" > "$tmp"
chmod 600 "$tmp"
mv "$tmp" "$metadata"
[[ ! -e "$qualification" ]] || mv "$qualification" "$state_dir/candidate-qualification.invalidated.$(date -u '+%Y%m%dT%H%M%SZ').json"

note "candidate generated inputs prepared for $commit"
note "decompressed ROM SHA-256: $rom_sha256"
note "game manifest SHA-256: $game_manifest"
note "patch manifest SHA-256: $patch_manifest"
note "metadata: $metadata"
