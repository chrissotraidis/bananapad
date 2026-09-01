#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

require_command git
require_command jq

selector="${1:-$(lock_value '.upstream.promoted.commit')}"
label="${2:-same-pin-rehearsal}"
url="$(lock_value '.references.dk64Recompiled.url')"
promoted="$(lock_value '.upstream.promoted.commit')"
candidate="$BANANAPAD_ROOT/worktrees/dk64-upstream-candidate"
state_dir="$BANANAPAD_ROOT/generated/upstream"
metadata="$state_dir/candidate.json"
qualification="$state_dir/candidate-qualification.json"

[[ ! -e "$candidate" ]] || die "candidate already exists; test it or run rollback-upstream-update.sh"
[[ ! -e "$metadata" ]] || die "candidate metadata already exists; run rollback-upstream-update.sh"
[[ ! -e "$qualification" ]] || die "candidate qualification already exists; run rollback-upstream-update.sh"

mkdir -p "$BANANAPAD_ROOT/worktrees" "$state_dir"
git clone --no-checkout --filter=blob:none "$url" "$candidate"
git -C "$candidate" remote set-url --push origin DISABLED
if ! git -C "$candidate" checkout --detach "$selector"; then
  git -C "$candidate" fetch origin "$selector"
  git -C "$candidate" checkout --detach FETCH_HEAD
fi
git -C "$candidate" submodule update --init --recursive
git -C "$candidate" submodule foreach --recursive \
  'git remote get-url origin >/dev/null 2>&1 && git remote set-url --push origin DISABLED || true' >/dev/null

for patch_dir in upstream bananapad; do
  for patch_file in "$BANANAPAD_ROOT"/patches/"$patch_dir"/*.patch; do
    [[ -e "$patch_file" ]] || continue
    git -C "$candidate" apply --check "$patch_file"
    git -C "$candidate" apply "$patch_file"
  done
done

commit="$(git -C "$candidate" rev-parse HEAD)"
tag="$(git -C "$candidate" describe --tags --exact-match 2>/dev/null || true)"
manifest="$(recursive_manifest_hash "$candidate")"
worktree_hash="$(recursive_worktree_hash "$candidate")"
patch_hash="$(patch_series_hash)"
product_hash="$(product_source_hash)"
staged_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
tmp="$(mktemp "$state_dir/candidate.XXXXXX")"
jq -n \
  --arg label "$label" \
  --arg selector "$selector" \
  --arg commit "$commit" \
  --arg tag "$tag" \
  --arg promoted "$promoted" \
  --arg manifest "$manifest" \
  --arg worktree_hash "$worktree_hash" \
  --arg patch_hash "$patch_hash" \
  --arg product_hash "$product_hash" \
  --arg staged_at "$staged_at" \
  '{schemaVersion:2,label:$label,selector:$selector,commit:$commit,tag:$tag,promotedAtStage:$promoted,recursiveManifestSha256:$manifest,recursiveWorktreeSha256:$worktree_hash,patchSeriesSha256:$patch_hash,productSourceSha256:$product_hash,stagedAt:$staged_at,test:null}' > "$tmp"
chmod 600 "$tmp"
mv "$tmp" "$metadata"

note "staged candidate: $commit ${tag:+($tag)}"
note "recursive manifest: $manifest"
note "recursive worktree: $worktree_hash"
note "patch series: $patch_hash"
note "product source: $product_hash"
note "metadata: $metadata"
