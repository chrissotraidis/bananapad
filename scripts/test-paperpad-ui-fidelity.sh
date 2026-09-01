#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

reference_checkout="$BANANAPAD_ROOT/ref/paperpad"
reference_ui="$reference_checkout/apple/app/ios_main.mm"
bananapad_ui="$BANANAPAD_ROOT/apple/app/ios_main.mm"
expected_commit="$(lock_value '.references.paperpad.commit')"

[[ -e "$reference_checkout/.git" ]] || die "pinned PaperPad checkout is missing"
[[ "$(git -C "$reference_checkout" rev-parse HEAD)" == "$expected_commit" ]] || \
  die "PaperPad checkout does not match dependencies.lock.json"
[[ -f "$reference_ui" && -f "$bananapad_ui" ]] || \
  die "PaperPad or BananaPad iOS UI source is missing"

cmp -s "$reference_ui" "$bananapad_ui" || {
  diff -u "$reference_ui" "$bananapad_ui" >&2 || true
  die "BananaPad touch/menu/settings source drifted from pinned PaperPad"
}

ui_hash="$(shasum -a 256 "$bananapad_ui" | awk '{print $1}')"
note "PaperPad UI fidelity: pass"
note "reference commit: $expected_commit"
note "verbatim ios_main.mm SHA-256: $ui_hash"
