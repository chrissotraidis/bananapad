#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

mode="${1:---candidate}"
state_dir="$BANANAPAD_ROOT/generated/upstream"
candidate="$BANANAPAD_ROOT/worktrees/dk64-upstream-candidate"
candidate_inputs="$state_dir/candidate-inputs"
candidate_macos_build="$BANANAPAD_ROOT/generated/build/bananapad-macos-candidate"
candidate_ios_build="$BANANAPAD_ROOT/generated/build/bananapad-ios-candidate"

if [[ "$mode" == "--candidate" ]]; then
  [[ -e "$candidate" || -e "$state_dir/candidate.json" || -e "$candidate_inputs" || \
     -e "$candidate_macos_build" || -e "$candidate_ios_build" ]] || die "no candidate state to roll back"
  stamp="$(date -u '+%Y%m%dT%H%M%SZ')"
  archive="$state_dir/rollbacks/$stamp"
  mkdir -p "$archive"
  [[ ! -e "$candidate" ]] || mv "$candidate" "$archive/checkout"
  [[ ! -e "$candidate_inputs" ]] || mv "$candidate_inputs" "$archive/candidate-inputs"
  [[ ! -e "$candidate_macos_build" ]] || mv "$candidate_macos_build" "$archive/macos-build"
  [[ ! -e "$candidate_ios_build" ]] || mv "$candidate_ios_build" "$archive/ios-build"
  for item in candidate.json candidate-test.json candidate-qualification.json promotion-rehearsal.json; do
    [[ ! -e "$state_dir/$item" ]] || mv "$state_dir/$item" "$archive/$item"
  done
  note "candidate rolled back recoverably to $archive"
  exit 0
fi

[[ "$mode" == "--promotion" && $# -eq 2 ]] || die "use --candidate, or --promotion GENERATED_SNAPSHOT_DIRECTORY"
snapshot="$2"
before="$snapshot/dependencies.lock.before.json"
[[ -f "$before" ]] || die "promotion snapshot is missing dependencies.lock.before.json"
old_commit="$(jq -er '.upstream.promoted.commit' "$before")"
reference="$BANANAPAD_ROOT/ref/dk64-recompiled"
git -C "$reference" checkout --detach "$old_commit"
git -C "$reference" submodule update --init --recursive
cp "$BANANAPAD_LOCK" "$snapshot/dependencies.lock.rolled-back-from.json"
cp "$before" "$BANANAPAD_LOCK"
note "restored promoted source and lock to $old_commit"
