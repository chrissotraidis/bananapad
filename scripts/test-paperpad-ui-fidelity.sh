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

expected_ui="$(mktemp "${TMPDIR:-/tmp}/bananapad-paperpad-ui.XXXXXX")"
trap 'rm -f "$expected_ui"' EXIT
sed \
  -e 's/@"PaperPad Menu"/@"BananaPad Menu"/g' \
  -e 's/alertControllerWithTitle:@"PaperPad"/alertControllerWithTitle:@"BananaPad"/g' \
  -e 's/@"PaperPad Settings"/@"BananaPad Settings"/g' \
  "$reference_ui" > "$expected_ui"

cmp -s "$expected_ui" "$bananapad_ui" || {
  diff -u "$expected_ui" "$bananapad_ui" >&2 || true
  die "BananaPad touch/menu/settings source drifted from pinned PaperPad"
}

ui_hash="$(shasum -a 256 "$bananapad_ui" | awk '{print $1}')"
note "PaperPad UI fidelity: pass"
note "reference commit: $expected_commit"
note "BananaPad-branded ios_main.mm SHA-256: $ui_hash"
