#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

"$BANANAPAD_ROOT/scripts/check-prerequisites.sh" >/dev/null
"$BANANAPAD_ROOT/scripts/verify-sources.sh" >/dev/null

promoted="$(lock_value '.upstream.promoted.commit')"
expected_commit="${BANANAPAD_EXPECTED_COMMIT:-$promoted}"
reference="$BANANAPAD_ROOT/ref/dk64-recompiled"
profile="${BANANAPAD_MACOS_PROFILE:-bootstrap}"
case "$profile" in
  bootstrap)
    default_workspace="$BANANAPAD_ROOT/worktrees/bananapad-macos"
    default_build_dir="$BANANAPAD_ROOT/generated/build/bananapad-macos"
    no_dynamic_code=OFF
    ;;
  static)
    default_workspace="$BANANAPAD_ROOT/worktrees/bananapad-static-macos"
    default_build_dir="$BANANAPAD_ROOT/generated/build/bananapad-static-macos"
    no_dynamic_code=ON
    ;;
  *) die "unknown BANANAPAD_MACOS_PROFILE: $profile" ;;
esac
workspace="${BANANAPAD_WORKSPACE:-$default_workspace}"
build_dir="${BANANAPAD_BUILD_DIR:-$default_build_dir}"
game_set="${BANANAPAD_GAME_SET:-$BANANAPAD_ROOT/generated/aot/current-game}"
patch_set="${BANANAPAD_PATCH_SET:-$BANANAPAD_ROOT/generated/aot/current-patches}"
decompressed_rom="${BANANAPAD_DECOMPRESSED_ROM:-$BANANAPAD_ROOT/generated/rom/donkeykong64.decompressed.us.z64}"
host_tools="${BANANAPAD_HOST_TOOLS:-$BANANAPAD_ROOT/generated/build/host-tools}"
llvm_root="/opt/homebrew/opt/llvm@18/bin"
sdl3_library="/opt/homebrew/opt/sdl3/lib/libSDL3.0.dylib"
pinned_sdl2_source="$BANANAPAD_ROOT/ref/paperpad/ref/SDL2"
pinned_sdl2_library="$BANANAPAD_ROOT/ref/paperpad/build-macos-sdl2/libSDL2.a"

[[ -f "$game_set/manifest.sha256" ]] || die "current generated game set is missing"
[[ -f "$patch_set/manifest.sha256" ]] || die "current generated patch set is missing"
[[ -f "$decompressed_rom" ]] || die "decompressed build ROM is missing"
[[ -x "$host_tools/N64Recomp" && -x "$host_tools/RSPRecomp" ]] || die "host tools are missing"
if [[ "$profile" == static ]]; then
  [[ -f "$pinned_sdl2_source/include/SDL.h" ]] || die "pinned PaperPad SDL2 source is missing"
  if [[ ! -f "$pinned_sdl2_library" ]]; then
    "$BANANAPAD_ROOT/ref/paperpad/scripts/build-sdl2.sh"
  fi
else
  [[ -f "$sdl3_library" ]] || die "SDL3 runtime required by the bootstrap desktop compatibility layer is missing"
fi

mkdir -p "$BANANAPAD_ROOT/worktrees" "$BANANAPAD_ROOT/generated/build"
if [[ ! -e "$workspace/.git" ]]; then
  [[ ! -e "$workspace" ]] || die "refusing to replace non-worktree path: $workspace"
  git -C "$reference" worktree add --detach "$workspace" "$promoted"
  git -C "$workspace" submodule update --init --recursive
fi

[[ "$(git -C "$workspace" rev-parse HEAD)" == "$expected_commit" ]] || die "BananaPad worktree is not at the expected pin"
mkdir -p "$build_dir"
patch_stamp="$build_dir/.bananapad-patch-series.sha256"
patch_series_hash="$(cd "$BANANAPAD_ROOT" && find patches/upstream patches/bananapad \
  -type f -name '*.patch' -print | LC_ALL=C sort | xargs shasum -a 256 | shasum -a 256 | awk '{print $1}')"
