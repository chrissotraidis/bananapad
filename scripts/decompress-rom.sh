#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

"$BANANAPAD_ROOT/scripts/check-prerequisites.sh" >/dev/null
"$BANANAPAD_ROOT/scripts/verify-sources.sh" >/dev/null

upstream_source="${BANANAPAD_UPSTREAM_SOURCE:-$BANANAPAD_ROOT/ref/dk64-recompiled}"
source_file="$upstream_source/decompressor.cpp"
normalized_rom="${BANANAPAD_NORMALIZED_ROM:-$BANANAPAD_ROOT/generated/rom/donkeykong64.us.z64}"
build_dir="${BANANAPAD_DECOMPRESSOR_BUILD_DIR:-$BANANAPAD_ROOT/generated/build/dk64-decompressor}"
destination="${BANANAPAD_DECOMPRESSED_ROM:-$BANANAPAD_ROOT/generated/rom/donkeykong64.decompressed.us.z64}"
generated_rom_dir="$(dirname "$destination")"
binary="$build_dir/dk64-decompressor"

[[ -e "$upstream_source/.git" ]] || die "upstream source checkout is missing: $upstream_source"
[[ -f "$source_file" ]] || die "upstream decompressor source is missing: $source_file"
[[ -f "$normalized_rom" ]] || die "normalized ROM is missing; run scripts/prepare-rom.sh first"
[[ "$(stat -f '%z' "$normalized_rom")" == "$(lock_value '.rom.size')" ]] || die "normalized ROM has the wrong size"
[[ "$(shasum -a 1 "$normalized_rom" | awk '{print $1}')" == "$(lock_value '.rom.sha1')" ]] || die "normalized ROM has the wrong SHA-1"

mkdir -p "$build_dir" "$generated_rom_dir"
clang++ -std=c++17 -O2 "$source_file" -lz -o "$binary"

run_a="$(mktemp -d "$generated_rom_dir/.decompress-a.XXXXXX")"
run_b="$(mktemp -d "$generated_rom_dir/.decompress-b.XXXXXX")"
cleanup() {
  case "$run_a" in "$generated_rom_dir"/.decompress-a.*) ;; *) die "unsafe first decompression cleanup path" ;; esac
  case "$run_b" in "$generated_rom_dir"/.decompress-b.*) ;; *) die "unsafe second decompression cleanup path" ;; esac
  rm -rf -- "$run_a" "$run_b"
}
trap cleanup EXIT

(cd "$run_a" && "$binary" "$normalized_rom")
(cd "$run_b" && "$binary" "$normalized_rom")

first="$run_a/donkeykong64.decompressed.us.z64"
second="$run_b/donkeykong64.decompressed.us.z64"
[[ -f "$first" && -f "$second" ]] || die "decompressor did not create both expected outputs"
cmp -s "$first" "$second" || die "decompressed ROM is not deterministic"

temporary="$generated_rom_dir/.donkeykong64.decompressed.us.z64.tmp"
cp "$first" "$temporary"
chmod 600 "$temporary"
mv -f "$temporary" "$destination"

note "decompressor-sha256=$(shasum -a 256 "$binary" | awk '{print $1}')"
note "source-sha256=$(shasum -a 256 "$source_file" | awk '{print $1}')"
note "decompressed=$destination"
note "size=$(stat -f '%z' "$destination")"
note "sha1=$(shasum -a 1 "$destination" | awk '{print $1}')"
note "sha256=$(shasum -a 256 "$destination" | awk '{print $1}')"
note "deterministic=yes"
