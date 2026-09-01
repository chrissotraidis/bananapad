#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

clone_reference() {
  local key="$1"
  local directory="$2"
  local url commit

  url="$(lock_value ".references.${key}.url")"
  commit="$(lock_value ".references.${key}.commit")"

  if [[ ! -d "$directory/.git" ]]; then
    [[ ! -e "$directory" ]] || die "refusing to replace non-Git path: $directory"
    git clone --recursive "$url" "$directory"
  fi

  [[ -z "$(git -C "$directory" status --porcelain --untracked-files=no)" ]] || die "refusing to alter dirty reference: $directory"
  git -C "$directory" cat-file -e "${commit}^{commit}" 2>/dev/null || git -C "$directory" fetch --no-tags origin "$commit"
  git -C "$directory" checkout --detach "$commit"
  git -C "$directory" submodule update --init --recursive
  git -C "$directory" remote set-url --push origin DISABLED
  git -C "$directory" submodule foreach --recursive 'git remote get-url origin >/dev/null 2>&1 && git remote set-url --push origin DISABLED || :' >/dev/null
}

mkdir -p "$BANANAPAD_ROOT/ref"
clone_reference dk64Recompiled "$BANANAPAD_ROOT/ref/dk64-recompiled"
clone_reference paperpad "$BANANAPAD_ROOT/ref/paperpad"
clone_reference sdl2 "$BANANAPAD_ROOT/ref/paperpad/ref/SDL2"
clone_reference sunpad "$BANANAPAD_ROOT/ref/sunpad"
clone_reference n64RecompHostTools "$BANANAPAD_ROOT/ref/toolchain/n64recomp-host"

"$BANANAPAD_ROOT/scripts/verify-sources.sh"
