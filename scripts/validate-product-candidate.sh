#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

candidate_workspace="${BANANAPAD_WORKSPACE:-$BANANAPAD_ROOT/worktrees/dk64-upstream-candidate}"
simulator_app="${BANANAPAD_SIMULATOR_APP:-$BANANAPAD_ROOT/generated/build/bananapad-ios-candidate/Release/BananaPad.app}"
simulator_build_dir="${BANANAPAD_SIMULATOR_BUILD_DIR:-$BANANAPAD_ROOT/generated/build/bananapad-ios-candidate}"

[[ -e "$candidate_workspace/.git" ]] || die "candidate workspace is missing: $candidate_workspace"
[[ -d "$simulator_app" ]] || die "candidate Simulator app is missing: $simulator_app"
[[ -f "$simulator_build_dir/CMakeCache.txt" ]] || die "candidate Simulator build cache is missing: $simulator_build_dir"

for test_script in \
  test-save-slot-injector.py \
  test-paperpad-ui-fidelity.sh \
  test-touch-input-contract.sh \
  test-native-settings-contract.sh \
  test-rom-management-contract.sh \
  test-native-ui-suppression-contract.sh \
  test-mobile-lifecycle-contract.sh \
  test-ios-device-build-contract.sh \
  test-physical-device-preflight.sh \
  test-native-input-contract.sh \
  test-renderer-task-order-contract.sh \
  test-app-icon-contract.sh \
  test-bootstrap-contract.sh \
  test-candidate-generation-contract.sh \
  test-update-evidence-contract.sh \
  test-release-readiness-contract.sh \
  check-repo-safety.sh \
  test-upstream-update.sh; do
  "$BANANAPAD_ROOT/scripts/$test_script"
done

"$BANANAPAD_ROOT/scripts/check-no-dynamic-code.sh" "$simulator_app"
"$BANANAPAD_ROOT/scripts/audit-ios-package.sh" "$simulator_app"

git -C "$BANANAPAD_ROOT" diff --check

note "candidate executable SHA-256: $(shasum -a 256 "$simulator_app/BananaPad" | awk '{print $1}')"
note "product source SHA-256: $(product_source_hash)"
note "patch series SHA-256: $(patch_series_hash)"
note "dependency lock SHA-256: $(shasum -a 256 "$BANANAPAD_LOCK" | awk '{print $1}')"
note "BananaPad product candidate validation: pass"
