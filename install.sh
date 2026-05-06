#!/usr/bin/env bash
# =============================================================================
# install.sh — plugin installer for my-zodiac-ai/mzai-plugins
# =============================================================================
# Usage:
#   ./install.sh              — install all plugins
#   ./install.sh zodiac-dev-toolkit speckit   — install specific plugins
#   ./install.sh --list       — list available plugins
#   ./install.sh --uninstall  — remove all installed plugins from this repo
# =============================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$REPO_DIR/plugins"

# Paths where Cowork/Claude stores plugins on macOS
# Claude Code (CLI): ~/.claude/plugins/
# Cowork (desktop):  ~/Library/Application Support/Claude/plugins/
CLAUDE_CODE_PLUGINS="$HOME/.claude/plugins"
COWORK_PLUGINS="$HOME/Library/Application Support/Claude/plugins"

# ─── colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

log_info()    { echo -e "${BLUE}→${RESET} $*"; }
log_success() { echo -e "${GREEN}✓${RESET} $*"; }
log_warn()    { echo -e "${YELLOW}⚠${RESET} $*"; }
log_error()   { echo -e "${RED}✗${RESET} $*" >&2; }
log_header()  { echo -e "\n${BOLD}$*${RESET}"; }

# ─── list available plugins ───────────────────────────────────────────────────
get_available_plugins() {
  ls "$PLUGINS_DIR"
}

# ─── detect install target ───────────────────────────────────────────────────
detect_install_target() {
  # Try Claude Code (CLI) first
  if command -v claude &>/dev/null; then
    echo "claude-code"
    return
  fi
  # Then Cowork desktop
  if [ -d "$HOME/Library/Application Support/Claude" ]; then
    echo "cowork"
    return
  fi
  echo "unknown"
}

install_plugin() {
  local plugin_name="$1"
  local src="$PLUGINS_DIR/$plugin_name"

  if [ ! -d "$src" ]; then
    log_error "Plugin '$plugin_name' not found in $PLUGINS_DIR"
    return 1
  fi

  local target_mode
  target_mode=$(detect_install_target)

  case "$target_mode" in
    claude-code)
      local dst="$CLAUDE_CODE_PLUGINS/$plugin_name"
      mkdir -p "$CLAUDE_CODE_PLUGINS"
      rm -rf "$dst"
      cp -r "$src" "$dst"
      log_success "[$plugin_name] → $dst (Claude Code)"
      ;;
    cowork)
      local dst="$COWORK_PLUGINS/$plugin_name"
      mkdir -p "$COWORK_PLUGINS"
      rm -rf "$dst"
      cp -r "$src" "$dst"
      log_success "[$plugin_name] → $dst (Cowork)"
      ;;
    *)
      log_warn "Could not detect install target."
      log_warn "Install manually — copy '$plugin_name' folder to:"
      log_warn "  Claude Code:  ~/.claude/plugins/"
      log_warn "  Cowork:       ~/Library/Application Support/Claude/plugins/"
      return 1
      ;;
  esac
}

uninstall_plugin() {
  local plugin_name="$1"
  local removed=0

  for dir in "$CLAUDE_CODE_PLUGINS/$plugin_name" "$COWORK_PLUGINS/$plugin_name"; do
    if [ -d "$dir" ]; then
      rm -rf "$dir"
      log_success "Removed: $dir"
      removed=1
    fi
  done

  [ "$removed" -eq 0 ] && log_warn "$plugin_name not found, skipping"
}

# ─── entrypoint ───────────────────────────────────────────────────────────────
main() {
  log_header "🔌 my-zodiac-ai/mzai-plugins installer"

  if [ "${1:-}" = "--list" ]; then
    log_header "Available plugins:"
    for p in $(get_available_plugins); do
      local version
      version=$(python3 -c "import json; print(json.load(open('$PLUGINS_DIR/$p/.claude-plugin/plugin.json')).get('version','?'))" 2>/dev/null || echo "?")
      echo "  • $p (v$version)"
    done
    return 0
  fi

  if [ "${1:-}" = "--uninstall" ]; then
    log_header "Removing plugins..."
    for p in $(get_available_plugins); do
      uninstall_plugin "$p"
    done
    log_success "Done"
    return 0
  fi

  # If arguments provided — install only those, otherwise install all
  local to_install
  if [ $# -gt 0 ]; then
    to_install=("$@")
  else
    mapfile -t to_install < <(get_available_plugins)
  fi

  log_header "Installing ${#to_install[@]} plugin(s)..."
  local failed=0
  for p in "${to_install[@]}"; do
    install_plugin "$p" || ((failed++))
  done

  echo ""
  if [ "$failed" -eq 0 ]; then
    log_success "All plugins installed!"
    echo ""
    echo -e "  ${BOLD}Next step:${RESET} restart Claude Code or Cowork"
    echo -e "  to pick up the new plugins."
  else
    log_error "$failed plugin(s) failed to install"
    exit 1
  fi
}

main "$@"
