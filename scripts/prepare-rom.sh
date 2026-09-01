#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

[[ $# -eq 2 && "$1" == "--rom" ]] || die "usage: $0 --rom /absolute/path/to/dk64-rom"
source_rom="$2"
[[ "$source_rom" = /* ]] || die "ROM path must be absolute"
[[ -f "$source_rom" ]] || die "ROM file does not exist: $source_rom"

"$BANANAPAD_ROOT/scripts/check-prerequisites.sh" >/dev/null
python_command="$(select_python)"

destination="$BANANAPAD_ROOT/generated/rom/donkeykong64.us.z64"
"$python_command" "$BANANAPAD_ROOT/scripts/prepare_rom.py" "$source_rom" "$destination"
