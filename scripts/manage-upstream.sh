#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

require_command git
require_command jq

command_name="${1:-status}"
shift || true
state_dir="$BANANAPAD_ROOT/generated/upstream"
metadata="$state_dir/candidate.json"
candidate="$BANANAPAD_ROOT/worktrees/dk64-upstream-candidate"
url="$(lock_value '.references.dk64Recompiled.url')"

latest_stable() {
  git ls-remote --tags --refs "$url" \
    | awk '{sub("refs/tags/", "", $2); print $2}' \
    | LC_ALL=C sort -V \
    | tail -n 1
}

show_status() {
  note "promoted: $(lock_value '.upstream.promoted.tag') $(lock_value '.upstream.promoted.commit')"
  if [[ -f "$metadata" && -e "$candidate/.git" ]]; then
    note "candidate: $(jq -r '.tag + " " + .commit' "$metadata")"
    note "candidate result: $(jq -r '.test.result // "not-tested"' "$metadata")"
    note "candidate reason: $(jq -r '.test.reason // "stage preparation/build/test not complete"' "$metadata")"
  else
    note "candidate: none"
  fi
}

evaluate_selector() {
  local selector="$1"
  local label="$2"
  [[ ! -e "$candidate" && ! -e "$metadata" ]] || \
    die "a candidate already exists; use status, promote, or rollback-candidate first"
  "$BANANAPAD_ROOT/scripts/stage-upstream-update.sh" "$selector" "$label"
  "$BANANAPAD_ROOT/scripts/prepare-upstream-candidate.sh"
  "$BANANAPAD_ROOT/scripts/build-upstream-candidate.sh" --build
  if "$BANANAPAD_ROOT/scripts/test-upstream-update.sh"; then
    note "candidate is mechanically green; review it, then run: scripts/manage-upstream.sh promote"
    return 0
  else
    local result=$?
    if [[ "$result" == 2 && "$(jq -r '.test.result // empty' "$metadata")" == "needs-full-validation" ]]; then
      note "candidate built and passed mechanical checks but is a genuinely newer runtime pin"
      note "complete docs/UPSTREAM-CANDIDATE-QUALIFICATION.md, then rerun: scripts/manage-upstream.sh test"
      return 2
    fi
    return "$result"
  fi
}

case "$command_name" in
  status)
    [[ $# -eq 0 ]] || die "usage: scripts/manage-upstream.sh status"
    show_status
    ;;
  check)
    [[ $# -eq 0 ]] || die "usage: scripts/manage-upstream.sh check"
    "$BANANAPAD_ROOT/scripts/check-upstream.sh"
    ;;
  evaluate-latest)
    [[ $# -eq 0 ]] || die "usage: scripts/manage-upstream.sh evaluate-latest"
    latest="$(latest_stable)"
    [[ -n "$latest" ]] || die "could not resolve the latest stable upstream tag"
    if [[ "$latest" == "$(lock_value '.upstream.promoted.tag')" ]]; then
      note "no update staged: $latest is already promoted"
      exit 0
    fi
    evaluate_selector "$latest" "latest-stable-$latest"
    ;;
  evaluate)
    [[ $# -ge 1 && $# -le 2 ]] || die "usage: scripts/manage-upstream.sh evaluate TAG-OR-COMMIT [LABEL]"
    evaluate_selector "$1" "${2:-selected-candidate}"
    ;;
  build)
    [[ $# -eq 0 ]] || die "usage: scripts/manage-upstream.sh build"
    "$BANANAPAD_ROOT/scripts/prepare-upstream-candidate.sh"
    "$BANANAPAD_ROOT/scripts/build-upstream-candidate.sh" --build
    ;;
  test)
    [[ $# -eq 0 ]] || die "usage: scripts/manage-upstream.sh test"
    "$BANANAPAD_ROOT/scripts/test-upstream-update.sh"
    ;;
  promote)
    [[ $# -eq 0 ]] || die "usage: scripts/manage-upstream.sh promote"
    "$BANANAPAD_ROOT/scripts/promote-upstream-update.sh" --apply
    ;;
  rollback-candidate)
    [[ $# -eq 0 ]] || die "usage: scripts/manage-upstream.sh rollback-candidate"
    "$BANANAPAD_ROOT/scripts/rollback-upstream-update.sh" --candidate
    ;;
  *)
    die "use status, check, evaluate-latest, evaluate TAG-OR-COMMIT [LABEL], build, test, promote, or rollback-candidate"
    ;;
esac
