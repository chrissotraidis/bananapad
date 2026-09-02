#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

require_command cmake
require_command codesign
require_command jq
require_command ps
require_command xcrun

mode="${1:---build}"
[[ "$mode" == "--build" || "$mode" == "--run" || "$mode" == "--smoke" ]] || \
  die "use --build, --run, or --smoke"

workspace="${BANANAPAD_WORKSPACE:-$BANANAPAD_ROOT/worktrees/bananapad-static-macos}"
build_dir="${BANANAPAD_BUILD_DIR:-$BANANAPAD_ROOT/generated/build/bananapad-ios-simulator}"
app="$build_dir/Release/BananaPad.app"
sdl2_source="$BANANAPAD_ROOT/generated/dependencies/sdl2-bananapad"
file_to_c="${BANANAPAD_FILE_TO_C:-$BANANAPAD_ROOT/generated/build/bananapad-static-macos/file_to_c}"
spirv_cross_msl="${BANANAPAD_SPIRV_CROSS_MSL:-$BANANAPAD_ROOT/worktrees/bananapad-static-macos/build/bin/spirv_cross_msl}"
promoted="$(lock_value '.upstream.promoted.commit')"
expected_commit="${BANANAPAD_EXPECTED_COMMIT:-$promoted}"
game_set="${BANANAPAD_GAME_SET:-$BANANAPAD_ROOT/generated/aot/current-game}"
patch_set="${BANANAPAD_PATCH_SET:-$BANANAPAD_ROOT/generated/aot/current-patches}"
decompressed_rom="${BANANAPAD_DECOMPRESSED_ROM:-$BANANAPAD_ROOT/generated/rom/donkeykong64.decompressed.us.z64}"
host_tools="${BANANAPAD_HOST_TOOLS:-$BANANAPAD_ROOT/generated/build/host-tools}"
reproducible_flags="-ffile-prefix-map=$workspace=BananaPadSource -fdebug-prefix-map=$workspace=BananaPadSource -ffile-prefix-map=$BANANAPAD_ROOT=BananaPadProject -fdebug-prefix-map=$BANANAPAD_ROOT=BananaPadProject"

[[ -e "$workspace/.git" ]] || die "prepared BananaPad worktree is missing; run scripts/build-bananapad-static-macos.sh first"
[[ "$(git -C "$workspace" rev-parse HEAD)" == "$expected_commit" ]] || die "BananaPad worktree is not at the expected DK64Recompiled pin"
"$BANANAPAD_ROOT/scripts/prepare-bananapad-sdl2.sh"
[[ -f "$sdl2_source/CMakeLists.txt" ]] || die "patched BananaPad SDL2 source is missing"
[[ -x "$file_to_c" ]] || die "native file_to_c is missing; run scripts/build-bananapad-static-macos.sh first"
[[ -x "$spirv_cross_msl" ]] || die "native spirv_cross_msl is missing; run scripts/build-bananapad-static-macos.sh first"
[[ -d "$game_set/RecompiledFuncs" && -d "$patch_set/RecompiledPatches" ]] || die "G1 generated source sets are missing"
[[ -f "$decompressed_rom" ]] || die "decompressed build ROM is missing"
[[ -x "$host_tools/N64Recomp" && -x "$host_tools/RSPRecomp" ]] || die "host recompilers are missing"

llvm_root="/opt/homebrew/opt/llvm@18/bin"
[[ -x "$llvm_root/clang" && -x "$llvm_root/ld.lld" ]] || die "Homebrew llvm@18 is required for DK64 patch generation"

if [[ "$mode" != "--smoke" ]]; then
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
  cmake -S "$workspace" -B "$build_dir" -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT=iphonesimulator \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
    "-DCMAKE_C_FLAGS=$reproducible_flags" \
    "-DCMAKE_CXX_FLAGS=$reproducible_flags" \
    "-DCMAKE_OBJC_FLAGS=$reproducible_flags" \
    "-DCMAKE_OBJCXX_FLAGS=$reproducible_flags" \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO \
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

  cmake --build "$build_dir" --config Release --target DK64Recompiled -j "$(sysctl -n hw.ncpu)"
fi

[[ -x "$app/BananaPad" ]] || die "Simulator BananaPad.app was not produced"
codesign --force --deep --sign - "$app"
codesign --verify --deep --strict "$app"
[[ "$(plutil -extract CFBundleIdentifier raw "$app/Info.plist")" == "com.chrissotraidis.bananapad" ]] || die "unexpected bundle identifier"
file "$app/BananaPad" | grep -q 'arm64' || die "Simulator executable is not arm64"

note "built Simulator app: $app"
note "executable SHA-256: $(shasum -a 256 "$app/BananaPad" | awk '{print $1}')"

[[ "$mode" == "--run" || "$mode" == "--smoke" ]] || exit 0

udid="${BANANAPAD_SIMULATOR_UDID:-}"
if [[ -z "$udid" ]]; then
  mapfile_output="$(xcrun simctl list devices booted -j | jq -r '.devices[][] | select(.state == "Booted" and (.name | test("iPad"))) | .udid')"
  [[ "$(printf '%s\n' "$mapfile_output" | sed '/^$/d' | wc -l | tr -d ' ')" == "1" ]] || \
    die "boot exactly one iPad Simulator or set BANANAPAD_SIMULATOR_UDID"
  udid="$mapfile_output"
