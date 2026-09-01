#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

workspace="${BANANAPAD_WORKSPACE:-$BANANAPAD_ROOT/worktrees/bananapad-static-macos}"
output="$BANANAPAD_ROOT/patches/bananapad/bananapad-integration.patch"
[[ -e "$workspace/.git" ]] || die "prepared BananaPad worktree is missing"

tmp="$(mktemp "${TMPDIR:-/tmp}/bananapad-integration.XXXXXX")"
cleanup() {
  rm -f "$tmp"
}
trap cleanup EXIT

append_diff() {
  local repo="$1"
  local prefix="$2"
  shift 2
  git -C "$repo" diff --binary --no-ext-diff \
    --src-prefix="a/$prefix" --dst-prefix="b/$prefix" -- "$@" >> "$tmp"
}

append_diff "$workspace" "" \
  .github/macos/Info.plist.in \
  .github/macos/apple_bundle.cmake \
  .github/macos/fixup_bundle.cmake \
  CMakeLists.txt \
  include/donk_config.h \
  src/game/recomp_api.cpp \
  src/game/recomp_data_api.cpp \
  src/game/recomp_extension_api.cpp \
  src/main/main.cpp

append_diff "$workspace/lib/N64ModernRuntime" "lib/N64ModernRuntime/" \
  librecomp/CMakeLists.txt \
  librecomp/include/librecomp/mods.hpp \
  librecomp/src/mods.cpp \
  librecomp/src/recomp.cpp \
  ultramodern/include/ultramodern/config.hpp \
  ultramodern/src/events.cpp

append_diff "$workspace/lib/rt64" "lib/rt64/" \
  CMakeLists.txt \
  src/apple/rt64_apple.mm \
  src/gbi/rt64_gbi.cpp \
  src/render/rt64_render_target.cpp \
  src/render/rt64_shader_library.cpp \
  src/shaders/TextureSampler.hlsli

append_diff "$workspace/lib/rt64/src/contrib/nativefiledialog-extended" \
  "lib/rt64/src/contrib/nativefiledialog-extended/" \
  CMakeLists.txt src/CMakeLists.txt src/nfd_null.cpp

append_diff "$workspace/lib/rt64/src/contrib/plume" \
  "lib/rt64/src/contrib/plume/" \
  CMakeLists.txt plume_apple.mm plume_metal.cpp

[[ -s "$tmp" ]] || die "generated integration patch is empty"
mkdir -p "$(dirname "$output")"
chmod 644 "$tmp"
mv "$tmp" "$output"
trap - EXIT

note "refreshed $output"
note "sha256=$(shasum -a 256 "$output" | awk '{print $1}')"
