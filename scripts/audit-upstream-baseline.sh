#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

mode="${1:-}"
[[ -z "$mode" || "$mode" == "--source-artifact-only" ]] || die "use --source-artifact-only or no argument"

require_command codesign
require_command file
require_command git
require_command jq
require_command otool
require_command shasum

reference="$BANANAPAD_ROOT/ref/dk64-recompiled"
tag="$(lock_value '.upstream.promoted.tag')"
commit="$(lock_value '.upstream.promoted.commit')"
app="$BANANAPAD_ROOT/generated/build/upstream-macos-$tag/DK64Recompiled.app"
executable="$app/Contents/MacOS/DK64Recompiled"
support="$HOME/Library/Application Support/DK64Recompiled"
rom="$support/DK64.z64"
save="$support/saves/DK64.bin"

expect_source() {
  local relative="$1"
  local literal="$2"
  grep -Fq "$literal" "$reference/$relative" || die "upstream baseline contract changed: $relative lacks $literal"
}

[[ "$(git -C "$reference" rev-parse HEAD)" == "$commit" ]] || die "upstream reference is not at the promoted pin"
[[ -d "$app" && -x "$executable" ]] || die "upstream baseline app is missing; run build-upstream-macos-baseline.sh"

expect_source src/main/main.cpp 'const std::string version_string = "1.0.1";'
expect_source include/donk_config.h 'inline const std::u8string program_id = u8"DK64Recompiled";'
expect_source src/main/main.cpp '.game_id = u8"DK64",'
expect_source src/main/main.cpp '.mod_game_id = "dk64",'
expect_source src/main/main.cpp '.save_type = recomp::SaveType::Eep16k,'
expect_source src/main/main.cpp 'flags |= SDL_WINDOW_METAL;'
expect_source src/main/main.cpp 'if (!reset_audio(48000)) {'
expect_source lib/RecompFrontend/recompui/src/base/ui_launcher.cpp 'recomp::start_game(this->game_id, {});'
expect_source lib/RecompFrontend/recompinput/src/input_mapping.cpp 'GameInput::A,              { InputField::keyboard(SDL_SCANCODE_SPACE)'
expect_source lib/RecompFrontend/recompinput/src/input_mapping.cpp 'GameInput::START,          { InputField::keyboard(SDL_SCANCODE_RETURN)'
expect_source lib/RecompFrontend/recompinput/src/input_mapping.cpp 'GameInput::A,              { InputField::controller_digital(SDL_CONTROLLER_BUTTON_SOUTH)'
expect_source lib/N64ModernRuntime/librecomp/src/pi.cpp 'const std::u8string save_folder = u8"saves";'
expect_source lib/N64ModernRuntime/librecomp/src/pi.cpp 'return 0x800;'
expect_source lib/N64ModernRuntime/librecomp/src/pi.cpp 'recomp::finalize_output_file_with_backup(ultramodern::get_save_file_path())'
expect_source lib/N64ModernRuntime/librecomp/src/pi.cpp 'read_save_file();'

codesign --verify --deep --strict "$app"
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist")" == "com.github.dk64recompiled" ]] || die "unexpected bundle identifier"
file "$executable" | grep -Fq 'Mach-O 64-bit executable arm64' || die "baseline executable is not native arm64"

entitlements_file="$(mktemp -t bananapad-upstream-entitlements)"
trap 'rm -f "$entitlements_file"' EXIT
codesign -d --entitlements :- "$app" >"$entitlements_file" 2>/dev/null
for entitlement in \
  com.apple.security.cs.allow-jit \
  com.apple.security.cs.allow-unsigned-executable-memory \
  com.apple.security.cs.disable-executable-page-protection \
  com.apple.security.cs.disable-library-validation; do
  [[ "$(/usr/libexec/PlistBuddy -c "Print :$entitlement" "$entitlements_file")" == "true" ]] || die "expected upstream entitlement is absent: $entitlement"
done

maxprot="$(otool -l "$executable" | awk '/segname __TEXT/{seen=1} seen&&/maxprot/{print $2; exit}')"
[[ "$maxprot" == "0x00000007" ]] || die "expected upstream __TEXT maxprot rwx, found $maxprot"
if "$BANANAPAD_ROOT/scripts/check-no-dynamic-code.sh" "$app" >/dev/null 2>&1; then
  die "upstream baseline unexpectedly passed the no-dynamic-code audit; recategorize before relying on this record"
fi

expected_patch_hash="$(lock_value '.upstream.patchSetSha256')"
if [[ "$mode" != "--source-artifact-only" ]]; then
  [[ "$(patch_series_hash)" == "$expected_patch_hash" ]] || die "upstream patch series differs from the lock"
fi

if [[ -f "$rom" ]]; then
  [[ "$(stat -f '%z' "$rom")" == "$(lock_value '.rom.size')" ]] || die "stored upstream ROM size changed"
  [[ "$(shasum "$rom" | awk '{print $1}')" == "$(lock_value '.rom.sha1')" ]] || die "stored upstream ROM identity changed"
  rom_state="verified"
else
  rom_state="absent"
fi

if [[ -f "$save" ]]; then
  save_state="present size=$(stat -f '%z' "$save") sha256=$(shasum -a 256 "$save" | awk '{print $1}')"
else
  save_state="absent"
fi

app_hash="$(cd "$app" && find . -type f -print | LC_ALL=C sort | while IFS= read -r item; do shasum -a 256 "$item"; done | shasum -a 256 | awk '{print $1}')"
note "upstream baseline audit passed"
note "source=$tag $commit"
note "app-sha256=$app_hash"
note "architecture=arm64"
note "bundle-id=com.github.dk64recompiled"
note "dynamic-code-profile=expected-desktop-rwx"
note "rom=$rom_state"
note "save=$save_state"
