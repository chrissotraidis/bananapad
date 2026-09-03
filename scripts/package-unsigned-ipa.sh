#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

require_command codesign
require_command shasum
require_command zip

app="${1:-$BANANAPAD_ROOT/generated/build/bananapad-ios-device/Release/BananaPad.app}"
output="${BANANAPAD_UNSIGNED_IPA_OUTPUT:-$BANANAPAD_ROOT/generated/packages/BananaPad-v0.1.0-preview.2-unsigned.ipa}"
[[ "$app" = /* ]] || app="$BANANAPAD_ROOT/$app"
[[ "$output" = /* ]] || output="$BANANAPAD_ROOT/$output"
[[ -d "$app" && -x "$app/BananaPad" ]] || die "device BananaPad.app is missing: $app"

reference="$BANANAPAD_ROOT/ref/dk64-recompiled"
sdl2_source="$BANANAPAD_ROOT/generated/dependencies/sdl2-bananapad"
[[ -f "$reference/LICENSE" && -f "$reference/COPYING" ]] || die "pinned DK64Recompiled licenses are missing"
[[ -f "$sdl2_source/LICENSE.txt" ]] || die "prepared pinned SDL2 license is missing"
[[ -f "$BANANAPAD_ROOT/docs/INSTALL_IPA.md" ]] || die "IPA installation guide is missing"
[[ -f "$BANANAPAD_ROOT/docs/RIGHTS-STATUS.md" ]] || die "rights status is missing"
"$BANANAPAD_ROOT/scripts/audit-ios-package.sh" "$app" >/dev/null

package_root="$(mktemp -d "${TMPDIR:-/tmp}/bananapad-package.XXXXXX")"
cleanup() {
  case "$package_root" in
    "${TMPDIR:-/tmp}"/bananapad-package.*) rm -rf "$package_root" ;;
    *) die "refusing unsafe package cleanup path" ;;
  esac
}
trap cleanup EXIT

staged_app="$package_root/Payload/BananaPad.app"
mkdir -p "$staged_app/Licenses/DK64Recompiled" "$staged_app/Licenses/SDL2" "$(dirname "$output")"
ditto "$app" "$staged_app"

# Release IPAs are self-signable inputs. Never convey the maintainer's local
# development identity, provisioning profile, or signature metadata.
codesign --remove-signature "$staged_app" 2>/dev/null || true
rm -rf "$staged_app/_CodeSignature"
rm -f "$staged_app/embedded.mobileprovision"

ditto "$BANANAPAD_ROOT/docs/INSTALL_IPA.md" "$staged_app/INSTALL_IPA.md"
ditto "$BANANAPAD_ROOT/docs/RIGHTS-STATUS.md" "$staged_app/RIGHTS-STATUS.md"
ditto "$BANANAPAD_ROOT/COPYING" "$staged_app/COPYING"
ditto "$sdl2_source/LICENSE.txt" "$staged_app/Licenses/SDL2/LICENSE.txt"

# Preserve the complete license/notices set from the exact pinned game/runtime
# graph. Paths remain namespaced so same-named transitive licenses cannot
# overwrite one another.
while IFS= read -r source; do
  relative="${source#"$reference"/}"
  destination="$staged_app/Licenses/DK64Recompiled/$relative"
  mkdir -p "$(dirname "$destination")"
  ditto "$source" "$destination"
done < <(find "$reference" -type f \( \
  -iname 'license' -o -iname 'license.*' -o \
  -iname 'copying' -o -iname 'copying.*' -o \
  -iname 'copyright' -o -iname 'copyright.*' -o \
  -iname 'notice' -o -iname 'notice.*' -o \
  -iname 'licenses' -o -iname 'third_party_notices*' \
  \) -print | LC_ALL=C sort)

find "$package_root/Payload" -exec touch -h -t 202001010000 {} +
archive_tmp="$package_root/BananaPad.ipa"
(
  cd "$package_root"
  export COPYFILE_DISABLE=1
  find Payload -print | LC_ALL=C sort | zip -X -q "$archive_tmp" -@
)
mv -f "$archive_tmp" "$output"

"$BANANAPAD_ROOT/scripts/audit-ios-package.sh" "$output"
(
  cd "$(dirname "$output")"
  shasum -a 256 "$(basename "$output")" >"$(basename "$output").sha256"
)

note "unsigned ROM-free IPA: $output"
note "app executable SHA-256: $(shasum -a 256 "$app/BananaPad" | awk '{print $1}')"
cat "$output.sha256"
note "This IPA must be re-signed with the user's own Apple credentials before installation."
