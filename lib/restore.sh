#!/usr/bin/env bash
# OCV — Restore: clone a backup repo into ~/.openclaw

ocv_restore() {
  need_git

  local repo="${1:-}"
  if [[ -z "$repo" ]]; then
    echo "Usage: ocv restore <git-repo-url>"
    echo "  Example: ocv restore git@github.com:you/my-openclaw.git"
    return 1
  fi

  echo ""
  echo -e "${BOLD}🦞 OCV Restore${RST}"
  echo "═══════════════════════════════════════"
  echo ""

  # Handle existing ~/.openclaw
  if [[ -d "$OCV_HOME" ]]; then
    warn "~/.openclaw already exists."
    echo -n "  Back up and replace? [y/N] "
    read -r confirm </dev/tty
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo "Aborted."; return 0; }

    local backup="$HOME/.openclaw-backup-$(date +%Y%m%d%H%M%S)"
    echo -n "  Moving to $backup ... "
    mv "$OCV_HOME" "$backup"
    echo "done."
    echo ""
  fi

  # Clone
  echo -n "  Cloning repo ... "
  if git clone "$repo" "$OCV_HOME" --quiet 2>/dev/null; then
    echo -e "${G}✅${RST}"
  else
    err "Clone failed. Check URL and credentials."
    return 1
  fi

  # Check what was restored
  echo ""
  echo "  Restored:"

  for item in openclaw.json workspace extensions credentials; do
    if [[ -e "$OCV_HOME/$item" ]]; then
      if [[ -d "$OCV_HOME/$item" ]]; then
        local n
        n=$(find "$OCV_HOME/$item" -type f 2>/dev/null | wc -l | tr -d ' ')
        echo -e "    ${G}✅${RST} $item/ ($n files)"
      else
        echo -e "    ${G}✅${RST} $item"
      fi
    else
      dim "    ── $item (not found)"
    fi
  done

  # Fix credential permissions
  if [[ -d "$OCV_HOME/credentials" ]]; then
    chmod 600 "$OCV_HOME/credentials"/* 2>/dev/null || true
    dim "  Credential permissions fixed."
  fi

  # Restore extensions from lock file
  echo ""
  echo "  Extensions:"
  if command -v jq &>/dev/null; then
    source "$LIB_DIR/extensions.sh"
    restore_extensions
  else
    warn "  jq not installed — cannot parse extensions.lock.json"
    dim "  Install jq, then: openclaw plugins install each extension manually"
  fi

  echo ""
  ok "Restore complete!"
  dim "  Start agent: openclaw"
  dim "  Health check: openclaw doctor"

  if [[ -d "$OCV_HOME/credentials" ]]; then
    echo ""
    warn "API keys restored from backup. Update if they've changed:"
    dim "  ls ~/.openclaw/credentials/"
  fi
}
