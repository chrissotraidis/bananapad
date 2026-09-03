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

for marker in \
  'PaperPadTouchOverlayView' \
  'beginEditingLayout' \
  'resetLayout' \
  'setGameplayControlsEnabled' \
  'setPhysicalControllerConnected' \
  'setModalControlsHidden' \
  'touchesBegan:' \
  'touchesMoved:' \
  'touchesEnded:' \
  'touchesCancelled:' \
  'Edit Touch Layout' \
  'Share Diagnostics & Logs'; do
  rg -qF "$marker" "$reference_ui" || die "pinned PaperPad UI is missing structural marker: $marker"
  rg -qF "$marker" "$bananapad_ui" || die "BananaPad UI is missing PaperPad structural marker: $marker"
done

rg -qF '@"BananaPad Menu"' "$bananapad_ui" || die "BananaPad menu branding is missing"
rg -qF '@"BananaPad Settings"' "$bananapad_ui" || die "BananaPad settings branding is missing"
rg -qF 'Hold Z to Lock' "$bananapad_ui" || die "BananaPad Z-lock extension is missing"
rg -qF '@"PaperPad Menu"' "$bananapad_ui" && die "PaperPad menu branding leaked into BananaPad"
rg -qF '@"PaperPad Settings"' "$bananapad_ui" && die "PaperPad settings branding leaked into BananaPad"

ui_hash="$(shasum -a 256 "$bananapad_ui" | awk '{print $1}')"
note "PaperPad UI structure fidelity: pass"
note "reference commit: $expected_commit"
note "BananaPad-branded ios_main.mm SHA-256: $ui_hash"
