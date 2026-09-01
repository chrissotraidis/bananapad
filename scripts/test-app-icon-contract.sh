#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

icon_set="$BANANAPAD_ROOT/apple/app/Assets.xcassets/AppIcon.appiconset"
icon="$icon_set/AppIcon-1024.png"
provenance="$icon_set/PROVENANCE.md"
expected_hash="e8c1213d036e12f1acd6b388c537ddb72d9dded5a3e7bb52f53731e63410a882"

[[ -f "$icon" && -f "$provenance" ]] || die "app icon or provenance is missing"
[[ "$(shasum -a 256 "$icon" | awk '{print $1}')" == "$expected_hash" ]] || die "app icon identity changed"
[[ "$(sips -g pixelWidth "$icon" | awk '/pixelWidth/ {print $2}')" == "1024" ]] || die "app icon width is not 1024"
[[ "$(sips -g pixelHeight "$icon" | awk '/pixelHeight/ {print $2}')" == "1024" ]] || die "app icon height is not 1024"
[[ "$(sips -g hasAlpha "$icon" | awk '/hasAlpha/ {print $2}')" == "no" ]] || die "app icon must be opaque"
jq -e --arg name "$(basename "$icon")" '.images | any(.filename == $name and .idiom == "universal" and .size == "1024x1024")' "$icon_set/Contents.json" >/dev/null || die "asset catalog does not reference the approved icon"
rg -qF "$expected_hash" "$provenance" || die "provenance does not bind the packaged master"
rg -qi 'no DK64 screenshots|No DK64 screenshots' "$provenance" || die "third-party-art exclusion is missing"

note "app icon contract: pass"
