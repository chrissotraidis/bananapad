#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

require_command jq
require_command shasum

evidence_file="${1:-}"
[[ -n "$evidence_file" && -f "$evidence_file" ]] || \
  die "use: scripts/qualify-upstream-candidate.sh /absolute/path/to/review-evidence.json"

state_dir="$BANANAPAD_ROOT/generated/upstream"
metadata="$state_dir/candidate.json"
test_record="$state_dir/candidate-test.json"
qualification="$state_dir/candidate-qualification.json"
candidate="$BANANAPAD_ROOT/worktrees/dk64-upstream-candidate"
candidate_app="$BANANAPAD_ROOT/generated/build/bananapad-ios-candidate/Release/BananaPad.app"

[[ -f "$metadata" && -f "$test_record" && -e "$candidate/.git" ]] || \
  die "stage, prepare, build, smoke, and run test-upstream-update.sh first"
[[ "$(jq -er '.result' "$test_record")" == "needs-full-validation" ]] || \
  die "candidate is not awaiting a full-validation record"

for check in patchReplay deterministicGeneration macosGameplay ipadTouchGameplay saveReload settingsCompatibility audits; do
  [[ "$(jq -r --arg check "$check" '.checks[$check] // empty' "$evidence_file")" == "pass" ]] || \
    die "review evidence must record checks.$check as pass"
done
jq -e '.result == "pass"
  and (.qualifiedBy | type == "string" and length > 0)
  and (.evidence | type == "array" and length > 0 and all(.[]; type == "string" and length > 0))' \
  "$evidence_file" >/dev/null || die "review evidence requires result=pass, qualifiedBy, and non-empty evidence paths/notes"

commit="$(jq -er '.commit' "$metadata")"
manifest="$(jq -er '.recursiveManifestSha256' "$metadata")"
worktree_hash="$(jq -er '.recursiveWorktreeSha256' "$metadata")"
product_hash="$(jq -er '.productSourceSha256' "$metadata")"
game_manifest_hash="$(jq -er '.generated.gameManifestSha256' "$metadata")"
patch_manifest_hash="$(jq -er '.generated.patchManifestSha256' "$metadata")"
decompressed_rom_hash="$(jq -er '.generated.decompressedRomSha256' "$metadata")"
simulator_receipt="$(jq -er '.simulatorReceipt' "$test_record")"
app_hash="$(shasum -a 256 "$candidate_app/BananaPad" | awk '{print $1}')"

[[ "$(git -C "$candidate" rev-parse HEAD)" == "$commit" ]] || die "candidate commit changed"
[[ "$(recursive_manifest_hash "$candidate")" == "$manifest" ]] || die "candidate manifest changed"
[[ "$(recursive_worktree_hash "$candidate")" == "$worktree_hash" ]] || die "candidate worktree changed"
[[ "$(product_source_hash)" == "$product_hash" ]] || die "BananaPad product source changed"
[[ -f "$simulator_receipt" ]] || die "candidate Simulator receipt is missing"

tmp="$(mktemp "$state_dir/candidate-qualification.XXXXXX")"
jq -n \
  --arg commit "$commit" \
  --arg manifest "$manifest" \
  --arg worktree_hash "$worktree_hash" \
  --arg product_hash "$product_hash" \
  --arg game_manifest_hash "$game_manifest_hash" \
  --arg patch_manifest_hash "$patch_manifest_hash" \
  --arg decompressed_rom_hash "$decompressed_rom_hash" \
  --arg app_hash "$app_hash" \
  --arg simulator_receipt "$simulator_receipt" \
  --arg qualified_by "$(jq -er '.qualifiedBy' "$evidence_file")" \
  --arg qualified_at "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
  --argjson checks "$(jq -c '.checks' "$evidence_file")" \
  --argjson evidence "$(jq -c '.evidence' "$evidence_file")" \
  '{schemaVersion:1,result:"pass",commit:$commit,recursiveManifestSha256:$manifest,recursiveWorktreeSha256:$worktree_hash,productSourceSha256:$product_hash,generatedGameManifestSha256:$game_manifest_hash,generatedPatchManifestSha256:$patch_manifest_hash,decompressedRomSha256:$decompressed_rom_hash,appExecutableSha256:$app_hash,simulatorReceipt:$simulator_receipt,checks:$checks,evidence:$evidence,qualifiedBy:$qualified_by,qualifiedAt:$qualified_at}' > "$tmp"
chmod 600 "$tmp"
mv "$tmp" "$qualification"

note "recorded exact upstream-candidate qualification: $qualification"
note "rerun scripts/test-upstream-update.sh, then review before promotion"
