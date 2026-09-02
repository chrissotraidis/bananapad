#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

require_command cmake
require_command plutil

workspace="${BANANAPAD_WORKSPACE:-$BANANAPAD_ROOT/worktrees/bananapad-static-macos}"
build_dir="${BANANAPAD_BUILD_DIR:-$BANANAPAD_ROOT/generated/build/bananapad-ios-device}"
app="$build_dir/Release/BananaPad.app"
sdl2_source="$BANANAPAD_ROOT/generated/dependencies/sdl2-bananapad"
file_to_c="${BANANAPAD_FILE_TO_C:-$BANANAPAD_ROOT/generated/build/bananapad-static-macos/file_to_c}"
spirv_cross_msl="${BANANAPAD_SPIRV_CROSS_MSL:-$BANANAPAD_ROOT/worktrees/bananapad-static-macos/build/bin/spirv_cross_msl}"
expected_commit="${BANANAPAD_EXPECTED_COMMIT:-$(lock_value '.upstream.promoted.commit')}"
game_set="${BANANAPAD_GAME_SET:-$BANANAPAD_ROOT/generated/aot/current-game}"
patch_set="${BANANAPAD_PATCH_SET:-$BANANAPAD_ROOT/generated/aot/current-patches}"
decompressed_rom="${BANANAPAD_DECOMPRESSED_ROM:-$BANANAPAD_ROOT/generated/rom/donkeykong64.decompressed.us.z64}"
host_tools="${BANANAPAD_HOST_TOOLS:-$BANANAPAD_ROOT/generated/build/host-tools}"
development_team="${BANANAPAD_DEVELOPMENT_TEAM:-}"
reproducible_flags="-ffile-prefix-map=$workspace=BananaPadSource -fdebug-prefix-map=$workspace=BananaPadSource -ffile-prefix-map=$BANANAPAD_ROOT=BananaPadProject -fdebug-prefix-map=$BANANAPAD_ROOT=BananaPadProject"

[[ -e "$workspace/.git" ]] || die "prepared BananaPad worktree is missing; run build-bananapad-static-macos.sh first"
[[ "$(git -C "$workspace" rev-parse HEAD)" == "$expected_commit" ]] || die "BananaPad worktree is not at the expected upstream pin"
"$BANANAPAD_ROOT/scripts/prepare-bananapad-sdl2.sh"
[[ -f "$sdl2_source/CMakeLists.txt" ]] || die "patched BananaPad SDL2 source is missing"
[[ -x "$file_to_c" && -x "$spirv_cross_msl" ]] || die "native renderer build tools are missing"
[[ -d "$game_set/RecompiledFuncs" && -d "$patch_set/RecompiledPatches" ]] || die "generated source sets are missing"
[[ -f "$decompressed_rom" ]] || die "decompressed build ROM is missing"
[[ -x "$host_tools/N64Recomp" && -x "$host_tools/RSPRecomp" ]] || die "host recompilers are missing"

llvm_root="/opt/homebrew/opt/llvm@18/bin"
[[ -x "$llvm_root/clang" && -x "$llvm_root/ld.lld" ]] || die "Homebrew llvm@18 is required"

if [[ ! -d "$workspace/RecompiledFuncs" ]]; then
  cp -R "$game_set/RecompiledFuncs" "$workspace/RecompiledFuncs"
fi
if [[ ! -d "$workspace/RecompiledPatches" ]]; then
  cp -R "$patch_set/RecompiledPatches" "$workspace/RecompiledPatches"
fi
cp "$game_set/rsp/n_aspMain.cpp" "$workspace/rsp/n_aspMain.cpp"
cp "$patch_set/patches/patches.elf" "$workspace/patches/patches.elf"
cp "$patch_set/patches/patches.bin" "$workspace/patches/patches.bin"
ln -sfn "$decompressed_rom" "$workspace/donkeykong64.decompressed.us.z64"
ln -sfn "$host_tools/N64Recomp" "$workspace/N64Recomp"
ln -sfn "$host_tools/RSPRecomp" "$workspace/RSPRecomp"

mkdir -p "$build_dir"
signing_args=(
  -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO
)
if [[ -n "$development_team" ]]; then
  signing_args=(
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=YES
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED=YES
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_STYLE=Automatic
    -DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM="$development_team"
  )
fi

cmake -S "$workspace" -B "$build_dir" -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
  "-DCMAKE_C_FLAGS=$reproducible_flags" \
  "-DCMAKE_CXX_FLAGS=$reproducible_flags" \
  "-DCMAKE_OBJC_FLAGS=$reproducible_flags" \
  "-DCMAKE_OBJCXX_FLAGS=$reproducible_flags" \
  "${signing_args[@]}" \
  -DVCPKG_TARGET_TRIPLET=arm64-ios \
  -DBANANAPAD_NATIVE_SHELL=ON \
  -DBANANAPAD_APPLE_CORE_DIR="$BANANAPAD_ROOT/apple/core" \
  -DBANANAPAD_APPLE_APP_DIR="$BANANAPAD_ROOT/apple/app" \
  -DBANANAPAD_SDL2_SOURCE_DIR="$sdl2_source" \
  -DBANANAPAD_SDL2_STATIC_LIBRARY= \
  -DN64MODERN_NO_DYNAMIC_CODE=ON \
  -DRT64_BUILD_TOOLS=OFF \
  -DFILE_TO_C_PATH="$file_to_c" \
  -DSPIRV_CROSS_MSL_PATH="$spirv_cross_msl" \
  -DPATCHES_C_COMPILER="$llvm_root/clang" \
  -DPATCHES_LD="$llvm_root/ld.lld"

if [[ -n "$development_team" ]]; then
  cmake --build "$build_dir" --config Release --target DK64Recompiled -j "$(sysctl -n hw.ncpu)" \
    -- -allowProvisioningUpdates -allowProvisioningDeviceRegistration
else
  cmake --build "$build_dir" --config Release --target DK64Recompiled -j "$(sysctl -n hw.ncpu)"
fi

[[ -x "$app/BananaPad" ]] || die "device BananaPad.app was not produced"
[[ "$(plutil -extract CFBundleIdentifier raw "$app/Info.plist")" == "com.chrissotraidis.bananapad" ]] \
  || die "unexpected bundle identifier"
file "$app/BananaPad" | grep -q 'arm64' || die "device executable is not arm64"
otool -l "$app/BananaPad" | rg -q 'platform 2' || die "executable is not built for iPhoneOS"
"$BANANAPAD_ROOT/scripts/audit-ios-package.sh" "$app"

if [[ -n "$development_team" ]]; then
  codesign --verify --deep --strict "$app"
  note "verified Apple development signature for team: $development_team"
else
  note "built without signing; set BANANAPAD_DEVELOPMENT_TEAM to create an installable development build"
fi

note "built iOS/iPadOS device app: $app"
note "executable SHA-256: $(shasum -a 256 "$app/BananaPad" | awk '{print $1}')"
