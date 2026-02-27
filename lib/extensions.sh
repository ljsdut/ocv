#!/usr/bin/env bash
# OCV — Extension lock manager
#
# Extensions are npm packages installed under ~/.openclaw/extensions/<id>/
# Each has a package.json with name + version.
#
# save:    scan → write extensions.lock.json (tracked by git)
# restore: read lock → openclaw plugins install each one

LOCK_FILE="$OCV_HOME/extensions.lock.json"

# Scan extensions/ and write lock file.
# Called automatically by ocv save.
sync_extensions_lock() {
  local ext_dir="$OCV_HOME/extensions"

  # No extensions dir → write empty lock
  if [[ ! -d "$ext_dir" ]]; then
    echo '{"extensions":{}}' > "$LOCK_FILE"
    return 0
  fi

  # Scan each subdirectory for package.json
  local entries='{}'
  for dir in "$ext_dir"/*/; do
    [[ ! -d "$dir" ]] && continue
    local pkg="$dir/package.json"
    [[ ! -f "$pkg" ]] && continue

    local name version npm_spec
    name=$(jq -r '.name // empty' "$pkg" 2>/dev/null)
    version=$(jq -r '.version // "unknown"' "$pkg" 2>/dev/null)
    npm_spec=$(jq -r '.openclaw.install.npmSpec // empty' "$pkg" 2>/dev/null)

    [[ -z "$name" ]] && continue

    local id
    id=$(basename "$dir")

    entries=$(echo "$entries" | jq \
      --arg id "$id" \
      --arg name "$name" \
      --arg ver "$version" \
      --arg spec "${npm_spec:-$name}" \
      '.[$id] = { name: $name, version: $ver, npmSpec: $spec }')
  done

  # Write lock file
  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  jq -n \
    --arg ts "$ts" \
    --argjson exts "$entries" \
    '{ generated_at: $ts, extensions: $exts }' > "$LOCK_FILE"
}

# Show installed extensions from lock file.
show_extensions_lock() {
  if [[ ! -f "$LOCK_FILE" ]]; then
    dim "  No extensions.lock.json found."
    return 0
  fi

  local count
  count=$(jq '.extensions | length' "$LOCK_FILE" 2>/dev/null)

  if [[ "$count" -eq 0 ]] || [[ -z "$count" ]]; then
    dim "  No extensions recorded."
    return 0
  fi

  echo -e "  ${BOLD}Extensions ($count):${RST}"
  jq -r '.extensions | to_entries[] | "    📦 \(.value.name)@\(.value.version)"' "$LOCK_FILE" 2>/dev/null
}

# Reinstall extensions from lock file.
# Called by ocv restore.
restore_extensions() {
  if [[ ! -f "$LOCK_FILE" ]]; then
    dim "  No extensions.lock.json — skipping."
    return 0
  fi

  local count
  count=$(jq '.extensions | length' "$LOCK_FILE" 2>/dev/null)

  if [[ "$count" -eq 0 ]] || [[ -z "$count" ]]; then
    dim "  No extensions to install."
    return 0
  fi

  echo "  Installing $count extension(s)..."

  local has_cli=0
  command -v openclaw &>/dev/null && has_cli=1

  jq -r '.extensions | to_entries[] | "\(.key)\t\(.value.name)\t\(.value.version)\t\(.value.npmSpec)"' "$LOCK_FILE" 2>/dev/null | \
  while IFS=$'\t' read -r id name version spec; do
    echo -n "    $name@$version ... "

    if [[ $has_cli -eq 1 ]]; then
      # Use openclaw's own install command
      if openclaw plugins install "$spec" &>/dev/null; then
        echo -e "${G}✅${RST}"
      else
        echo -e "${R}❌${RST}"
        warn "    → Try: openclaw plugins install $spec"
      fi
    else
      # Fallback: suggest manual install
      echo -e "${Y}⏭️${RST}  (openclaw CLI not found)"
      warn "    → Install openclaw, then: openclaw plugins install $spec"
    fi
  done
}
