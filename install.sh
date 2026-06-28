#!/usr/bin/env bash
# =============================================================================
# install.sh — plugin installer for my-zodiac-ai/mzai-plugins
# =============================================================================
# Usage:
#   ./install.sh              — install all plugins
#   ./install.sh zodiac-dev-toolkit zodiac-quality-gate   — install specific plugins
#   ./install.sh --list       — list available plugins
#   ./install.sh --uninstall  — remove all installed plugins from this repo
#
# Notes:
#   - Installs into EVERY detected client (Claude Code CLI and/or Cowork desktop),
#     not just the first one found.
#   - Backs up any existing same-named plugin dir to <dst>.bak before overwriting,
#     so a third-party plugin of the same name is never silently destroyed.
#   - Bash 3.2 compatible (macOS system bash) — no `mapfile`.
# =============================================================================

set -uo pipefail   # intentionally not -e: an installer handles its own errors

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$REPO_DIR/plugins"

# Plugin install locations:
#   Claude Code (CLI):  ~/.claude/plugins/
#   Cowork (desktop):   ~/Library/Application Support/Claude/plugins/
CLAUDE_CODE_PLUGINS="$HOME/.claude/plugins"
COWORK_PLUGINS="$HOME/Library/Application Support/Claude/plugins"

# ─── colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'
log_info()    { echo -e "${BLUE}→${RESET} $*"; }
log_success() { echo -e "${GREEN}✓${RESET} $*"; }
log_warn()    { echo -e "${YELLOW}⚠${RESET} $*"; }
log_error()   { echo -e "${RED}✗${RESET} $*" >&2; }
log_header()  { echo -e "\n${BOLD}$*${RESET}"; }

# ─── list available plugins (dirs with a real manifest; skips .DS_Store etc.) ──
get_available_plugins() {
  local d
  for d in "$PLUGINS_DIR"/*/; do
    [ -f "${d}.claude-plugin/plugin.json" ] || continue
    basename "$d"
  done
}

# ─── detect ALL install targets (not mutually exclusive) ───────────────────────
# Echoes one target plugins-dir per line. Returns non-zero if none found.
detect_install_dirs() {
  local found=0
  if command -v claude >/dev/null 2>&1 || [ -d "$HOME/.claude" ]; then
    echo "$CLAUDE_CODE_PLUGINS"; found=1
  fi
  if [ -d "$HOME/Library/Application Support/Claude" ]; then
    echo "$COWORK_PLUGINS"; found=1
  fi
  [ "$found" -eq 1 ]
}

install_plugin() {
  local plugin_name="$1"
  local src="$PLUGINS_DIR/$plugin_name"
  [ -d "$src" ] || { log_error "Plugin '$plugin_name' not found in $PLUGINS_DIR"; return 1; }

  local targets
  targets="$(detect_install_dirs)" || {
    log_warn "Could not detect a Claude Code or Cowork install."
    log_warn "Copy '$plugin_name' manually into one of:"
    log_warn "  Claude Code:  ~/.claude/plugins/"
    log_warn "  Cowork:       ~/Library/Application Support/Claude/plugins/"
    return 1
  }

  local base dst
  while IFS= read -r base; do
    [ -n "$base" ] || continue
    dst="$base/$plugin_name"
    mkdir -p "$base"
    if [ -e "$dst" ]; then
      rm -rf "$dst.bak"
      mv "$dst" "$dst.bak"
      log_warn "[$plugin_name] existing copy backed up → $dst.bak"
    fi
    cp -r "$src" "$dst"
    log_success "[$plugin_name] → $dst"
  done <<< "$targets"
}

uninstall_plugin() {
  local plugin_name="$1" removed=0 dir
  for dir in "$CLAUDE_CODE_PLUGINS/$plugin_name" "$COWORK_PLUGINS/$plugin_name"; do
    if [ -d "$dir" ]; then rm -rf "$dir"; log_success "Removed: $dir"; removed=1; fi
  done
  [ "$removed" -eq 0 ] && log_warn "$plugin_name not found, skipping"
  return 0
}

# ─── entrypoint ───────────────────────────────────────────────────────────────
main() {
  log_header "🔌 my-zodiac-ai/mzai-plugins installer"

  if [ "${1:-}" = "--list" ]; then
    log_header "Available plugins:"
    local p version
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      version=$(python3 -c "import json;print(json.load(open('$PLUGINS_DIR/$p/.claude-plugin/plugin.json')).get('version','?'))" 2>/dev/null || echo "?")
      echo "  • $p (v$version)"
    done <<< "$(get_available_plugins)"
    return 0
  fi

  if [ "${1:-}" = "--uninstall" ]; then
    log_header "Removing plugins..."
    local p
    while IFS= read -r p; do [ -n "$p" ] && uninstall_plugin "$p"; done <<< "$(get_available_plugins)"
    log_success "Done"
    return 0
  fi

  # Build the install list: explicit args, otherwise everything available.
  local to_install=() p
  if [ $# -gt 0 ]; then
    to_install=("$@")
  else
    while IFS= read -r p; do [ -n "$p" ] && to_install+=("$p"); done <<< "$(get_available_plugins)"
  fi
  [ "${#to_install[@]}" -gt 0 ] || { log_error "No plugins found in $PLUGINS_DIR"; exit 1; }

  log_header "Installing ${#to_install[@]} plugin(s)..."
  local failed=0
  for p in "${to_install[@]}"; do
    install_plugin "$p" || failed=$((failed+1))
  done

  echo ""
  if [ "$failed" -eq 0 ]; then
    log_success "All plugins installed!"
    echo ""
    echo -e "  ${BOLD}Next step:${RESET} restart Claude Code or Cowork to pick up the plugins."
  else
    log_error "$failed plugin(s) failed to install"
    exit 1
  fi
}

main "$@"
