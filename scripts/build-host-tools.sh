#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

build_jobs="${CMAKE_BUILD_PARALLEL_LEVEL:-}"
if [[ -n "$build_jobs" && ! "$build_jobs" =~ ^[1-9][0-9]*$ ]]; then
  die "CMAKE_BUILD_PARALLEL_LEVEL must be a positive whole number without leading zeros"
fi

"$BANANAPAD_ROOT/scripts/check-prerequisites.sh" >/dev/null
"$BANANAPAD_ROOT/scripts/verify-sources.sh" >/dev/null

source_dir="$BANANAPAD_ROOT/ref/toolchain/n64recomp-host"
build_dir="$BANANAPAD_ROOT/generated/build/host-tools"

cmake -S "$source_dir" -B "$build_dir" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++
cmake --build "$build_dir" --target N64Recomp RSPRecomp -j "${build_jobs:-$(sysctl -n hw.ncpu)}"

shasum -a 256 "$build_dir/N64Recomp" "$build_dir/RSPRecomp"
