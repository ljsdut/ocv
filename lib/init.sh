#!/usr/bin/env bash
# OCV — Init: turn ~/.openclaw into a git repo

ocv_init() {
  need_git

  local remote=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --remote|-r) remote="$2"; shift 2 ;;
      -h|--help) echo "Usage: ocv init [--remote <git-repo-url>]"; return 0 ;;
      *) shift ;;
    esac
  done

  if [[ ! -d "$OCV_HOME" ]]; then
    err "$OCV_HOME does not exist. Install and run OpenClaw first."
    exit 1
  fi

  # Already initialized — just update remote if given
  if [[ -d "$OCV_HOME/.git" ]]; then
    if [[ -n "$remote" ]]; then
      _g remote set-url origin "$remote" 2>/dev/null || \
      _g remote add origin "$remote" 2>/dev/null
      ok "Remote updated → $remote"
    else
      warn "Already initialized."
      _has_remote && dim "  Remote: $(_g remote get-url origin)"
    fi
    return 0
  fi

  # Generate .gitignore
  cat > "$OCV_HOME/.gitignore" << 'GITIGNORE'
# OCV — generated (runtime files, not needed in backup)
sessions/
sandboxes/
.cache/
*.sqlite-journal
*.log
node_modules/
.DS_Store
Thumbs.db
GITIGNORE

  # Init git
  _g init --quiet 2>/dev/null
  _g checkout -b main --quiet 2>/dev/null || true
  _g config user.email "ocv@localhost"
  _g config user.name "OCV"

  # Initial commit
  _g add -A
  _g commit -m "💾 ocv: initial save" --quiet 2>/dev/null || true

  # Set remote
  if [[ -n "$remote" ]]; then
    _g remote add origin "$remote" 2>/dev/null || true
    ok "Initialized with remote → $remote"
  else
    ok "Initialized!"
  fi

  dim "  Save:    ocv save"
  dim "  Remote:  ocv init --remote <git-repo-url>"
  [[ -n "$remote" ]] && warn "Make sure the remote repo is PRIVATE (credentials will be backed up)." || true
}
