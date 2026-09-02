#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

require_command rg
require_command shasum

first="$(product_source_hash)"
second="$(product_source_hash)"
[[ "$first" =~ ^[0-9a-f]{64}$ ]] || die "product source hash is not SHA-256"
[[ "$first" == "$second" ]] || die "product source hash is not deterministic"

for source_file in \
  scripts/stage-upstream-update.sh \
  scripts/prepare-upstream-candidate.sh \
  scripts/build-upstream-candidate.sh \
  scripts/qualify-upstream-candidate.sh \
  scripts/build-bananapad-ios-simulator.sh \
  scripts/test-upstream-update.sh \
  scripts/promote-upstream-update.sh \
  scripts/audit-mobile-execution-model.sh; do
  rg -q 'productSourceSha256|product_source_hash' "$BANANAPAD_ROOT/$source_file" || \
    die "product-source evidence is missing from $source_file"
done

"$BANANAPAD_ROOT/scripts/test-candidate-generation-contract.sh"

for required_check in patchReplay deterministicGeneration macosGameplay ipadTouchGameplay saveReload settingsCompatibility audits; do
  rg -q "$required_check" "$BANANAPAD_ROOT/scripts/qualify-upstream-candidate.sh" || \
    die "upstream qualification is missing required check: $required_check"
done
rg -q 'candidate-qualification.json' "$BANANAPAD_ROOT/scripts/test-upstream-update.sh" || \
  die "upstream test does not consume the exact candidate qualification"

manager="$BANANAPAD_ROOT/scripts/manage-upstream.sh"
[[ -x "$manager" ]] || die "guided upstream manager is missing or not executable"
for command_name in status check evaluate-latest evaluate build test promote rollback-candidate; do
  rg -q "$command_name" "$manager" || die "guided upstream manager omits: $command_name"
done
rg -q 'needs-full-validation' "$manager" || \
  die "guided upstream manager must preserve the newer-pin qualification gate"

integration_patch="$BANANAPAD_ROOT/patches/bananapad/bananapad-integration.patch"
[[ "$(rg -c 'BANANAPAD_APPLE_CORE_DIR}/paperpad_paths\.mm' "$integration_patch")" == "1" ]] || \
  die "Apple Application Support paths must be linked once from the shared native-shell source set"

rollback="$BANANAPAD_ROOT/scripts/rollback-upstream-update.sh"
for candidate_output in candidate-inputs bananapad-macos-candidate bananapad-ios-candidate; do
  rg -q "$candidate_output" "$rollback" || \
    die "candidate rollback does not archive disposable output: $candidate_output"
done

note "update evidence contract: pass"
note "product source SHA-256: $first"
