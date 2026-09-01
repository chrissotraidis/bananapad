#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

source_file="$BANANAPAD_ROOT/apple/app/rom_setup.mm"
ui_file="$BANANAPAD_ROOT/apple/app/ios_main.mm"
[[ -f "$source_file" ]] || die "ROM-management source is missing"
[[ -f "$ui_file" ]] || die "touch/menu source is missing"

rg -q 'normalizedROMData\(source, error\)' "$source_file" \
  || die "ROM replacement no longer validates before installation"
rg -q 'writeToURL:target options:NSDataWritingAtomic' "$source_file" \
  || die "valid ROM replacement is not atomic"
rg -q 'URLByAppendingPathComponent:@"DK64\.z64"' "$source_file" \
  || die "private ROM target changed"
rg -q 'URLByAppendingPathComponent:@"rom\.cfg"' "$source_file" \
  || die "ROM configuration target changed"
rg -q 'Remove Private ROM Copy\?' "$source_file" \
  || die "destructive ROM removal confirmation is missing"
rg -q 'Saves and settings will be kept' "$source_file" \
  || die "ROM removal does not state the preservation boundary"
rg -q '\[self confirmRemoveROM\]' "$source_file" \
  || die "Remove ROM bypasses confirmation"
python3 - "$ui_file" <<'PY'
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text()
call = text.index("paperpad_present_rom_manager")
window = text[max(0, call - 700):call]
if "setModalControlsHidden:YES" not in window:
    raise SystemExit("ROM manager is not preceded by modal touch suppression")
PY

if rg -n 'removeItemAtURL:.*(save|settings)|URLByAppendingPathComponent:@"saves"' "$source_file"; then
  die "ROM manager may delete saves or settings"
fi

note "ROM management contract: pass"
