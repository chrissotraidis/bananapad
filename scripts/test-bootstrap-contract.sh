#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

script="$BANANAPAD_ROOT/scripts/bootstrap-bananapad.sh"
[[ -x "$script" ]] || die "bootstrap script is missing or not executable"
receipt_auditor="$BANANAPAD_ROOT/scripts/audit-bootstrap-receipt.sh"
[[ -x "$receipt_auditor" ]] || die "bootstrap receipt auditor is missing or not executable"

for required in check-prerequisites clone-sources check-repo-safety prepare-rom build-host-tools decompress-rom generate-game generate-patches build-bananapad-static-macos build-bananapad-ios-simulator build-bananapad-ios-device package-unsigned-ipa check-no-dynamic-code audit-ios-package; do
  rg -q "$required" "$script" || die "bootstrap omits required step: $required"
done
rg -q 'bootstrap-last-run.json' "$script" || die "bootstrap does not produce an identity receipt"
rg -q 'unsignedIpaSha256' "$script" || die "bootstrap receipt does not bind the private IPA"
rg -q 'audit-bootstrap-receipt.sh' "$script" || die "bootstrap does not verify its completed identity receipt"
rg -q -- '-ef.*normalized_rom' "$script" || die "bootstrap reruns do not safely reuse the verified normalized ROM"
rg -q 'mkdir -p.*build_dir' "$BANANAPAD_ROOT/scripts/build-bananapad-macos.sh" || \
  die "macOS build does not create its patch-stamp directory before first use"
if rg -q 'simctl[[:space:]]+(boot|bootstatus|launch)' "$script"; then
  die "bootstrap must not boot or launch a Simulator"
fi

note "bootstrap contract: pass"
