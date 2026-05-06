#!/usr/bin/env bash
# _common.sh — shared helpers for zodiac-hooks-pack hook scripts
# Sourced by every hook script in ../hooks/
# All functions are fail-soft: they return empty string on parse errors
# rather than crashing the hook (which would interrupt Claude's flow).

set -u
# Note: we intentionally do NOT set -e — hooks should never abort midway.

# ---------- Kill switches ----------
# Global: ZODIAC_HOOKS_DISABLE=1 disables every hook in the pack.
# Per-hook: each script also checks ZODIAC_HOOK_<NAME>_DISABLE=1.
zh_globally_disabled() {
  [[ "${ZODIAC_HOOKS_DISABLE:-0}" == "1" ]]
}

# ---------- Stdin parsing ----------
# Hooks receive a JSON payload on stdin. We cache it in a variable so each
# helper can re-parse without re-reading (stdin is not seekable).
_ZH_PAYLOAD=""

zh_read_payload() {
  if [[ -z "${_ZH_PAYLOAD}" ]]; then
    _ZH_PAYLOAD="$(cat -)"
  fi
  printf '%s' "${_ZH_PAYLOAD}"
}

zh_get_file_path() {
  local payload
  payload="$(zh_read_payload)"
  ZH_PAYLOAD="${payload}" python3 -c "
import os, json, sys
try:
    d = json.loads(os.environ.get('ZH_PAYLOAD', '') or '{}')
    ti = d.get('tool_input', {}) or {}
    print(ti.get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null
}

zh_get_content() {
  # For Edit: prefer new_string. For Write: prefer content.
  # For MultiEdit: concatenate all new_string values.
  local payload
  payload="$(zh_read_payload)"
  ZH_PAYLOAD="${payload}" python3 -c "
import os, json, sys
try:
    d = json.loads(os.environ.get('ZH_PAYLOAD', '') or '{}')
    ti = d.get('tool_input', {}) or {}
    if 'edits' in ti and isinstance(ti['edits'], list):
        # MultiEdit
        parts = [str(e.get('new_string', '')) for e in ti['edits']]
        print('\n'.join(parts))
    elif 'new_string' in ti:
        print(ti.get('new_string', ''))
    elif 'content' in ti:
        print(ti.get('content', ''))
    else:
        print('')
except Exception:
    print('')
" 2>/dev/null
}

zh_get_tool_name() {
  local payload
  payload="$(zh_read_payload)"
  ZH_PAYLOAD="${payload}" python3 -c "
import os, json
try:
    d = json.loads(os.environ.get('ZH_PAYLOAD', '') or '{}')
    print(d.get('tool_name', ''))
except Exception:
    print('')
" 2>/dev/null
}

# ---------- Project root detection ----------
# CLAUDE_PROJECT_DIR is set by Claude Code. Fall back to git root, then cwd.
zh_project_root() {
  if [[ -n "${CLAUDE_PROJECT_DIR:-}" && -d "${CLAUDE_PROJECT_DIR}" ]]; then
    printf '%s' "${CLAUDE_PROJECT_DIR}"
    return 0
  fi
  local guess
  guess="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "${guess}" ]]; then
    printf '%s' "${guess}"
    return 0
  fi
  printf '%s' "${PWD}"
}

# Find nearest ancestor directory containing package.json.
# Useful for monorepos: file in apps/api/src/foo.ts → returns apps/api.
zh_nearest_package_dir() {
  local file="$1"
  [[ -z "${file}" ]] && return 1
  local dir
  dir="$(dirname "${file}")"
  while [[ "${dir}" != "/" && "${dir}" != "." ]]; do
    if [[ -f "${dir}/package.json" ]]; then
      printf '%s' "${dir}"
      return 0
    fi
    dir="$(dirname "${dir}")"
  done
  return 1
}

# Check if file path is inside the project (defense against absolute paths
# pointing to /tmp or other unrelated dirs).
zh_in_project() {
  local file="$1"
  local root
  root="$(zh_project_root)"
  [[ "${file}" == "${root}/"* ]]
}

# ---------- Output helpers ----------
# Hook output to stderr is shown to the user; stdout is shown to Claude.
zh_warn() { printf '%s\n' "$*" >&2; }
zh_info() { printf '%s\n' "$*" >&2; }

# ---------- Pattern detection ----------
zh_file_matches() {
  local file="$1"; shift
  local pattern
  for pattern in "$@"; do
    case "${file}" in
      ${pattern}) return 0 ;;
    esac
  done
  return 1
}
