#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

[[ $# -eq 1 ]] || die "usage: $0 <BananaPad.app-or.ipa>"
package="$1"
[[ -e "$package" ]] || die "package does not exist: $package"

audit_root="$(mktemp -d "${TMPDIR:-/tmp}/bananapad-package-audit.XXXXXX")"
cleanup() {
  case "$audit_root" in
    "${TMPDIR:-/tmp}"/bananapad-package-audit.*) rm -rf "$audit_root" ;;
    *) die "refusing unsafe audit cleanup path" ;;
  esac
}
trap cleanup EXIT

is_ipa=false
if [[ -d "$package" && "$package" == *.app ]]; then
  app="$package"
elif [[ -f "$package" && "$package" == *.ipa ]]; then
  is_ipa=true
  unzip -tq "$package" >/dev/null || die "IPA ZIP integrity check failed"
  entries="$(unzip -Z1 "$package")"
  if printf '%s\n' "$entries" | rg -q '(^|/)\.\.(/|$)|^/|(^|/)__MACOSX(/|$)'; then
    die "IPA contains an unsafe archive path"
  fi
  unzip -q "$package" -d "$audit_root"
  [[ "$(find "$audit_root/Payload" -mindepth 1 -maxdepth 1 -type d -name '*.app' | wc -l | tr -d ' ')" == 1 ]] || \
    die "IPA must contain exactly one Payload app"
  app="$(find "$audit_root/Payload" -mindepth 1 -maxdepth 1 -type d -name '*.app' -print -quit)"
else
  die "expected an .app directory or .ipa file"
fi

executable="$app/BananaPad"
[[ -x "$executable" && -f "$app/Info.plist" ]] || die "BananaPad executable or Info.plist is missing"

failures=0
while IFS= read -r -d '' path; do
  relative="${path#"$app"/}"
  case "$relative" in
    *.z64|*.v64|*.n64|*.rom|*.eep|*.sra|*.fla|*.sav|*.save|*.crash|*.dmp|*.log|*.p12|*.cer|*.key|*RecompiledFuncs*|*RecompiledPatches*|*n_aspMain.cpp*|*recomp_overlays.inl*)
      printf 'unsafe package content: %s\n' "$relative" >&2
      failures=$((failures + 1))
      ;;
  esac
  [[ -f "$path" ]] || continue
  magic="$(od -An -tx1 -N4 "$path" 2>/dev/null | tr -d ' \n')"
  case "$magic" in
    80371240|37804012|40123780)
      printf 'Nintendo 64 ROM magic in package: %s\n' "$relative" >&2
      failures=$((failures + 1))
      ;;
  esac
done < <(find "$app" -print0)
(( failures == 0 )) || die "$failures unsafe package item(s) found"

[[ "$(lipo -archs "$executable")" == arm64 ]] || die "app executable is not arm64-only"
xcrun_tool="$(command -v xcrun)"
[[ -x /usr/bin/xcrun ]] && xcrun_tool=/usr/bin/xcrun
"$xcrun_tool" vtool -show-build "$executable" | rg -q 'platform +IOS$' || die "app is not an iPhoneOS product"
"$xcrun_tool" vtool -show-build "$executable" | rg -q 'minos +15\.0$' || die "app minimum OS is not iOS 15.0"
[[ "$(plutil -extract CFBundleIdentifier raw "$app/Info.plist")" == com.chrissotraidis.bananapad ]] || die "unexpected bundle identifier"
[[ "$(plutil -extract CFBundleShortVersionString raw "$app/Info.plist")" == 0.1.0 ]] || die "unexpected app version"
[[ "$(plutil -extract CFBundleVersion raw "$app/Info.plist")" == 2 ]] || die "unexpected app build number"
[[ "$(plutil -extract MinimumOSVersion raw "$app/Info.plist")" == 15.0 ]] || die "unexpected minimum OS"
[[ "$(plutil -extract ITSAppUsesNonExemptEncryption raw "$app/Info.plist")" == false ]] || die "unexpected encryption declaration"
plutil -lint "$app/PrivacyInfo.xcprivacy" >/dev/null || die "privacy manifest is invalid"
[[ "$(plutil -extract NSPrivacyTracking raw "$app/PrivacyInfo.xcprivacy")" == false ]] || die "privacy manifest unexpectedly declares tracking"

unexpected_runtime="$(otool -L "$executable" | awk 'NR > 1 { print $1 }' | rg -v '^(/System/Library/|/usr/lib/)' || true)"
[[ -z "$unexpected_runtime" ]] || die "app has an unbundled runtime dependency: $unexpected_runtime"
otool -l "$executable" | rg -q 'cmd LC_RPATH' && die "app executable contains a runtime search path"

if [[ "$is_ipa" == true ]]; then
  for required in \
    ThirdPartyNotices.txt PrivacyInfo.xcprivacy INSTALL_IPA.md RIGHTS-STATUS.md COPYING \
    Licenses/DK64Recompiled/LICENSE Licenses/DK64Recompiled/COPYING \
    Licenses/DK64Recompiled/lib/N64ModernRuntime/COPYING \
    Licenses/DK64Recompiled/lib/N64ModernRuntime/N64Recomp/LICENSE \
    Licenses/DK64Recompiled/lib/rt64/LICENSE Licenses/SDL2/LICENSE.txt; do
    [[ -f "$app/$required" ]] || die "required release file is missing: $required"
  done
  [[ ! -d "$app/_CodeSignature" && ! -f "$app/embedded.mobileprovision" ]] || die "unsigned IPA contains signing material"
  codesign --verify --strict "$app" >/dev/null 2>&1 && die "unsigned IPA app is still signed"
  otool -l "$executable" | rg -q 'cmd LC_CODE_SIGNATURE' && die "unsigned IPA executable still contains a code signature"
  cmp -s "$BANANAPAD_ROOT/apple/app/ThirdPartyNotices.txt" "$app/ThirdPartyNotices.txt" || die "bundled notices differ from source"
  personal_path_pattern="/U""sers/|/Volumes/|/private/var/folders/|github_pat_|gh[pousr]_|AKIA[0-9A-Z]{16}"
  if LC_ALL=C strings -a "$executable" | rg -q "$personal_path_pattern"; then
    die "app executable contains a personal build path or likely credential"
  fi
fi

"$BANANAPAD_ROOT/scripts/check-no-dynamic-code.sh" "$app"
note "iOS package audit passed: $package"
