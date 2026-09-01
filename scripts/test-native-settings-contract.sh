#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

native="$BANANAPAD_ROOT/apple/core/bananapad_native.cpp"
renderer="$BANANAPAD_ROOT/apple/core/bananapad_rt64_context.cpp"
runtime_config="${1:-$BANANAPAD_ROOT/worktrees/bananapad-static-macos/lib/N64ModernRuntime/ultramodern/include/ultramodern/config.hpp}"

[[ -f "$runtime_config" ]] || die "runtime graphics config is missing: $runtime_config"

rg -q 'case 4: config\.res_option = ultramodern::renderer::Resolution::Manual' "$native" \
  || die "the visible 3x/4x choices do not select the manual-resolution path"
rg -q 'config\.resolution_multiplier = fixed_scale > 0 \? fixed_scale : 2\.0' "$native" \
  || die "the native settings bridge does not preserve the selected fixed multiplier"
rg -q 'Resolution::Manual' "$runtime_config" \
  || die "the runtime graphics contract has no manual-resolution mode"
rg -q 'double resolution_multiplier = 2\.0' "$runtime_config" \
  || die "the runtime graphics contract has no manual-resolution multiplier"
rg -q 'case ultramodern::renderer::Resolution::Manual' "$renderer" \
  || die "the RT64 bridge does not apply manual resolution"
rg -q 'new_config\.resolution_multiplier != old_config\.resolution_multiplier' "$renderer" \
  || die "changing only the fixed multiplier does not invalidate RT64 configuration"
rg -q 'N64ReferenceWidth = 320\.0f' "$native" \
  || die "renderer telemetry does not report internal width from the N64 reference resolution"
rg -q 'N64ReferenceHeight = 240\.0f' "$native" \
  || die "renderer telemetry does not report internal height from the N64 reference resolution"

note "native settings contract: pass"
