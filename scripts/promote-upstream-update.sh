#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

mode="${1:-}"
candidate="$BANANAPAD_ROOT/worktrees/dk64-upstream-candidate"
state_dir="$BANANAPAD_ROOT/generated/upstream"
metadata="$state_dir/candidate.json"

[[ -d "$candidate/.git" && -f "$metadata" ]] || die "no staged candidate"
[[ "$(jq -er '.test.result' "$metadata")" == "pass" ]] || die "candidate has no passing test record"
commit="$(jq -er '.commit' "$metadata")"
[[ "$(git -C "$candidate" rev-parse HEAD)" == "$commit" ]] || die "candidate checkout changed after testing"
[[ "$(recursive_manifest_hash "$candidate")" == "$(jq -er '.recursiveManifestSha256' "$metadata")" ]] || die "candidate recursive manifest changed after testing"
[[ "$(recursive_worktree_hash "$candidate")" == "$(jq -er '.recursiveWorktreeSha256' "$metadata")" ]] || die "candidate recursive worktree changed after testing"
[[ "$(patch_series_hash)" == "$(jq -er '.patchSeriesSha256' "$metadata")" ]] || die "patch series changed after testing"
[[ "$(product_source_hash)" == "$(jq -er '.productSourceSha256' "$metadata")" ]] || die "BananaPad product source changed after testing"

if [[ "$mode" == "--rehearsal" ]]; then
  [[ "$commit" == "$(lock_value '.upstream.promoted.commit')" ]] || die "rehearsal promotion is only valid for the same pin"
  jq -n \
    --arg commit "$commit" \
    --arg at "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
    '{schemaVersion:1,mode:"same-pin-rehearsal",commit:$commit,result:"pass",recordedAt:$at}' \
    > "$state_dir/promotion-rehearsal.json"
  chmod 600 "$state_dir/promotion-rehearsal.json"
  note "same-pin promotion rehearsal passed; promoted lock was not changed"
  exit 0
fi

[[ "$mode" == "--apply" ]] || die "use --rehearsal, or --apply after a genuinely validated newer candidate"

tag="$(jq -r '.tag // ""' "$metadata")"
manifest="$(jq -er '.recursiveManifestSha256' "$metadata")"
patch_hash="$(jq -er '.patchSeriesSha256' "$metadata")"
current_commit="$(lock_value '.upstream.promoted.commit')"
current_patch_hash="$(lock_value '.upstream.patchSetSha256')"
[[ "$commit" != "$current_commit" || "$patch_hash" != "$current_patch_hash" ]] || die "candidate source and patch set are already promoted"
stamp="$(date -u '+%Y%m%dT%H%M%SZ')"
backup_dir="$state_dir/promotions/$stamp"
mkdir -p "$backup_dir"
cp "$BANANAPAD_LOCK" "$backup_dir/dependencies.lock.before.json"
cp "$metadata" "$backup_dir/candidate.json"

reference="$BANANAPAD_ROOT/ref/dk64-recompiled"
git -C "$reference" fetch "$candidate" "$commit"
git -C "$reference" checkout --detach FETCH_HEAD
git -C "$reference" submodule update --init --recursive
git -C "$reference" submodule foreach --recursive \
  'git remote get-url origin >/dev/null 2>&1 && git remote set-url --push origin DISABLED || true' >/dev/null

tmp="$(mktemp "$BANANAPAD_ROOT/dependencies.lock.XXXXXX")"
jq \
  --arg tag "$tag" \
  --arg commit "$commit" \
  --arg manifest "$manifest" \
  --arg patch_hash "$patch_hash" \
  '.updated = (now | strftime("%Y-%m-%d"))
   | .upstream.promoted = {tag:$tag,commit:$commit}
   | .upstream.candidate = null
   | .upstream.recursiveManifestSha256 = $manifest
   | .upstream.patchSetSha256 = $patch_hash
   | .references.dk64Recompiled.commit = $commit' "$BANANAPAD_LOCK" > "$tmp"
jq -e . "$tmp" >/dev/null
mv "$tmp" "$BANANAPAD_LOCK"

note "promoted source $commit with patch series $patch_hash; rollback snapshot: $backup_dir"
