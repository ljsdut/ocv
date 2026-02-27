#!/usr/bin/env bash
# OCV — Rollback: restore to a previous save point

ocv_rollback() {
  need_git
  need_ocv

  local target="" skip_confirm=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -y|--yes) skip_confirm=1; shift ;;
      -h|--help)
        echo "Usage: ocv rollback <commit-hash> [--yes]"
        echo "  Find hashes with: ocv log"
        return 0 ;;
      *) target="$1"; shift ;;
    esac
  done

  if [[ -z "$target" ]]; then
    echo "Usage: ocv rollback <commit-hash> [--yes]"
    echo ""
    echo "  Find a hash with: ocv log"
    echo "  Then: ocv rollback abc1234"
    return 1
  fi

  # Resolve
  if ! _g rev-parse "$target" &>/dev/null; then
    err "Commit not found: $target"
    dim "  Run 'ocv log' to see available saves."
    return 1
  fi

  local target_hash target_msg current_hash
  target_hash=$(_g rev-parse --short "$target")
  target_msg=$(_g log -1 --format='%s' "$target")
  current_hash=$(_short)

  # Confirm
  if [[ $skip_confirm -eq 0 ]]; then
    echo ""
    warn "Rolling back:"
    echo "  From: $current_hash (current)"
    echo "  To:   $target_hash — $target_msg"
    echo ""
    echo -n "  Continue? [y/N] "
    read -r confirm </dev/tty
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo "Aborted."; return 0; }
  fi

  # Safety save first
  _g add -A
  _g commit -m "💾 pre-rollback safety save" --quiet 2>/dev/null || true
  local safety
  safety=$(_short)

  # Rollback
  _g checkout "$target" -- . 2>/dev/null
  _g add -A
  _g commit -m "⏪ rollback to $target_hash ($target_msg)" --quiet 2>/dev/null || true

  ok "Rolled back to ${BOLD}$target_hash${RST}"
  dim "  Undo: ocv rollback $safety"
}
