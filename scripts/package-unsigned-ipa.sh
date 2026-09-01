#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

require_command codesign
require_command ditto
require_command shasum

app="${1:-$BANANAPAD_ROOT/generated/build/bananapad-ios-device/Release/BananaPad.app}"
[[ -d "$app" && -x "$app/BananaPad" ]] || die "unsigned device BananaPad.app is missing: $app"

if codesign --verify --deep --strict "$app" >/dev/null 2>&1; then
  die "refusing to label a signed app as an unsigned IPA"
fi

"$BANANAPAD_ROOT/scripts/audit-ios-package.sh" "$app" >/dev/null
app_hash="$(shasum -a 256 "$app/BananaPad" | awk '{print $1}')"
package_dir="$BANANAPAD_ROOT/generated/packages"
ipa="$package_dir/BananaPad-unsigned-$app_hash.ipa"
if [[ -e "$ipa" ]]; then
  "$BANANAPAD_ROOT/scripts/audit-ios-package.sh" "$ipa" >/dev/null
  note "reusing audited private ROM-free unsigned IPA: $ipa"
  note "app executable SHA-256: $app_hash"
  note "IPA SHA-256: $(shasum -a 256 "$ipa" | awk '{print $1}')"
  exit 0
fi

package_root="$(mktemp -d "${TMPDIR:-/tmp}/bananapad-unsigned-ipa.XXXXXX")"
cleanup() {
  case "$package_root" in
    "${TMPDIR:-/tmp}"/bananapad-unsigned-ipa.*) rm -rf "$package_root" ;;
    *) die "refusing unsafe package cleanup path" ;;
  esac
}
trap cleanup EXIT

mkdir -p "$package_root/Payload" "$package_dir"
ditto "$app" "$package_root/Payload/BananaPad.app"
temporary_ipa="$package_root/BananaPad.ipa"
ditto -c -k --sequesterRsrc --keepParent "$package_root/Payload" "$temporary_ipa"
"$BANANAPAD_ROOT/scripts/audit-ios-package.sh" "$temporary_ipa" >/dev/null
chmod 600 "$temporary_ipa"
mv "$temporary_ipa" "$ipa"

note "created private ROM-free unsigned IPA: $ipa"
note "app executable SHA-256: $app_hash"
note "IPA SHA-256: $(shasum -a 256 "$ipa" | awk '{print $1}')"
note "publication remains prohibited until the release gate is explicitly approved"
