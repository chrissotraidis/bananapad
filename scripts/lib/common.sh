#!/usr/bin/env bash

set -euo pipefail

BANANAPAD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BANANAPAD_LOCK="$BANANAPAD_ROOT/dependencies.lock.json"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

note() {
  printf '%s\n' "$*"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

lock_value() {
  jq -er "$1" "$BANANAPAD_LOCK"
}

select_python() {
  local candidate
  if [[ -n "${BANANAPAD_PYTHON:-}" ]]; then
    candidate="$BANANAPAD_PYTHON"
    "$candidate" -c 'import sys; raise SystemExit(sys.version_info < (3, 11))' || die "BANANAPAD_PYTHON must be Python 3.11 or newer"
    printf '%s\n' "$candidate"
    return
  fi
  for candidate in /opt/homebrew/bin/python3.14 /opt/homebrew/bin/python3.13 /opt/homebrew/bin/python3.12 /opt/homebrew/bin/python3.11 python3.14 python3.13 python3.12 python3.11; do
    if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -c 'import sys; raise SystemExit(sys.version_info < (3, 11))'; then
      printf '%s\n' "$candidate"
      return
    fi
  done
  die "Python 3.11 or newer is required"
}

recursive_manifest_hash() {
  local checkout="$1"
  local state
  state="$(git -C "$checkout" submodule status --recursive)"
  if printf '%s\n' "$state" | grep -Eq '^[+-U]'; then
    die "recursive submodules are missing or do not match gitlinks: $checkout"
  fi
  printf '%s\n' "$state" | sed 's/^[ +-U]//' | LC_ALL=C sort | shasum -a 256 | awk '{print $1}'
}

recursive_worktree_hash() {
  local checkout="$1"
  (
    printf 'repo .\n'
    git -C "$checkout" status --porcelain=v1 --untracked-files=all
    git -C "$checkout" diff --binary --no-ext-diff
    git -C "$checkout" submodule foreach --quiet --recursive '
      printf "repo %s\n" "$displaypath"
      git status --porcelain=v1 --untracked-files=all
      git diff --binary --no-ext-diff
    '
  ) | shasum -a 256 | awk '{print $1}'
}

patch_series_hash() {
  (
    cd "$BANANAPAD_ROOT"
    find patches/upstream patches/bananapad -type f -name '*.patch' -print \
      | LC_ALL=C sort \
      | while IFS= read -r patch_file; do
          shasum -a 256 "$patch_file"
        done \
      | shasum -a 256 \
      | awk '{print $1}'
  )
}

product_source_hash() {
  (
    cd "$BANANAPAD_ROOT"
    {
      find apple -type f -print
      printf '%s\n' \
        patches/sdl2/ios-controller-uipress-duplication.patch \
        scripts/build-bananapad-ios-device.sh \
        scripts/build-bananapad-ios-simulator.sh \
        scripts/prepare-bananapad-sdl2.sh \
        scripts/lib/common.sh
    } | LC_ALL=C sort -u | while IFS= read -r source_file; do
      [[ -f "$source_file" ]] || die "product source input is missing: $source_file"
      printf '%s\n' "$source_file"
      shasum -a 256 "$source_file"
    done | shasum -a 256 | awk '{print $1}'
  )
}
