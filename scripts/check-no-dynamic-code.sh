#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

[[ $# -eq 1 ]] || die "usage: $0 <Mach-O-or-.app>"
target="$1"
[[ -e "$target" ]] || die "target does not exist: $target"

require_command codesign
require_command nm
require_command otool

if [[ -d "$target" && "$target" == *.app ]]; then
  if [[ -f "$target/Contents/Info.plist" ]]; then
    plist="$target/Contents/Info.plist"
    executable_name="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist")"
    binary="$target/Contents/MacOS/$executable_name"
  else
    plist="$target/Info.plist"
    executable_name="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist")"
    binary="$target/$executable_name"
  fi
else
  binary="$target"
fi

[[ -f "$binary" ]] || die "Mach-O executable not found: $binary"
file "$binary" | grep -q 'Mach-O' || die "not a Mach-O executable: $binary"

entitlements="$(codesign -d --entitlements :- "$target" 2>/dev/null || true)"
for forbidden in \
  com.apple.security.cs.allow-jit \
  com.apple.security.cs.allow-unsigned-executable-memory \
  com.apple.security.cs.disable-executable-page-protection \
  com.apple.security.cs.disable-library-validation; do
  if printf '%s\n' "$entitlements" | grep -q "$forbidden"; then
    die "forbidden entitlement found: $forbidden"
  fi
done

if otool -l "$binary" | grep -Eq '^[[:space:]]+(maxprot|initprot)[[:space:]]+0x0*7$'; then
  die "writable-executable Mach-O segment found"
fi

if strings "$binary" | grep -Eiq 'LiveRecomp|libtcc|Tiny C Compiler|allow-jit|unsigned-executable-memory|offline\.nrm|mod_binary\.bin|FailedToLoadNativeLibrary'; then
  die "dynamic-code marker found in executable strings"
fi

# Platform libraries legitimately use dlopen/dlsym, and librecomp uses mprotect
# for non-executable RDRAM guard/protection state. Reject the mod/JIT machinery
# itself instead of treating those broad imports as proof of executable pages.
if nm "$binary" 2>/dev/null | c++filt | grep -Eiq \
  'recomp::mods::(LiveRecompilerCodeHandle|DynamicLibraryCodeHandle)|apply_regenlist|regenerate_with_hooks|load_mod_code|(^|[[:space:]])patch_func\('; then
  die "compiled live-recompiler or native code-mod machinery found"
fi

if otool -L "$binary" | grep -Eiq 'libtcc|LiveRecomp'; then
  die "dynamic-code runtime linkage found"
fi

note "no-dynamic-code audit passed: $target"
