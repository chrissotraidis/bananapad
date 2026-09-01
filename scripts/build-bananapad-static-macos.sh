#!/usr/bin/env bash

set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
BANANAPAD_MACOS_PROFILE=static "$script_dir/build-bananapad-macos.sh"
