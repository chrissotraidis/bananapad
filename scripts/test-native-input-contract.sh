#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$script_dir/.." && pwd)"
source_file="$root/apple/core/bananapad_native.cpp"

die() {
    echo "native input contract: $*" >&2
    exit 1
}

[[ -f "$source_file" ]] || die "missing native input adapter"

rg -q '#if defined\(__APPLE__\) && !TARGET_OS_IPHONE' "$source_file" \
    || die "acceptance override is not guarded to desktop Apple targets"
rg -q 'BANANAPAD_TEST_KEY_TAP_FRAMES' "$source_file" \
    || die "acceptance duration environment variable is missing"
rg -q 'parsed >= 1 && parsed <= 240' "$source_file" \
    || die "acceptance duration is not bounded to 1..240"
rg -q 'return static_cast<uint8_t>\(4\);' "$source_file" \
    || die "normal four-frame fallback is missing"
rg -q 'SDL_SCANCODE_T, SDL_SCANCODE_G, SDL_SCANCODE_F, SDL_SCANCODE_H' "$source_file" \
    || die "fine-stick acceptance aliases changed"
rg -q 'SDL_SCANCODE_1, SDL_SCANCODE_2, SDL_SCANCODE_3, SDL_SCANCODE_4' "$source_file" \
    || die "sustained-stick acceptance aliases changed"
rg -q 'SDL_SCANCODE_5, SDL_SCANCODE_6, SDL_SCANCODE_7, SDL_SCANCODE_8' "$source_file" \
    || die "sustained jump-stick acceptance aliases changed"
rg -q 'SDL_SCANCODE_9, SDL_SCANCODE_0, SDL_SCANCODE_MINUS, SDL_SCANCODE_EQUALS' "$source_file" \
    || die "precision jump-stick acceptance aliases changed"
rg -q 'tap_latches\[action\]\.store\(4, std::memory_order_release\)' "$source_file" \
    || die "precision jump-stick aliases no longer release movement after four frames"
rg -q 'test_a_keyboard_binding = SDL_SCANCODE_U' "$source_file" \
    || die "held-A acceptance alias changed"
rg -q 'test_z_keyboard_binding = SDL_SCANCODE_V' "$source_file" \
    || die "held-Z acceptance alias changed"
rg -q 'if \(keyboard_tap_frames\(\) != 4\)' "$source_file" \
    || die "acceptance aliases are no longer default-off"

echo "native input contract: pass"
