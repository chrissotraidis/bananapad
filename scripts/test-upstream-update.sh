#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

candidate="$BANANAPAD_ROOT/worktrees/dk64-upstream-candidate"
state_dir="$BANANAPAD_ROOT/generated/upstream"
metadata="$state_dir/candidate.json"
result_file="$state_dir/candidate-test.json"
qualification_file="$state_dir/candidate-qualification.json"
baseline_app="$BANANAPAD_ROOT/generated/build/upstream-macos-1.0.1/DK64Recompiled.app"
candidate_app="$BANANAPAD_ROOT/generated/build/bananapad-ios-candidate/Release/BananaPad.app"
simulator_receipt_dir="$BANANAPAD_ROOT/generated/validation/ios-simulator-runs"
simulator_receipt=""

[[ -d "$candidate/.git" ]] || die "no staged candidate"
[[ -f "$metadata" ]] || die "candidate metadata is missing"

expected_commit="$(jq -er '.commit' "$metadata")"
actual_commit="$(git -C "$candidate" rev-parse HEAD)"
[[ "$actual_commit" == "$expected_commit" ]] || die "candidate checkout does not match metadata"
[[ "$(patch_series_hash)" == "$(jq -er '.patchSeriesSha256' "$metadata")" ]] || die "patch series changed after staging"
product_hash="$(product_source_hash)"
[[ "$product_hash" == "$(jq -er '.productSourceSha256' "$metadata")" ]] || die "BananaPad product source changed after staging"

generated_commit="$(jq -er '.generated.upstreamCommit' "$metadata")"
[[ "$generated_commit" == "$actual_commit" ]] || die "candidate generated inputs are for a different upstream commit"
generated_game_set="$(jq -er '.generated.gameSet' "$metadata")"
generated_patch_set="$(jq -er '.generated.patchSet' "$metadata")"
generated_rom="$(jq -er '.generated.decompressedRom' "$metadata")"
game_manifest_hash="$(jq -er '.generated.gameManifestSha256' "$metadata")"
patch_manifest_hash="$(jq -er '.generated.patchManifestSha256' "$metadata")"
decompressed_rom_hash="$(jq -er '.generated.decompressedRomSha256' "$metadata")"
[[ -f "$generated_game_set/manifest.sha256" && "$(shasum -a 256 "$generated_game_set/manifest.sha256" | awk '{print $1}')" == "$game_manifest_hash" ]] || die "candidate game generation evidence changed"
[[ -f "$generated_patch_set/manifest.sha256" && "$(shasum -a 256 "$generated_patch_set/manifest.sha256" | awk '{print $1}')" == "$patch_manifest_hash" ]] || die "candidate patch generation evidence changed"
[[ -f "$generated_rom" && "$(shasum -a 256 "$generated_rom" | awk '{print $1}')" == "$decompressed_rom_hash" ]] || die "candidate decompressed ROM evidence changed"

