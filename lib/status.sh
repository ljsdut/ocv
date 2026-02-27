#!/usr/bin/env bash
# OCV — Status: what changed since last save

ocv_status() {
  need_git
  need_ocv

  echo ""
  echo -e "${BOLD}💾 OCV Status${RST}"
  echo "═══════════════════════════════════════"

  # Last save
  echo -e "  Last save: ${BOLD}$(_last_save)${RST}"

  # Remote
  if _has_remote; then
    local url
    url=$(_g remote get-url origin 2>/dev/null)
    dim "  Remote:    $url"
    local ahead
    ahead=$(_ahead)
    [[ "$ahead" -gt 0 ]] && warn "  $ahead save(s) not pushed yet." || true
  else
    dim "  Remote:    not configured → ocv init --remote <url>"
  fi

  echo ""

  # Changes
  if _is_clean; then
    ok "All saved — no changes."
  else
    local changed
    changed=$(_changed_count)
    warn "$changed file(s) changed since last save:"
    echo ""

    _g status --porcelain 2>/dev/null | while IFS= read -r line; do
      local st="${line:0:2}" f="${line:3}"
      local icon="📝"
      case "$st" in
        "??") icon="🆕" ;;
        " D"|"D ") icon="🗑️" ;;
      esac
      echo "    $icon $f"
    done

    echo ""
    dim "  Run 'ocv save' to backup."
  fi

  # Auto-save
  echo ""
  if _auto_is_on; then
    echo -e "  Auto-save: ${G}ON${RST}"
  else
    dim "  Auto-save: OFF → ocv auto on"
  fi
}
