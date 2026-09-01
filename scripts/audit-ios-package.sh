#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

[[ $# -eq 1 ]] || die "usage: $0 <BananaPad.app-or.ipa>"
package="$1"
[[ -e "$package" ]] || die "package does not exist: $package"

audit_root="$(mktemp -d "${TMPDIR:-/tmp}/bananapad-package-audit.XXXXXX")"
cleanup() {
  [[ "$audit_root" == "${TMPDIR:-/tmp}/bananapad-package-audit."* ]] || die "refusing unsafe audit cleanup path"
  rm -rf "$audit_root"
}
trap cleanup EXIT

if [[ -d "$package" && "$package" == *.app ]]; then
  app="$package"
elif [[ -f "$package" && "$package" == *.ipa ]]; then
  unzip -q "$package" -d "$audit_root"
  app="$(find "$audit_root/Payload" -maxdepth 1 -type d -name '*.app' -print -quit)"
  [[ -n "$app" ]] || die "IPA does not contain Payload/*.app"
else
  die "expected an .app directory or .ipa file"
fi

failures=0
while IFS= read -r -d '' path; do
  relative="${path#"$app"/}"
  case "$relative" in
    *.z64|*.v64|*.n64|*.rom|*.eep|*.sra|*.fla|*.sav|*.save|*.crash|*.dmp|*.log|*.p12|*.cer|*.key|*RecompiledFuncs*|*RecompiledPatches*|*n_aspMain.cpp*|*recomp_overlays.inl*)
      printf 'unsafe package content: %s\n' "$relative" >&2
      failures=$((failures + 1))
      ;;
  esac
  [[ -f "$path" ]] || continue
  magic="$(od -An -tx1 -N4 "$path" 2>/dev/null | tr -d ' \n')"
  case "$magic" in
    80371240|37804012|40123780)
      printf 'Nintendo 64 ROM magic in package: %s\n' "$relative" >&2
      failures=$((failures + 1))
      ;;
  esac
done < <(find "$app" -print0)

(( failures == 0 )) || die "$failures unsafe package item(s) found"
"$BANANAPAD_ROOT/scripts/check-no-dynamic-code.sh" "$app"
note "iOS package audit passed: $package"
