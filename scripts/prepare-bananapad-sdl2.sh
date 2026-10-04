#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

source_checkout="$BANANAPAD_ROOT/ref/paperpad/ref/SDL2"
destination="$BANANAPAD_ROOT/generated/dependencies/sdl2-bananapad"
patch="$BANANAPAD_ROOT/patches/sdl2/ios-controller-uipress-duplication.patch"
# UIKit scene startup for SDL 2.32.10: apps built with the iOS 27 SDK need it to open.
scene_patch="$BANANAPAD_ROOT/patches/sdl2/uikit-scenes.patch"
expected_commit="$(lock_value '.references.sdl2.commit')"

[[ -d "$source_checkout/.git" ]] || die "pinned SDL2 checkout is missing"
[[ "$(git -C "$source_checkout" rev-parse HEAD)" == "$expected_commit" ]] \
  || die "pinned SDL2 checkout is not at the locked commit"
[[ -z "$(git -C "$source_checkout" status --porcelain --untracked-files=no)" ]] \
  || die "refusing to prepare from a dirty SDL2 reference"
[[ -f "$patch" ]] || die "BananaPad SDL2 controller patch is missing"
[[ -f "$scene_patch" ]] || die "BananaPad SDL2 scene patch is missing"

expected_status=" M src/video/uikit/SDL_uikitappdelegate.h
 M src/video/uikit/SDL_uikitappdelegate.m
 M src/video/uikit/SDL_uikitmessagebox.m
 M src/video/uikit/SDL_uikitmodes.m
 M src/video/uikit/SDL_uikitvideo.h
 M src/video/uikit/SDL_uikitvideo.m
 M src/video/uikit/SDL_uikitview.m
 M src/video/uikit/SDL_uikitwindow.m"

is_valid_destination() {
  [[ -d "$destination/.git" ]] || return 1
  [[ "$(git -C "$destination" rev-parse HEAD)" == "$expected_commit" ]] || return 1
  [[ "$(git -C "$destination" status --porcelain --untracked-files=all)" \
      == "$expected_status" ]] || return 1
  git -C "$destination" apply --unidiff-zero --reverse --check "$patch" >/dev/null 2>&1 || return 1
  git -C "$destination" apply --reverse --check "$scene_patch" >/dev/null 2>&1 || return 1
}

if is_valid_destination; then
  note "reusing exactly patched BananaPad SDL2 source: $destination"
  exit 0
fi

mkdir -p "$(dirname "$destination")"
if [[ -e "$destination" ]]; then
  stale="$destination.stale.$(date -u '+%Y%m%dT%H%M%SZ')"
  mv "$destination" "$stale"
  note "archived stale generated SDL2 source: $stale"
fi

temporary="$(mktemp -d "$(dirname "$destination")/.sdl2-bananapad.XXXXXX")"
git -c advice.detachedHead=false clone --no-hardlinks --quiet "$source_checkout" "$temporary"
git -c advice.detachedHead=false -C "$temporary" checkout --quiet --detach "$expected_commit"
git -C "$temporary" apply --unidiff-zero --check "$patch"
git -C "$temporary" apply --unidiff-zero "$patch"
git -C "$temporary" apply --unidiff-zero --reverse --check "$patch"
git -C "$temporary" apply --check "$scene_patch"
git -C "$temporary" apply "$scene_patch"
git -C "$temporary" apply --reverse --check "$scene_patch"
git -C "$temporary" remote set-url --push origin DISABLED
mv "$temporary" "$destination"

is_valid_destination || die "prepared SDL2 source failed exact patch validation"
note "prepared exactly patched BananaPad SDL2 source: $destination"
