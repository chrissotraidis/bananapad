#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

require_command git
require_command jq
require_command shasum
require_command xxd

tag="$(lock_value '.upstream.promoted.tag')"
commit="$(lock_value '.upstream.promoted.commit')"
app="$BANANAPAD_ROOT/generated/build/upstream-macos-$tag/DK64Recompiled.app"
support="$HOME/Library/Application Support/DK64Recompiled"
save="$support/saves/DK64.bin"
session_root="$BANANAPAD_ROOT/generated/evidence/g2/play-session"
session="$session_root/session.json"

usage() {
  cat <<'EOF'
Usage:
  scripts/validate-upstream-play-session.sh begin
  scripts/validate-upstream-play-session.sh record-play-exit
  scripts/validate-upstream-play-session.sh begin-reload
  scripts/validate-upstream-play-session.sh complete RELOAD_SCREENSHOT.png OBSERVATION.txt
  scripts/validate-upstream-play-session.sh status
  scripts/validate-upstream-play-session.sh abort

The complete command records private, ignored evidence. It does not publish or
claim gameplay on its own; the screenshot and observation must show that the
same progress was visibly restored after relaunch.
EOF
}

require_no_process() {
  if pgrep -x DK64Recompiled >/dev/null; then
    die "DK64Recompiled is still running; exit it cleanly before this step"
  fi
}

require_session() {
  [[ -f "$session" ]] || die "no active G2 play session; run with begin"
}

require_phase() {
  local expected="$1"
  local actual
  require_session
  actual="$(jq -er '.phase' "$session")"
  [[ "$actual" == "$expected" ]] || die "expected session phase $expected, found $actual"
}

save_state_json() {
  if [[ -f "$save" ]]; then
    jq -n \
      --arg path "$save" \
      --argjson size "$(stat -f '%z' "$save")" \
      --arg sha256 "$(shasum -a 256 "$save" | awk '{print $1}')" \
      '{state:"present",path:$path,size:$size,sha256:$sha256}'
  else
    jq -n --arg path "$save" '{state:"absent",path:$path}'
  fi
}

update_session() {
  local filter="$1"
  shift
  local tmp
  tmp="$(mktemp "$session_root/session.XXXXXX")"
  jq "$@" "$filter" "$session" >"$tmp"
  chmod 600 "$tmp"
  mv "$tmp" "$session"
}

bundle_hash() {
  (
    cd "$app"
    find . -type f -print \
      | LC_ALL=C sort \
      | while IFS= read -r item; do shasum -a 256 "$item"; done \
      | shasum -a 256 \
      | awk '{print $1}'
  )
}

command="${1:-status}"

