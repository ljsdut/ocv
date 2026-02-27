#!/usr/bin/env bash
# OCV — Common utilities

OCV_VERSION="1.0.0"
OCV_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"

# ── Colors (disabled when not a terminal) ──────────────────────
if [[ -t 1 ]]; then
  R='\033[0;31m' G='\033[0;32m' Y='\033[0;33m'
  C='\033[0;36m' BOLD='\033[1m' DIM='\033[2m' RST='\033[0m'
else
  R='' G='' Y='' C='' BOLD='' DIM='' RST=''
fi

ok()   { echo -e "${G}💾${RST} $*"; }
warn() { echo -e "${Y}⚠️${RST}  $*"; }
err()  { echo -e "${R}❌${RST} $*" >&2; }
dim()  { echo -e "${DIM}$*${RST}"; }

# ── Preconditions ──────────────────────────────────────────────
need_git() {
  command -v git &>/dev/null || { err "git not found. Install git first."; exit 1; }
}

need_ocv() {
  [[ -d "$OCV_HOME/.git" ]] || { err "Not initialized. Run: ocv init"; exit 1; }
}

# ── Git wrappers (always operate on OCV_HOME) ──────────────────
_g() { git -C "$OCV_HOME" "$@"; }

_short() { _g rev-parse --short HEAD 2>/dev/null || echo "???"; }

_branch() { _g rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main"; }

_has_remote() { _g remote get-url origin &>/dev/null && return 0 || return 1; }

_is_clean() {
  local d1 d2 u
  d1=$(_g diff --quiet 2>/dev/null; echo $?)
  d2=$(_g diff --cached --quiet 2>/dev/null; echo $?)
  u=$(_g ls-files --others --exclude-standard 2>/dev/null)
  [[ "$d1" == "0" && "$d2" == "0" && -z "$u" ]]
}

_ahead() {
  local n
  n=$(_g rev-list --count "origin/$(_branch)..HEAD" 2>/dev/null) || n=0
  echo "$n"
}

_last_save() {
  _g log -1 --format='%cr — %s' 2>/dev/null || echo "never"
}

_changed_count() {
  _g status --porcelain 2>/dev/null | wc -l | tr -d ' '
}

_changed_files() {
  _g status --porcelain 2>/dev/null | sed 's/^...//' | tr '\n' ', ' | sed 's/,$//'
}

# ── Auto-save helpers ───────────────────────────────────────────
OCV_CRON_MARKER="# OCV_AUTO_SAVE"

_auto_is_on() {
  crontab -l 2>/dev/null | grep -q "$OCV_CRON_MARKER"
}

# Resolve ocv binary path
_ocv_bin() {
  local bin
  bin="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/bin/ocv"
  if [[ -x "$bin" ]]; then echo "$bin"
  elif command -v ocv &>/dev/null; then command -v ocv
  else echo ""
  fi
}
