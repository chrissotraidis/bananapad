#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

[[ "$(uname -m)" == "arm64" ]] || die "BananaPad requires an Apple Silicon host"

for command_name in git jq shasum file stat cmake ninja xcodebuild xcrun clang clang++ rustc cargo cpp-16; do
  require_command "$command_name"
done

python_command="$(select_python)"

metal_status="$(xcodebuild -showComponent MetalToolchain -json | jq -r '.status // empty')"
[[ "$metal_status" == "installed" ]] || die "Xcode Metal Toolchain is not installed"

note "host: $(sw_vers -productName) $(sw_vers -productVersion) ($(uname -m))"
note "$(xcodebuild -version | tr '\n' ' ')"
note "$(cmake --version | head -n 1)"
note "ninja $(ninja --version)"
note "$(git --version)"
note "jq $(jq --version)"
note "$($python_command --version) ($python_command)"
note "$(rustc --version)"
note "$(cargo --version)"
note "Metal Toolchain: installed"
