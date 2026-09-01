#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

"$BANANAPAD_ROOT/scripts/check-prerequisites.sh" >/dev/null
"$BANANAPAD_ROOT/scripts/verify-sources.sh" >/dev/null
"$BANANAPAD_ROOT/scripts/build-host-tools.sh" >/dev/null

upstream="${BANANAPAD_UPSTREAM_SOURCE:-$BANANAPAD_ROOT/ref/dk64-recompiled}"
host_tools="${BANANAPAD_HOST_TOOLS:-$BANANAPAD_ROOT/generated/build/host-tools}"
n64recomp="$host_tools/N64Recomp"
llvm_root="/opt/homebrew/opt/llvm@18/bin"
patch_cc="$llvm_root/clang"
patch_ld="$llvm_root/ld.lld"
aot_root="${BANANAPAD_AOT_ROOT:-$BANANAPAD_ROOT/generated/aot}"
sets_root="$aot_root/patch-sets"

[[ -e "$upstream/.git" ]] || die "upstream source checkout is missing: $upstream"
[[ -x "$n64recomp" ]] || die "N64Recomp host tool is missing: $n64recomp"
[[ -x "$patch_cc" && -x "$patch_ld" ]] || die "Homebrew llvm@18 is required for MIPS patch generation"

patch_source_manifest="$({
  cd "$upstream"
  find patches -type f -print | LC_ALL=C sort | while IFS= read -r path; do
    printf '%s  %s\n' "$(shasum -a 256 "$path" | awk '{print $1}')" "$path"
  done
})"
identity="$({
  git -C "$upstream" rev-parse HEAD
  git -C "$BANANAPAD_ROOT/ref/toolchain/n64recomp-host" rev-parse HEAD
  printf '%s\n' "$patch_source_manifest"
  shasum -a 256 "$n64recomp" "$upstream/patches.toml" \
    "$upstream/DK64Syms/dump.toml" "$upstream/DK64Syms/data_dump.toml"
  "$patch_cc" --version | head -n 1
  "$patch_ld" --version | head -n 1
} | shasum -a 256 | awk '{print $1}')"

mkdir -p "$sets_root"
work_a="$(mktemp -d "$aot_root/.patch-a.XXXXXX")"
work_b="$(mktemp -d "$aot_root/.patch-b.XXXXXX")"
cleanup() {
  case "$work_a" in "$aot_root"/.patch-a.*) ;; *) die "unsafe first patch cleanup path" ;; esac
  case "$work_b" in "$aot_root"/.patch-b.*) ;; *) die "unsafe second patch cleanup path" ;; esac
  rm -rf -- "$work_a" "$work_b"
}
trap cleanup EXIT

generate_once() {
  local workspace="$1"
  cp -R "$upstream/patches" "$workspace/patches"
  cp "$upstream/patches.toml" "$workspace/patches.toml"
  ln -s "$upstream/lib" "$workspace/lib"
  ln -s "$upstream/DK64Syms" "$workspace/DK64Syms"
  make -C "$workspace/patches" CC="$patch_cc" LD="$patch_ld"
  (cd "$workspace" && "$n64recomp" patches.toml)

  mkdir -p "$workspace/product/patches"
  mv "$workspace/RecompiledPatches" "$workspace/product/RecompiledPatches"
  cp "$workspace/patches/patches.elf" "$workspace/product/patches/patches.elf"
  cp "$workspace/patches/patches.bin" "$workspace/product/patches/patches.bin"
  cp "$workspace/patches/patches.map" "$workspace/product/patches/patches.map"
  (
    cd "$workspace/product"
    find RecompiledPatches patches -type f -print | LC_ALL=C sort | while IFS= read -r path; do
      printf '%s  %s\n' "$(shasum -a 256 "$path" | awk '{print $1}')" "$path"
    done
  ) >"$workspace/product/manifest.sha256"
  printf '%s\n' "$identity" >"$workspace/product/input-identity.sha256"
}

generate_once "$work_a"
generate_once "$work_b"
cmp -s "$work_a/product/manifest.sha256" "$work_b/product/manifest.sha256" || die "patch generation is not deterministic"

set_dir="$sets_root/$identity"
if [[ -e "$set_dir" ]]; then
  cmp -s "$work_a/product/manifest.sha256" "$set_dir/manifest.sha256" || die "existing patch set does not match regenerated output: $identity"
else
  mv "$work_a/product" "$set_dir"
fi
ln -sfn "patch-sets/$identity" "$aot_root/current-patches"

note "input-identity=$identity"
note "patch-files=$(find "$set_dir/RecompiledPatches" -type f | wc -l | tr -d ' ')"
note "patch-manifest-sha256=$(shasum -a 256 "$set_dir/manifest.sha256" | awk '{print $1}')"
note "patch-elf-sha256=$(shasum -a 256 "$set_dir/patches/patches.elf" | awk '{print $1}')"
note "patch-bin-sha256=$(shasum -a 256 "$set_dir/patches/patches.bin" | awk '{print $1}')"
note "deterministic=yes"
