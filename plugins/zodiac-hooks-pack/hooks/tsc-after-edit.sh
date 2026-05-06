#!/usr/bin/env bash
# tsc-after-edit.sh — PostToolUse hook
# Runs `tsc --noEmit` (or `vue-tsc --noEmit` for .vue) in the workspace.
# Reports the first 20 lines of errors to stderr (Claude can see them).
#
# Cost: tsc on a large monorepo is slow (10-60s). To prevent slowdown:
#   - Skips files outside src/ (config files etc.)
#   - Times out after 30s
#   - Caches last-run-time per workspace; reruns only every 5 minutes
#
# Disable: ZODIAC_HOOK_TSC_DISABLE=1

source "$(dirname "$0")/../lib/_common.sh"

zh_globally_disabled && exit 0
[[ "${ZODIAC_HOOK_TSC_DISABLE:-0}" == "1" ]] && exit 0

file="$(zh_get_file_path)"
[[ -z "${file}" ]] && exit 0
[[ ! -f "${file}" ]] && exit 0

# Only TypeScript-relevant extensions
case "${file}" in
  *.ts|*.tsx|*.vue) ;;
  *) exit 0 ;;
esac

# Skip files outside likely source dirs
case "${file}" in
  */src/*|*/app/*|*/server/*|*/pages/*|*/components/*|*/composables/*) ;;
  *) exit 0 ;;
esac

pkg_dir="$(zh_nearest_package_dir "${file}")" || exit 0

# Throttle: only rerun if last check was >5 min ago for this workspace
cache_dir="${TMPDIR:-/tmp}/zodiac-hooks-pack"
mkdir -p "${cache_dir}" 2>/dev/null
cache_key="$(printf '%s' "${pkg_dir}" | tr '/' '_')"
cache_file="${cache_dir}/tsc-${cache_key}.lastrun"
now=$(date +%s)
if [[ -f "${cache_file}" ]]; then
  last=$(cat "${cache_file}" 2>/dev/null || echo 0)
  if (( now - last < 300 )); then
    exit 0
  fi
fi
echo "${now}" > "${cache_file}"

# Pick checker
checker="tsc"
if [[ "${file}" == *.vue ]]; then
  checker="vue-tsc"
fi

# Detect package manager
runner="npx"
if [[ -f "${pkg_dir}/pnpm-lock.yaml" ]] || [[ -f "$(dirname "${pkg_dir}")/pnpm-lock.yaml" ]]; then
  runner="pnpm exec"
elif [[ -f "${pkg_dir}/yarn.lock" ]]; then
  runner="yarn"
fi

# Skip if checker not in deps
if ! grep -qE "\"(${checker}|typescript|vue-tsc)\"" "${pkg_dir}/package.json" 2>/dev/null; then
  exit 0
fi

output="$( cd "${pkg_dir}" && timeout 30 ${runner} ${checker} --noEmit 2>&1 | head -20 )"

if [[ -n "${output}" ]] && echo "${output}" | grep -qE "(error TS[0-9]+|error  )"; then
  zh_warn "── ${checker} (workspace: $(basename "${pkg_dir}")) ──"
  zh_warn "${output}"
  zh_warn "── end ${checker} ──"
fi

exit 0
