#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

preflight="$BANANAPAD_ROOT/scripts/preflight-bananapad-device-acceptance.sh"
app="$BANANAPAD_ROOT/generated/build/bananapad-ios-device/Release/BananaPad.app"
[[ -x "$preflight" ]] || die "physical-device preflight is missing"
[[ -x "$app/BananaPad" ]] || die "unsigned device build is missing"

test_root="$(mktemp -d "${TMPDIR:-/tmp}/bananapad-physical-preflight-test.XXXXXX")"
cleanup() {
  [[ "$test_root" == "${TMPDIR:-/tmp}/bananapad-physical-preflight-test."* ]] \
    || die "refusing unsafe preflight-test cleanup path"
  rm -rf "$test_root"
}
trap cleanup EXIT

mock_bin="$test_root/bin"
receipt_root="$test_root/receipts"
mkdir -p "$mock_bin" "$receipt_root"

cat > "$mock_bin/codesign" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
if [[ " $* " == *" -dvv "* ]]; then
  printf '%s\n' 'Executable=/mock/BananaPad' 'TeamIdentifier=TESTTEAM42' >&2
fi
MOCK

cat > "$mock_bin/xcrun" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
output=""
while [[ $# -gt 0 ]]; do
  if [[ "$1" == "--json-output" ]]; then
    shift
    output="$1"
    break
  fi
  shift
done
[[ -n "$output" ]] || { printf 'mock xcrun requires --json-output\n' >&2; exit 1; }
printf '%s\n' \
  '{' \
  '  "info": {"outcome": "success"},' \
  '  "result": {"deviceProperties": {"name": "Mock iPad", "osVersionNumber": "26.0"}}' \
  '}' > "$output"
MOCK
chmod +x "$mock_bin/codesign" "$mock_bin/xcrun"

PATH="$mock_bin:$PATH" \
BANANAPAD_DEVICE_APP="$app" \
BANANAPAD_PHYSICAL_RECEIPT_ROOT="$receipt_root" \
  "$preflight" "Mock iPad" >/dev/null

receipt="$(find "$receipt_root" -mindepth 2 -maxdepth 2 -name preflight.json -print -quit)"
[[ -f "$receipt" ]] || die "physical-device preflight did not create a receipt"
worksheet="$(dirname "$receipt")/ACCEPTANCE.md"
[[ -f "$worksheet" ]] || die "physical-device preflight did not create a worksheet"

jq -e '
  .schema == "bananapad-physical-preflight-v1" and
  .requestedDevice == "Mock iPad" and
  .installedAndLaunched == false and
  .app.signingTeam == "TESTTEAM42" and
  (.app.executableSha256 | length == 64) and
  (.app.bundleManifestSha256 | length == 64) and
  (.source.dependencyLockSha256 | length == 64) and
  (.source.patchSeriesSha256 | length == 64) and
  (.source.productSourceSha256 | length == 64) and
  .deviceDetails.deviceProperties.name == "Mock iPad" and
  .decision == "pending-hands-on-acceptance"
' "$receipt" >/dev/null || die "physical-device preflight receipt is incomplete"

rg -q 'Z\+C-Up, Z\+C-Down, Z\+C-Left, and Z\+C-Right' "$worksheet" \
  || die "physical-device worksheet is missing the chord matrix"
rg -q '90-minute release soak' "$worksheet" \
  || die "physical-device worksheet is missing the sustained-operation gate"
rg -q 'Decision: \*\*PENDING\*\*' "$worksheet" \
  || die "physical-device worksheet must remain pending"

note "physical-device preflight contract: pass"
