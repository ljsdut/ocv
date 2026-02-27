#!/usr/bin/env bash
# OCV — Auto-save via cron

OCV_CRON_MARKER="# OCV_AUTO_SAVE"
OCV_CRON_INTERVAL="${OCV_CRON_INTERVAL:-30}"

ocv_auto() {
  case "${1:-status}" in
    on)     _auto_on ;;
    off)    _auto_off ;;
    status) _auto_status ;;
    run)    _auto_run ;;
    *)      echo "Usage: ocv auto [on|off|status]"; return 1 ;;
  esac
}

_auto_on() {
  need_ocv
  local bin
  bin=$(_ocv_bin)
  [[ -z "$bin" ]] && { err "Cannot find ocv binary."; return 1; }

  if _auto_is_on; then
    ok "Auto-save already enabled."
    return 0
  fi

  local line="*/$OCV_CRON_INTERVAL * * * * OPENCLAW_HOME=\"$OCV_HOME\" $bin save --auto >> /tmp/ocv-auto.log 2>&1 $OCV_CRON_MARKER"
  (crontab -l 2>/dev/null; echo "$line") | crontab -

  ok "Auto-save ON (every ${OCV_CRON_INTERVAL} min)."
  dim "  Log: /tmp/ocv-auto.log"
  dim "  Disable: ocv auto off"
}

_auto_off() {
  if ! _auto_is_on; then
    ok "Auto-save already off."
    return 0
  fi
  crontab -l 2>/dev/null | grep -v "$OCV_CRON_MARKER" | crontab -
  ok "Auto-save OFF."
}

_auto_status() {
  if _auto_is_on; then
    echo -e "  Auto-save: ${G}ON${RST} (every ${OCV_CRON_INTERVAL} min)"
  else
    dim "  Auto-save: OFF"
    dim "  Enable: ocv auto on"
  fi
}

# Called by cron — silent save if files changed
_auto_run() {
  need_git
  [[ ! -d "$OCV_HOME/.git" ]] && return 0 || true

  if ! _is_clean; then
    local changed
    changed=$(_changed_count)
    local ts
    ts=$(date +"%m-%d %H:%M")

    _g add -A
    _g commit -m "🤖 auto-save $ts — $changed file(s)" --quiet 2>/dev/null || true

    if _has_remote; then
      _g push origin "$(_branch)" --quiet 2>/dev/null || true
    fi

    echo "[$(date)] auto-saved: $changed file(s)"
  fi
}
