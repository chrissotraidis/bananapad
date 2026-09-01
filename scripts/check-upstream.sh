#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

require_command git
require_command jq

url="$(lock_value '.references.dk64Recompiled.url')"
promoted="$(lock_value '.upstream.promoted.commit')"
promoted_tag="$(lock_value '.upstream.promoted.tag')"

main_line="$(git ls-remote --symref "$url" HEAD refs/heads/main | awk '$2 == "refs/heads/main" && $1 != "ref:" {print $1; exit}')"
[[ -n "$main_line" ]] || die "could not resolve upstream main"

tags="$(git ls-remote --tags --refs "$url")"
latest_tag="$(printf '%s\n' "$tags" | awk '{sub("refs/tags/", "", $2); print $2}' | sort -V | tail -n 1)"
latest_tag_commit="$(printf '%s\n' "$tags" | awk -v wanted="refs/tags/$latest_tag" '$2 == wanted {print $1; exit}')"

note "promoted: $promoted_tag $promoted"
note "latest stable: $latest_tag $latest_tag_commit"
note "upstream main: $main_line"

if [[ "$latest_tag_commit" != "$promoted" ]]; then
  note "new stable candidate available: $latest_tag"
else
  note "promoted pin is the latest stable tag"
fi

if [[ "$main_line" != "$promoted" ]]; then
  note "main differs from promoted; inspect and categorize before staging"
fi
