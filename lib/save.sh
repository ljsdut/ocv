#!/usr/bin/env bash
# OCV — Save: stage everything, commit, push.

ocv_save() {
  need_git
  need_ocv

  # Parse args
  local msg="" auto=0
  if [[ "${1:-}" == "--auto" ]]; then
    auto=1; shift
  fi
  msg="${*:-}"

  # Nothing to save?
  if _is_clean; then
    ok "Nothing changed since last save."
    dim "  Last save: $(_last_save)"
    return 0
  fi

  # Count changes
  local changed
  changed=$(_changed_count)

  # Build commit message
  if [[ -z "$msg" ]]; then
    local top
    top=$(_changed_files | sed 's/\(.*\),.*/\1/')
    local ts
    ts=$(date +"%m-%d %H:%M")
    if [[ $auto -eq 1 ]]; then
      msg="🤖 auto-save $ts — ${changed} file(s)"
    else
      msg="💾 $ts — ${changed} file(s): ${top}"
    fi
  else
    msg="💾 $msg"
  fi

  # Commit
  _g add -A
  _g commit -m "$msg" --quiet 2>/dev/null

  local hash
  hash=$(_short)

  # Push if remote exists
  local pushed=""
  if _has_remote; then
    local ok_push=0
    _g push origin "$(_branch)" --quiet 2>/dev/null && ok_push=1
    if [[ $ok_push -eq 0 ]]; then
      _g push --set-upstream origin "$(_branch)" --quiet 2>/dev/null && ok_push=1
    fi
    if [[ $ok_push -eq 1 ]]; then
      pushed=" → pushed"
    else
      pushed=" (push failed, try later)"
    fi
    _g push --tags --quiet 2>/dev/null || true
  fi

  ok "Saved! ${BOLD}${hash}${RST} — ${changed} file(s) changed${pushed}"
  [[ $auto -eq 1 ]] && dim "  (auto-save)" || true
}