if [[ -f "$patch_stamp" ]]; then
  if [[ "$(tr -d '[:space:]' < "$patch_stamp")" != "$patch_series_hash" ]]; then
    current_series_applied=true
    for patch_dir in upstream bananapad; do
      for patch_file in "$BANANAPAD_ROOT/patches/$patch_dir"/*.patch; do
        [[ -e "$patch_file" ]] || continue
        if ! git -C "$workspace" apply --reverse --check "$patch_file"; then
          current_series_applied=false
          break 2
        fi
      done
    done
    [[ "$current_series_applied" == true ]] || \
      die "BananaPad patch series changed; stage it in a fresh isolated worktree"
    printf '%s\n' "$patch_series_hash" > "$patch_stamp"
    note "refreshed patch stamp after verifying the current series is applied exactly"
  fi
else
  current_series_applied=true
  for patch_dir in upstream bananapad; do
    for patch_file in "$BANANAPAD_ROOT/patches/$patch_dir"/*.patch; do
      [[ -e "$patch_file" ]] || continue
      if ! git -C "$workspace" apply --reverse --check "$patch_file"; then
        current_series_applied=false
        break 2
      fi
    done
  done
  if [[ "$current_series_applied" != true ]]; then
    for patch_dir in upstream bananapad; do
      for patch_file in "$BANANAPAD_ROOT/patches/$patch_dir"/*.patch; do
        [[ -e "$patch_file" ]] || continue
        git -C "$workspace" apply --check "$patch_file"
        git -C "$workspace" apply "$patch_file"
      done
    done
  fi
  printf '%s\n' "$patch_series_hash" > "$patch_stamp"
fi

if [[ ! -d "$workspace/RecompiledFuncs" ]]; then
  cp -R "$game_set/RecompiledFuncs" "$workspace/RecompiledFuncs"
else
  diff -qr "$game_set/RecompiledFuncs" "$workspace/RecompiledFuncs" >/dev/null || die "BananaPad game output differs from the G1 set"
fi
if [[ ! -d "$workspace/RecompiledPatches" ]]; then
  cp -R "$patch_set/RecompiledPatches" "$workspace/RecompiledPatches"
else
  for name in patches.c funcs.h recomp_overlays.inl; do
    cmp -s "$patch_set/RecompiledPatches/$name" "$workspace/RecompiledPatches/$name" || die "BananaPad patch output differs: $name"
  done
fi

cp "$game_set/rsp/n_aspMain.cpp" "$workspace/rsp/n_aspMain.cpp"
cp "$patch_set/patches/patches.elf" "$workspace/patches/patches.elf"
cp "$patch_set/patches/patches.bin" "$workspace/patches/patches.bin"
ln -sfn "$decompressed_rom" "$workspace/donkeykong64.decompressed.us.z64"
ln -sfn "$host_tools/N64Recomp" "$workspace/N64Recomp"
ln -sfn "$host_tools/RSPRecomp" "$workspace/RSPRecomp"

cmake_profile_args=()
if [[ "$profile" == static ]]; then
  export PKG_CONFIG_PATH="/opt/homebrew/opt/curl/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
  cmake_profile_args+=(
    "-DBANANAPAD_SDL2_SOURCE_DIR=$pinned_sdl2_source"
    "-DBANANAPAD_SDL2_STATIC_LIBRARY=$pinned_sdl2_library"
    "-DBANANAPAD_NATIVE_SHELL=ON"
    "-DBANANAPAD_APPLE_CORE_DIR=$BANANAPAD_ROOT/apple/core")
else
  export PKG_CONFIG_PATH="/opt/homebrew/opt/sdl2-compat/lib/pkgconfig:/opt/homebrew/opt/curl/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
fi
cmake -S "$workspace" -B "$build_dir" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_AR="$llvm_root/llvm-ar" \
  -DPATCHES_C_COMPILER="$llvm_root/clang" \
  -DPATCHES_LD="$llvm_root/ld.lld" \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
  -DN64MODERN_NO_DYNAMIC_CODE="$no_dynamic_code" \
  -DCMAKE_PREFIX_PATH="/opt/homebrew/opt/curl" \
  -DCURL_ROOT="/opt/homebrew/opt/curl" \
  "${cmake_profile_args[@]}"
cmake --build "$build_dir" --target DK64Recompiled -j "$(sysctl -n hw.ncpu)"

app="$build_dir/BananaPad.app"
[[ -x "$app/Contents/MacOS/BananaPad" ]] || die "BananaPad.app was not produced"

mkdir -p "$app/Contents/Frameworks"
if [[ "$profile" != static ]]; then
  cp "$sdl3_library" "$app/Contents/Frameworks/libSDL3.0.dylib"
  chmod u+w "$app/Contents/Frameworks/libSDL3.0.dylib"
  install_name_tool -id "@rpath/libSDL3.0.dylib" "$app/Contents/Frameworks/libSDL3.0.dylib"
  ln -sfn "libSDL3.0.dylib" "$app/Contents/Frameworks/libSDL3.dylib"
  codesign --force --sign - "$app/Contents/Frameworks/libSDL3.0.dylib"
else
  # Remove compatibility-layer artifacts left by an earlier bootstrap build
  # in the same CMake output directory. The static profile links pinned SDL2.
  rm -f \
    "$app/Contents/Frameworks/libSDL2-2.0.0.dylib" \
    "$app/Contents/Frameworks/libSDL3.0.dylib" \
    "$app/Contents/Frameworks/libSDL3.dylib" \
    "$app/Contents/Frameworks/libfreetype.6.dylib" \
    "$app/Contents/Frameworks/libpng16.16.dylib"
fi
if [[ "$profile" == static ]]; then
  # A local ad-hoc signature has no Team ID. Enabling Hardened Runtime library
  # validation on that signature makes dyld reject separately signed embedded
  # libraries as having a different Team ID. Sign the whole local bundle
  # consistently without forbidden entitlements; distribution signing can turn
  # Hardened Runtime on once an Apple Development/Distribution identity exists.
  while IFS= read -r framework; do
    codesign --force --sign - --timestamp=none "$framework"
  done < <(find "$app/Contents/Frameworks" -type f -name '*.dylib' -print | LC_ALL=C sort)
  codesign --verbose=2 --sign - --timestamp=none --deep --force "$app"
else
  codesign --verbose=2 --options=runtime --no-strict --sign - \
    --entitlements "$workspace/.github/macos/entitlements.plist" --deep --force "$app"
fi
codesign --verify --deep --strict "$app"

note "app=$app"
note "app-sha256=$(cd "$app" && find . -type f -print | LC_ALL=C sort | while IFS= read -r item; do shasum -a 256 "$item"; done | shasum -a 256 | awk '{print $1}')"
note "executable-sha256=$(shasum -a 256 "$app/Contents/MacOS/BananaPad" | awk '{print $1}')"
if [[ "$profile" == static ]]; then
  note "profile=static-native-shell (LiveRecomp disabled; pinned static PaperPad SDL2; desktop launcher bypassed)"
else
  note "profile=bootstrap-desktop (upstream dynamic-code assumptions retained pending PaperPad static-core integration)"
fi
