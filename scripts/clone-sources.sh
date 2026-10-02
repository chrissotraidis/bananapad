#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

# A download that stopped partway (for example empty submodule folders) or local changes would
# stop every later run. Keep that folder under a new name, never delete it, and download again.
move_aside() {
  local directory="$1" earlier
  earlier="${directory}.earlier-$(date +%Y%m%d-%H%M%S)"
  mv "$directory" "$earlier"
  note "${directory#"$BANANAPAD_ROOT"/} was incomplete or changed, maybe from a download that stopped partway."
  note "Kept it as ${earlier#"$BANANAPAD_ROOT"/} (nothing deleted) and downloading it again."
}

clone_reference() {
  local key="$1"
  local directory="$2"
  local url commit status

  url="$(lock_value ".references.${key}.url")"
  commit="$(lock_value ".references.${key}.commit")"

  if [[ -e "$directory" ]]; then
    if [[ ! -d "$directory/.git" ]] \
        || ! status="$(git -C "$directory" status --porcelain --untracked-files=no 2>/dev/null)" \
        || [[ -n "$status" ]]; then
      move_aside "$directory"
    fi
  fi
  if [[ ! -e "$directory" ]]; then
    # Select the locked revision before fetching its submodules, not today's HEAD.
    git clone --no-checkout "$url" "$directory"
  fi

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
