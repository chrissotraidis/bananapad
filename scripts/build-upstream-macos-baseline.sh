#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

"$BANANAPAD_ROOT/scripts/check-prerequisites.sh" >/dev/null
"$BANANAPAD_ROOT/scripts/verify-sources.sh" >/dev/null

promoted="$(lock_value '.upstream.promoted.commit')"
reference="$BANANAPAD_ROOT/ref/dk64-recompiled"
workspace="$BANANAPAD_ROOT/worktrees/dk64-upstream-baseline"
build_dir="$BANANAPAD_ROOT/generated/build/upstream-macos-1.0.1"
game_set="$BANANAPAD_ROOT/generated/aot/current-game"
patch_set="$BANANAPAD_ROOT/generated/aot/current-patches"
decompressed_rom="$BANANAPAD_ROOT/generated/rom/donkeykong64.decompressed.us.z64"
host_tools="$BANANAPAD_ROOT/generated/build/host-tools"
llvm_root="/opt/homebrew/opt/llvm@18/bin"
compat_patch="$BANANAPAD_ROOT/patches/upstream/xcode26-hlslpp-labs.patch"
sdl3_library="/opt/homebrew/opt/sdl3/lib/libSDL3.0.dylib"

[[ -f "$game_set/manifest.sha256" ]] || die "current generated game set is missing"
[[ -f "$patch_set/manifest.sha256" ]] || die "current generated patch set is missing"
[[ -f "$decompressed_rom" ]] || die "decompressed build ROM is missing"
[[ -x "$host_tools/N64Recomp" && -x "$host_tools/RSPRecomp" ]] || die "host tools are missing"
[[ -f "$compat_patch" ]] || die "Xcode 26 compatibility patch is missing"
[[ -f "$sdl3_library" ]] || die "SDL3 runtime required by sdl2-compat is missing"

mkdir -p "$BANANAPAD_ROOT/worktrees" "$BANANAPAD_ROOT/generated/build"
if [[ ! -e "$workspace/.git" ]]; then
  [[ ! -e "$workspace" ]] || die "refusing to replace non-worktree path: $workspace"
  git -C "$reference" worktree add --detach "$workspace" "$promoted"
  git -C "$workspace" submodule update --init --recursive
fi

[[ "$(git -C "$workspace" rev-parse HEAD)" == "$promoted" ]] || die "baseline worktree is not at the promoted pin"
if git -C "$workspace" diff --quiet; then
  git -C "$workspace" apply --check "$compat_patch"
  git -C "$workspace" apply "$compat_patch"
else
  [[ "$(git -C "$workspace" diff --name-only)" == "lib/rt64" ]] || die "baseline worktree has unexpected tracked modifications"
  git -C "$workspace" apply --reverse --check "$compat_patch" || die "baseline compatibility patch differs from the recorded patch"
fi

if [[ ! -d "$workspace/RecompiledFuncs" ]]; then
  cp -R "$game_set/RecompiledFuncs" "$workspace/RecompiledFuncs"
else
  diff -qr "$game_set/RecompiledFuncs" "$workspace/RecompiledFuncs" >/dev/null || die "baseline game output differs from the G1 set"
fi
if [[ ! -d "$workspace/RecompiledPatches" ]]; then
  cp -R "$patch_set/RecompiledPatches" "$workspace/RecompiledPatches"
else
  for name in patches.c funcs.h recomp_overlays.inl; do
    cmp -s "$patch_set/RecompiledPatches/$name" "$workspace/RecompiledPatches/$name" || die "baseline patch output differs: $name"
  done
fi

cp "$game_set/rsp/n_aspMain.cpp" "$workspace/rsp/n_aspMain.cpp"
cp "$patch_set/patches/patches.elf" "$workspace/patches/patches.elf"
cp "$patch_set/patches/patches.bin" "$workspace/patches/patches.bin"

ln -sfn "$decompressed_rom" "$workspace/donkeykong64.decompressed.us.z64"
ln -sfn "$host_tools/N64Recomp" "$workspace/N64Recomp"
ln -sfn "$host_tools/RSPRecomp" "$workspace/RSPRecomp"

export PKG_CONFIG_PATH="/opt/homebrew/opt/sdl2-compat/lib/pkgconfig:/opt/homebrew/opt/curl/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
cmake -S "$workspace" -B "$build_dir" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_AR="$llvm_root/llvm-ar" \
  -DPATCHES_C_COMPILER="$llvm_root/clang" \
  -DPATCHES_LD="$llvm_root/ld.lld" \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
  -DCMAKE_PREFIX_PATH="/opt/homebrew/opt/sdl2-compat;/opt/homebrew/opt/curl" \
  -DCURL_ROOT="/opt/homebrew/opt/curl"
cmake --build "$build_dir" --target DK64Recompiled -j "$(sysctl -n hw.ncpu)"

app="$build_dir/DK64Recompiled.app"
[[ -d "$app" ]] || die "upstream build did not produce DK64Recompiled.app"

# Homebrew's sdl2-compat loads SDL3 dynamically, so BundleUtilities cannot see
# or copy it from the shim's Mach-O dependency list. Complete the private
# baseline bundle explicitly and re-sign after changing its contents.
mkdir -p "$app/Contents/Frameworks"
cp "$sdl3_library" "$app/Contents/Frameworks/libSDL3.0.dylib"
chmod u+w "$app/Contents/Frameworks/libSDL3.0.dylib"
install_name_tool -id "@rpath/libSDL3.0.dylib" "$app/Contents/Frameworks/libSDL3.0.dylib"
ln -sfn "libSDL3.0.dylib" "$app/Contents/Frameworks/libSDL3.dylib"
codesign --force --sign - "$app/Contents/Frameworks/libSDL3.0.dylib"
codesign --verbose=2 --options=runtime --no-strict --sign - \
  --entitlements "$workspace/.github/macos/entitlements.plist" --deep --force "$app"

note "app=$app"
note "app-sha256=$(cd "$app" && find . -type f -print | LC_ALL=C sort | while IFS= read -r path; do shasum -a 256 "$path"; done | shasum -a 256 | awk '{print $1}')"
note "executable-sha256=$(shasum -a 256 "$app/Contents/MacOS/DK64Recompiled" | awk '{print $1}')"
codesign -d --entitlements :- "$app" 2>&1
