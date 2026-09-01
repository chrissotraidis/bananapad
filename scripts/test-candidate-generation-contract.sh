#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

for script in decompress-rom.sh generate-game.sh generate-patches.sh; do
  rg -q 'BANANAPAD_UPSTREAM_SOURCE' "$BANANAPAD_ROOT/scripts/$script" || \
    die "$script is not candidate-source aware"
done

rg -q 'BANANAPAD_AOT_ROOT' "$BANANAPAD_ROOT/scripts/generate-game.sh" || die "game generation has no isolated AOT root"
rg -q 'BANANAPAD_AOT_ROOT' "$BANANAPAD_ROOT/scripts/generate-patches.sh" || die "patch generation has no isolated AOT root"

for variable in BANANAPAD_EXPECTED_COMMIT BANANAPAD_GAME_SET BANANAPAD_PATCH_SET BANANAPAD_DECOMPRESSED_ROM BANANAPAD_FILE_TO_C BANANAPAD_SPIRV_CROSS_MSL; do
  rg -q "$variable" "$BANANAPAD_ROOT/scripts/build-upstream-candidate.sh" || \
    die "candidate build does not bind $variable"
done

rg -q 'upstreamCommit:.commit' "$BANANAPAD_ROOT/scripts/prepare-upstream-candidate.sh" || \
  die "candidate generated inputs are not bound to the staged commit"
rg -q 'gameManifestSha256' "$BANANAPAD_ROOT/scripts/prepare-upstream-candidate.sh" || \
  die "candidate game manifest evidence is missing"
rg -q 'patchManifestSha256' "$BANANAPAD_ROOT/scripts/prepare-upstream-candidate.sh" || \
  die "candidate patch manifest evidence is missing"
for field in generatedGameManifestSha256 generatedPatchManifestSha256 decompressedRomSha256; do
  rg -q "$field" "$BANANAPAD_ROOT/scripts/build-bananapad-ios-simulator.sh" || \
    die "Simulator receipt does not bind $field"
  rg -q "$field" "$BANANAPAD_ROOT/scripts/test-upstream-update.sh" || \
    die "candidate test does not validate $field"
done

note "candidate generation contract: pass"