case "$command" in
  begin)
    [[ $# -eq 1 ]] || { usage; exit 2; }
    require_no_process
    [[ ! -e "$session_root" ]] || die "active or residual play-session state exists; inspect status or abort it"
    "$BANANAPAD_ROOT/scripts/audit-upstream-baseline.sh" >/dev/null
    mkdir -p "$session_root"
    chmod 700 "$session_root"
    before_save="$(save_state_json)"
    jq -n \
      --arg tag "$tag" \
      --arg commit "$commit" \
      --arg app "$app" \
      --arg app_hash "$(bundle_hash)" \
      --arg rom_sha1 "$(lock_value '.rom.sha1')" \
      --arg started_at "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
      --argjson before_save "$before_save" \
      '{schemaVersion:1,phase:"prepared",source:{tag:$tag,commit:$commit},app:{path:$app,sha256:$app_hash},romSha1:$rom_sha1,beforeSave:$before_save,startedAt:$started_at}' \
      >"$session"
    chmod 600 "$session"
    /usr/bin/open "$app"
    update_session '.phase = "play-launched" | .playLaunchedAt = $at' --arg at "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    note "exact upstream comparison launched"
    note "play normally, create or select an Adventure file, reach gameplay, make visible progress, then exit cleanly"
    note "after the process exits: scripts/validate-upstream-play-session.sh record-play-exit"
    ;;

  record-play-exit)
    [[ $# -eq 1 ]] || { usage; exit 2; }
    require_phase "play-launched"
    require_no_process
    [[ -f "$save" ]] || die "expected gameplay save was not created: $save"
    [[ "$(stat -f '%z' "$save")" == "2048" ]] || die "expected 2048-byte Eep16k save"
    nonzero_bytes="$(LC_ALL=C tr -d '\000' <"$save" | wc -c | tr -d ' ')"
    [[ "$nonzero_bytes" -gt 0 ]] || die "save is still entirely zero-filled"
    after_hash="$(shasum -a 256 "$save" | awk '{print $1}')"
    before_hash="$(jq -r '.beforeSave.sha256 // ""' "$session")"
    [[ -z "$before_hash" || "$after_hash" != "$before_hash" ]] || die "save did not change during the play session"
    /usr/bin/install -m 600 "$save" "$session_root/save-after-play.bin"
    update_session \
      '.phase = "play-exit-recorded" | .playExitedAt = $at | .afterPlaySave = {state:"present",path:$path,size:2048,sha256:$sha256,nonzeroBytes:$nonzero,privateBackup:"save-after-play.bin"}' \
      --arg at "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
      --arg path "$save" \
      --arg sha256 "$after_hash" \
      --argjson nonzero "$nonzero_bytes"
    note "changed 2048-byte gameplay save recorded and backed up privately"
    note "next: scripts/validate-upstream-play-session.sh begin-reload"
    ;;

  begin-reload)
    [[ $# -eq 1 ]] || { usage; exit 2; }
    require_phase "play-exit-recorded"
    require_no_process
    "$BANANAPAD_ROOT/scripts/audit-upstream-baseline.sh" >/dev/null
    current_hash="$(shasum -a 256 "$save" | awk '{print $1}')"
    [[ "$current_hash" == "$(jq -er '.afterPlaySave.sha256' "$session")" ]] || die "save changed before reload validation"
    /usr/bin/open "$app"
    update_session '.phase = "reload-launched" | .reloadLaunchedAt = $at' --arg at "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    note "exact upstream comparison relaunched with the recorded save"
    note "visibly load the same Adventure file/progress, capture a PNG, write a short observation note, then exit cleanly"
    note "after exit: scripts/validate-upstream-play-session.sh complete /absolute/reload.png /absolute/observation.txt"
    ;;

  complete)
    [[ $# -eq 3 ]] || { usage; exit 2; }
    require_phase "reload-launched"
    require_no_process
    screenshot="$2"
    observation="$3"
    [[ -f "$screenshot" && -s "$screenshot" ]] || die "reload screenshot is missing or empty"
    [[ "$(xxd -p -l 8 "$screenshot")" == "89504e470d0a1a0a" ]] || die "reload screenshot is not a PNG"
    [[ -f "$observation" && -s "$observation" ]] || die "reload observation is missing or empty"
    [[ -f "$save" && "$(stat -f '%z' "$save")" == "2048" ]] || die "Eep16k save is missing after reload"
    /usr/bin/install -m 600 "$screenshot" "$session_root/reload-observed.png"
    /usr/bin/install -m 600 "$observation" "$session_root/reload-observation.txt"
    update_session \
      '.phase = "complete" | .completedAt = $at | .reloadEvidence = {screenshot:"reload-observed.png",screenshotSha256:$screenshot_hash,observation:"reload-observation.txt",observationSha256:$observation_hash,saveSha256:$save_hash}' \
      --arg at "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
      --arg screenshot_hash "$(shasum -a 256 "$screenshot" | awk '{print $1}')" \
      --arg observation_hash "$(shasum -a 256 "$observation" | awk '{print $1}')" \
      --arg save_hash "$(shasum -a 256 "$save" | awk '{print $1}')"
    note "G2 play/save/reload evidence session recorded privately"
    note "review $session before changing G2 status"
    ;;

  status)
    [[ $# -eq 1 ]] || { usage; exit 2; }
    if [[ -f "$session" ]]; then
      jq . "$session"
    else
      note "no active G2 play session"
    fi
    ;;

  abort)
    [[ $# -eq 1 ]] || { usage; exit 2; }
    require_session
    require_no_process
    stamp="$(date -u '+%Y%m%dT%H%M%SZ')"
    archive="$BANANAPAD_ROOT/generated/evidence/g2/aborted/$stamp-play-session"
    mkdir -p "$(dirname "$archive")"
    mv "$session_root" "$archive"
    note "play session archived recoverably to $archive"
    ;;

  -h|--help|help)
    usage
    ;;

  *)
    usage >&2
    exit 2
    ;;
esac
