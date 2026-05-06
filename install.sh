#!/usr/bin/env bash
# =============================================================================
# install.sh — установка плагинов my-zodiac-ai/mzai-plugins
# =============================================================================
# Использование:
#   ./install.sh              — установить все плагины
#   ./install.sh zodiac-dev-toolkit speckit   — установить конкретные
#   ./install.sh --list       — показать доступные плагины
#   ./install.sh --uninstall  — удалить все установленные плагины этого репо
# =============================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$REPO_DIR/plugins"

# Путь куда Cowork/Claude хранит плагины на macOS
# Claude Code (CLI): ~/.claude/plugins/
# Cowork (desktop):  ~/Library/Application Support/Claude/plugins/ (remote-plugins sync)
CLAUDE_CODE_PLUGINS="$HOME/.claude/plugins"
COWORK_PLUGINS="$HOME/Library/Application Support/Claude/plugins"

# ─── цвета ───────────────────────────────────────────────────────────────────
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

# ─── определяем доступные плагины ─────────────────────────────────────────────
get_available_plugins() {
  ls "$PLUGINS_DIR"
}

# ─── определяем куда устанавливать ────────────────────────────────────────────
detect_install_target() {
  # Сначала пробуем Claude Code (CLI)
  if command -v claude &>/dev/null; then
    echo "claude-code"
    return
  fi
  # Затем Cowork desktop
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
    log_error "Плагин '$plugin_name' не найден в $PLUGINS_DIR"
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
      log_warn "Не удалось определить тип установки."
      log_warn "Установи вручную: скопируй папку '$plugin_name' в:"
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
      log_success "Удалён: $dir"
      removed=1
    fi
  done

  [ "$removed" -eq 0 ] && log_warn "$plugin_name не найден, пропускаем"
}

# ─── entrypoint ───────────────────────────────────────────────────────────────
main() {
  log_header "🔌 my-zodiac-ai/mzai-plugins installer"

  if [ "${1:-}" = "--list" ]; then
    log_header "Доступные плагины:"
    for p in $(get_available_plugins); do
      local version
      version=$(python3 -c "import json; print(json.load(open('$PLUGINS_DIR/$p/.claude-plugin/plugin.json')).get('version','?'))" 2>/dev/null || echo "?")
      echo "  • $p (v$version)"
    done
    return 0
  fi

  if [ "${1:-}" = "--uninstall" ]; then
    log_header "Удаляю плагины..."
    for p in $(get_available_plugins); do
      uninstall_plugin "$p"
    done
    log_success "Готово"
    return 0
  fi

  # Если аргументы переданы — ставим только их, иначе все
  local to_install
  if [ $# -gt 0 ]; then
    to_install=("$@")
  else
    mapfile -t to_install < <(get_available_plugins)
  fi

  log_header "Устанавливаю ${#to_install[@]} плагин(ов)..."
  local failed=0
  for p in "${to_install[@]}"; do
    install_plugin "$p" || ((failed++))
  done

  echo ""
  if [ "$failed" -eq 0 ]; then
    log_success "Все плагины установлены!"
    echo ""
    echo -e "  ${BOLD}Следующий шаг:${RESET} перезапусти Claude Code или Cowork"
    echo -e "  чтобы плагины подхватились."
  else
    log_error "$failed плагин(ов) не удалось установить"
    exit 1
  fi
}

main "$@"
