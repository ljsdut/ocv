#!/usr/bin/env bash
# OCV — Log: show save history

ocv_log() {
  need_git
  need_ocv

  local count="${1:-15}"

  echo ""
  echo -e "${BOLD}💾 Save History${RST}"
  echo "═══════════════════════════════════════"
  echo ""

  _g log --format="  %C(cyan)%h%C(reset)  %C(dim)%cr%C(reset)  %s" \
    -"$count" 2>/dev/null || echo "  (no saves yet)"

  echo ""
}