fi

xcrun simctl install "$udid" "$app"

if [[ -n "${BANANAPAD_ROM_PATH:-}" ]]; then
  [[ -f "$BANANAPAD_ROM_PATH" ]] || die "BANANAPAD_ROM_PATH is not a file"
  expected_sha1="$(lock_value '.rom.sha1')"
  actual_sha1="$(shasum -a 1 "$BANANAPAD_ROM_PATH" | awk '{print $1}')"
  [[ "$actual_sha1" == "$expected_sha1" ]] || die "BANANAPAD_ROM_PATH is not the locked DK64 US 1.0 ROM"
  data_container="$(xcrun simctl get_app_container "$udid" com.chrissotraidis.bananapad data)"
  rom_dir="$data_container/Library/Application Support/PaperPad"
  mkdir -p "$rom_dir"
  cp "$BANANAPAD_ROM_PATH" "$rom_dir/DK64.z64"
  chmod 600 "$rom_dir/DK64.z64"
  note "installed verified private ROM into the Simulator data container"
fi

launch_output="$(xcrun simctl launch --terminate-running-process "$udid" com.chrissotraidis.bananapad)"
printf '%s\n' "$launch_output"
pid="$(printf '%s\n' "$launch_output" | awk -F ': ' 'NF == 2 {print $2}')"
[[ "$pid" =~ ^[0-9]+$ ]] || die "could not determine the Simulator process id"

# A launch that immediately crashes is not a passing smoke test.
sleep 20
launch_command="$(ps -p "$pid" -o command= 2>/dev/null || true)"
case "$launch_command" in
  *"/BananaPad.app/BananaPad"*) ;;
  *) die "BananaPad exited during the Simulator smoke window" ;;
esac

receipt_dir="$BANANAPAD_ROOT/generated/validation"
run_receipt_dir="$receipt_dir/ios-simulator-runs"
last_receipt="$receipt_dir/ios-simulator-last-run.json"
mkdir -p "$receipt_dir"
workspace_commit="$(git -C "$workspace" rev-parse HEAD)"
workspace_hash="$(recursive_worktree_hash "$workspace")"
app_hash="$(shasum -a 256 "$app/BananaPad" | awk '{print $1}')"
product_hash="$(product_source_hash)"
game_manifest_hash="$(shasum -a 256 "$game_set/manifest.sha256" | awk '{print $1}')"
patch_manifest_hash="$(shasum -a 256 "$patch_set/manifest.sha256" | awk '{print $1}')"
decompressed_rom_hash="$(shasum -a 256 "$decompressed_rom" | awk '{print $1}')"
rom_sha1=""
if [[ -n "${BANANAPAD_ROM_PATH:-}" ]]; then
  rom_sha1="$(shasum -a 1 "$BANANAPAD_ROM_PATH" | awk '{print $1}')"
fi
tested_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
receipt_stamp="$(date -u '+%Y%m%dT%H%M%SZ')"
mkdir -p "$run_receipt_dir"
receipt="$run_receipt_dir/$app_hash-$workspace_hash-$receipt_stamp-pid$pid.json"
[[ ! -e "$receipt" ]] || die "Simulator run receipt already exists"
tmp="$(mktemp "$run_receipt_dir/.ios-simulator-run.XXXXXX")"
jq -n \
  --arg workspace "$workspace" \
  --arg commit "$workspace_commit" \
  --arg worktree_hash "$workspace_hash" \
  --arg app "$app" \
  --arg app_hash "$app_hash" \
  --arg product_hash "$product_hash" \
  --arg simulator_udid "$udid" \
  --arg rom_sha1 "$rom_sha1" \
  --arg pid "$pid" \
  --arg tested_at "$tested_at" \
  --arg game_manifest_hash "$game_manifest_hash" \
  --arg patch_manifest_hash "$patch_manifest_hash" \
  --arg decompressed_rom_hash "$decompressed_rom_hash" \
  '{schemaVersion:4,result:"pass",workspace:$workspace,commit:$commit,recursiveWorktreeSha256:$worktree_hash,productSourceSha256:$product_hash,generatedGameManifestSha256:$game_manifest_hash,generatedPatchManifestSha256:$patch_manifest_hash,decompressedRomSha256:$decompressed_rom_hash,app:$app,appExecutableSha256:$app_hash,simulatorUdid:$simulator_udid,romSha1:$rom_sha1,pid:($pid | tonumber),smokeSeconds:20,testedAt:$tested_at}' > "$tmp"
chmod 600 "$tmp"
mv "$tmp" "$receipt"

tmp="$(mktemp "$receipt_dir/ios-simulator-last-run.XXXXXX")"
cp "$receipt" "$tmp"
chmod 600 "$tmp"
mv "$tmp" "$last_receipt"
note "Simulator smoke passed for PID $pid; immutable receipt: $receipt"
note "latest-run receipt: $last_receipt"
