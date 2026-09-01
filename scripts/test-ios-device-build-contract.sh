#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

build_script="$BANANAPAD_ROOT/scripts/build-bananapad-ios-device.sh"

[[ -x "$build_script" ]] || die "iOS device build script is missing or not executable"
rg -q -- '-DCMAKE_OSX_SYSROOT=iphoneos' "$build_script" \
  || die "device build must target iphoneos"
rg -q -- '-DCMAKE_OSX_ARCHITECTURES=arm64' "$build_script" \
  || die "device build must target arm64"
rg -q -- '-DCMAKE_OSX_DEPLOYMENT_TARGET=15.0' "$build_script" \
  || die "device build must preserve the iOS 15 deployment floor"
rg -q -- '-DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO' "$build_script" \
  || die "reproducible build route must not require a local signing identity"
rg -q 'BANANAPAD_DEVELOPMENT_TEAM' "$build_script" \
  || die "device build must expose the optional local signing handoff"
rg -q -- '-allowProvisioningUpdates' "$build_script" \
  || die "signed build must support automatic development provisioning"
! rg -q 'native_build_args' "$build_script" \
  || die "device build must not expand an empty argument array under Bash strict mode"
rg -q -- '-DN64MODERN_NO_DYNAMIC_CODE=ON' "$build_script" \
  || die "device build must use the AOT-only profile"
rg -q 'audit-ios-package\.sh' "$build_script" \
  || die "device build must run the package/no-dynamic-code audit"
! rg -q 'DonkeyKong64|DK64\.z64|\.v64|\.n64' "$build_script" \
  || die "device build must not package or copy a private ROM"

install_script="$BANANAPAD_ROOT/scripts/install-bananapad-ios-device.sh"
[[ -x "$install_script" ]] || die "physical-device install script is missing or not executable"
rg -q 'devicectl device install app' "$install_script" \
  || die "physical install must use the supported devicectl route"
rg -q 'codesign --verify --deep --strict' "$install_script" \
  || die "physical install must reject an unsigned/invalid app"
rg -q 'audit-ios-package\.sh' "$install_script" \
  || die "physical install must re-audit the exact app"

preflight_script="$BANANAPAD_ROOT/scripts/preflight-bananapad-device-acceptance.sh"
[[ -x "$preflight_script" ]] || die "physical acceptance preflight script is missing or not executable"
rg -q 'codesign --verify --deep --strict' "$preflight_script" \
  || die "physical acceptance preflight must reject an invalid signature"
rg -q 'devicectl device info details' "$preflight_script" \
  || die "physical acceptance preflight must resolve the explicit device"
rg -q 'executableSha256' "$preflight_script" \
  || die "physical acceptance preflight must bind the executable identity"
rg -q 'bundleManifestSha256' "$preflight_script" \
  || die "physical acceptance preflight must bind the signed bundle contents"
rg -q 'pending-hands-on-acceptance' "$preflight_script" \
  || die "physical acceptance preflight must not claim hands-on success"
rg -q 'Z\+C-Up' "$preflight_script" \
  || die "physical acceptance worksheet must cover the required touch chords"
rg -q '90-minute release soak' "$preflight_script" \
  || die "physical acceptance worksheet must cover sustained device operation"

package_script="$BANANAPAD_ROOT/scripts/package-unsigned-ipa.sh"
[[ -x "$package_script" ]] || die "unsigned IPA packaging script is missing or not executable"
rg -q 'audit-ios-package\.sh' "$package_script" \
  || die "unsigned IPA packaging must audit the source app and package"
rg -q 'Payload/BananaPad\.app' "$package_script" \
  || die "unsigned IPA packaging must use the standard Payload app layout"
rg -q 'codesign --verify --deep --strict' "$package_script" \
  || die "unsigned IPA packaging must reject a signed input"

note "iOS/iPadOS device build contract: pass"