for patch_dir in upstream bananapad; do
  for patch_file in "$BANANAPAD_ROOT"/patches/"$patch_dir"/*.patch; do
    [[ -e "$patch_file" ]] || continue
    git -C "$candidate" apply --reverse --check "$patch_file" || die "recorded patch is not applied exactly: $patch_file"
  done
done

manifest="$(recursive_manifest_hash "$candidate")"
[[ "$manifest" == "$(jq -er '.recursiveManifestSha256' "$metadata")" ]] || die "candidate recursive manifest changed"
worktree_hash="$(recursive_worktree_hash "$candidate")"
[[ "$worktree_hash" == "$(jq -er '.recursiveWorktreeSha256' "$metadata")" ]] || die "candidate recursive worktree changed"
BANANAPAD_WORKSPACE="$candidate" "$BANANAPAD_ROOT/scripts/test-renderer-task-order-contract.sh" >/dev/null
"$BANANAPAD_ROOT/scripts/test-paperpad-ui-fidelity.sh" >/dev/null
"$BANANAPAD_ROOT/scripts/test-touch-input-contract.sh" >/dev/null
"$BANANAPAD_ROOT/scripts/test-rom-management-contract.sh" >/dev/null

promoted="$(lock_value '.upstream.promoted.commit')"
tested_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
result="needs-full-validation"
reason="candidate differs from promoted; regenerate, build, audit, play, and verify save/config compatibility before promotion"

[[ -x "$candidate_app/BananaPad" ]] || die "clean candidate Simulator app is missing"
codesign --verify --deep --strict "$candidate_app"
[[ "$(plutil -extract CFBundleIdentifier raw "$candidate_app/Info.plist")" == "com.chrissotraidis.bananapad" ]] || die "candidate Simulator bundle identifier is invalid"
file "$candidate_app/BananaPad" | grep -q 'arm64' || die "candidate Simulator executable is not arm64"
candidate_app_hash="$(shasum -a 256 "$candidate_app/BananaPad" | awk '{print $1}')"
"$BANANAPAD_ROOT/scripts/audit-ios-package.sh" "$candidate_app" >/dev/null

if [[ "$actual_commit" == "$promoted" ]]; then
  [[ "$manifest" == "$(lock_value '.upstream.recursiveManifestSha256')" ]] || die "same-pin recursive manifest differs from the promoted lock"
  [[ -d "$baseline_app" ]] || die "same-pin baseline app is missing"
  "$BANANAPAD_ROOT/scripts/audit-upstream-baseline.sh" --source-artifact-only >/dev/null
  result="pass"
  reason="same-pin rehearsal matches the promoted source/manifest; the clean iOS/iPadOS candidate builds and its exact PaperPad UI, touch, three-dot menu, ROM-management, renderer, package, and archived baseline contracts pass without replaying DK64 gameplay"
else
  expected_rom_sha1="$(lock_value '.rom.sha1')"
  if [[ -d "$simulator_receipt_dir" ]]; then
    while IFS= read -r receipt_candidate; do
      if jq -e \
        --arg commit "$actual_commit" \
        --arg worktree_hash "$worktree_hash" \
        --arg app "$candidate_app" \
        --arg app_hash "$candidate_app_hash" \
        --arg product_hash "$product_hash" \
        --arg game_manifest_hash "$game_manifest_hash" \
        --arg patch_manifest_hash "$patch_manifest_hash" \
        --arg decompressed_rom_hash "$decompressed_rom_hash" \
        --arg rom_sha1 "$expected_rom_sha1" \
        '.result == "pass" and .commit == $commit and .recursiveWorktreeSha256 == $worktree_hash and .productSourceSha256 == $product_hash and .generatedGameManifestSha256 == $game_manifest_hash and .generatedPatchManifestSha256 == $patch_manifest_hash and .decompressedRomSha256 == $decompressed_rom_hash and .app == $app and .appExecutableSha256 == $app_hash and .romSha1 == $rom_sha1 and .smokeSeconds >= 20' \
        "$receipt_candidate" >/dev/null; then
        simulator_receipt="$receipt_candidate"
        break
      fi
    done < <(find "$simulator_receipt_dir" -maxdepth 1 -type f -name "$candidate_app_hash-$worktree_hash-*.json" -print | LC_ALL=C sort -r)
  fi
fi

if [[ "$actual_commit" != "$promoted" && -f "$simulator_receipt" && -f "$qualification_file" ]] && jq -e \
  --arg commit "$actual_commit" \
  --arg manifest "$manifest" \
  --arg worktree_hash "$worktree_hash" \
  --arg product_hash "$product_hash" \
  --arg game_manifest_hash "$game_manifest_hash" \
  --arg patch_manifest_hash "$patch_manifest_hash" \
  --arg decompressed_rom_hash "$decompressed_rom_hash" \
  --arg app_hash "$candidate_app_hash" \
  --arg receipt "$simulator_receipt" \
  '.schemaVersion == 1 and .result == "pass"
   and .commit == $commit
   and .recursiveManifestSha256 == $manifest
   and .recursiveWorktreeSha256 == $worktree_hash
   and .productSourceSha256 == $product_hash
   and .generatedGameManifestSha256 == $game_manifest_hash
   and .generatedPatchManifestSha256 == $patch_manifest_hash
   and .decompressedRomSha256 == $decompressed_rom_hash
   and .appExecutableSha256 == $app_hash
   and .simulatorReceipt == $receipt
   and .checks.patchReplay == "pass"
   and .checks.deterministicGeneration == "pass"
   and .checks.macosGameplay == "pass"
   and .checks.ipadTouchGameplay == "pass"
   and .checks.saveReload == "pass"
   and .checks.settingsCompatibility == "pass"
   and .checks.audits == "pass"
   and (.evidence | type == "array" and length > 0 and all(.[]; type == "string" and length > 0))
   and (.qualifiedBy | type == "string" and length > 0)' "$qualification_file" >/dev/null; then
  result="pass"
  reason="new upstream candidate has exact build/Simulator evidence plus a complete, identity-bound gameplay, save, settings, and audit qualification record"
fi

tmp="$(mktemp "$state_dir/candidate-test.XXXXXX")"
jq -n \
  --arg commit "$actual_commit" \
  --arg manifest "$manifest" \
  --arg worktree_hash "$worktree_hash" \
  --arg product_hash "$product_hash" \
  --arg result "$result" \
  --arg reason "$reason" \
  --arg simulator_receipt "$simulator_receipt" \
  --arg tested_at "$tested_at" \
  '{schemaVersion:2,commit:$commit,recursiveManifestSha256:$manifest,recursiveWorktreeSha256:$worktree_hash,productSourceSha256:$product_hash,result:$result,reason:$reason,simulatorReceipt:$simulator_receipt,testedAt:$tested_at}' > "$tmp"
chmod 600 "$tmp"
mv "$tmp" "$result_file"

tmp="$(mktemp "$state_dir/candidate.XXXXXX")"
jq --slurpfile test "$result_file" '.test = $test[0]' "$metadata" > "$tmp"
chmod 600 "$tmp"
mv "$tmp" "$metadata"

note "candidate test: $result"
note "$reason"
[[ "$result" == "pass" ]] || exit 2
