#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

cd "$BANANAPAD_ROOT"
failures=0

fail() {
  printf 'unsafe: %s\n' "$*" >&2
  failures=$((failures + 1))
}

paths_file="$(mktemp)"
trap 'rm -f "$paths_file"' EXIT
git ls-files --cached --others --exclude-standard -z >"$paths_file"

while IFS= read -r -d '' path; do
  case "$path" in
    ref/*|generated/*|worktrees/*|artifacts/*|docs/artifacts/*)
      fail "private/generated path is publishable: $path"
      ;;
  esac

  case "${path##*.}" in
    z64|v64|n64|rom|eep|sra|fla|sav|save|ipa|xcarchive|mobileprovision|p12|cer|key|crash|dmp|log)
      fail "forbidden private/package extension: $path"
      ;;
  esac

  [[ -f "$path" ]] || continue
  size="$(stat -f '%z' "$path")"
  if (( size > 10485760 )); then
    fail "publishable file exceeds 10 MiB: $path ($size bytes)"
  fi

  magic="$(od -An -tx1 -N4 "$path" 2>/dev/null | tr -d ' \n')"
  case "$magic" in
    80371240|37804012|40123780)
      fail "Nintendo 64 ROM magic found: $path"
      ;;
  esac

  if [[ "$path" != "docs/JOURNAL.md" && "$path" != "scripts/check-repo-safety.sh" ]] && grep -Iq . "$path"; then
    if grep -nE '/Users/[^/]+/|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|gh[pousr]_[A-Za-z0-9_]{20,}' "$path"; then
      fail "personal absolute path, private key, or likely token found: $path"
    fi
  fi
done <"$paths_file"

(( failures == 0 )) || die "$failures repository safety violation(s) found"
note "repository safety check passed"
