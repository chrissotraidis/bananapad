#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

readiness="$BANANAPAD_ROOT/docs/RELEASE-READINESS.md"
receipt="$BANANAPAD_ROOT/generated/validation/ios-simulator-last-run.json"
ui_receipt="$BANANAPAD_ROOT/generated/validation/mobile-ui-last-run.json"
candidate_app="${BANANAPAD_RELEASE_CANDIDATE_APP:-$BANANAPAD_ROOT/generated/build/bananapad-ios-candidate/Release/BananaPad.app}"

if [[ ! -f "$ui_receipt" ]]; then
  ui_receipt="$receipt"
fi

[[ -f "$readiness" ]] || die "release-readiness document is missing"
[[ -f "$receipt" ]] || die "Simulator receipt is missing"
[[ -f "$ui_receipt" ]] || die "mobile UI/Simulator receipt is missing"
[[ -x "$candidate_app/BananaPad" ]] || die "current clean Simulator candidate is missing"

python3 - "$readiness" <<'PY'
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text()
rows = re.findall(r'^\|\s*(\d+)\s*\|[^\n]+\|\s*(Met|Inherited|Partial|Open|External)\s*\|', text, re.M)
ids = [int(row[0]) for row in rows]
if ids != list(range(1, 35)):
    raise SystemExit(f"release-readiness matrix must contain rows 1-34 exactly once; found {ids}")
PY

lock_hash="$(shasum -a 256 "$BANANAPAD_LOCK" | awk '{print $1}')"
patch_hash="$(patch_series_hash)"
product_hash="$(product_source_hash)"
gameplay_executable_hash="$(jq -er '.appExecutableSha256' "$receipt")"
executable_hash="$(jq -er '.appExecutableSha256' "$ui_receipt")"
candidate_executable_hash="$(shasum -a 256 "$candidate_app/BananaPad" | awk '{print $1}')"

rg -qF "$lock_hash" "$readiness" || die "release-readiness lock hash is stale"
rg -qF "$patch_hash" "$readiness" || die "release-readiness patch hash is stale"
rg -qF "$product_hash" "$readiness" || die "release-readiness product-source hash is stale"
rg -qF "$executable_hash" "$readiness" || die "release-readiness executable hash is stale"
rg -qF "$candidate_executable_hash" "$readiness" || die "release-readiness clean candidate hash is stale"
rg -qF "$gameplay_executable_hash" "$readiness" || die "release-readiness gameplay executable hash is stale"
rg -q 'Decision: \*\*GO for public BananaPad Preview 3\*\*' "$readiness" || \
  die "release decision is missing or unsafe"

note "release readiness contract: pass"
