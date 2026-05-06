#!/usr/bin/env bash
# serena-session-reminder.sh — SessionStart hook
# Nudges Claude to use Serena MCP for symbolic operations on TS/JS files.
# Output goes to stderr → user sees it; stdout → Claude sees it (we use both).
#
# Disable: ZODIAC_HOOK_SERENA_DISABLE=1

source "$(dirname "$0")/../lib/_common.sh"

zh_globally_disabled && exit 0
[[ "${ZODIAC_HOOK_SERENA_DISABLE:-0}" == "1" ]] && exit 0

root="$(zh_project_root)"

# Only nudge if Serena is actually configured for this project
if [[ ! -d "${root}/.serena" ]]; then
  exit 0
fi

# Only nudge for TS/JS-heavy projects (skip if no TS files at root level)
if ! find "${root}" -maxdepth 4 -type f \( -name "*.ts" -o -name "*.vue" \) \
     -not -path "*/node_modules/*" -not -path "*/.nuxt/*" \
     -not -path "*/dist/*" 2>/dev/null | head -1 | grep -q .; then
  exit 0
fi

# stdout is shown to Claude as additional context
cat <<'NUDGE'
[zodiac-hooks-pack] Serena MCP is available in this project.

For TS/JS files >200 lines, prefer Serena over Read:
  - find_symbol(name, include_body=true)         ← surgical reads
  - find_referencing_symbols(name)               ← real ref tracking
  - rename_symbol(old, new)                      ← refactors with re-exports
  - get_symbols_overview(file)                   ← orient before editing

Skip Serena for: small files, Vue SFC <script setup> (Volar unstable),
config/yaml/json/md, broad text searches (use Grep).

Before replace_symbol_body: verify text matches via Edit first
(LSP index may be stale after fresh commits).
NUDGE

exit 0
