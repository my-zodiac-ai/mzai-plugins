#!/usr/bin/env bash
# eslint-on-save.sh — PostToolUse hook
# Runs `eslint --fix` on the edited file in the nearest workspace.
# Auto-detects monorepo layout (back/front, apps/api/apps/web, single-pkg).
# Silent on success; logs errors to stderr but never fails the hook.
#
# Disable: ZODIAC_HOOK_ESLINT_DISABLE=1

source "$(dirname "$0")/../lib/_common.sh"

zh_globally_disabled && exit 0
[[ "${ZODIAC_HOOK_ESLINT_DISABLE:-0}" == "1" ]] && exit 0

payload="$(zh_read_payload)"
file="$(zh_get_file_path "${payload}")"
[[ -z "${file}" ]] && exit 0
[[ ! -f "${file}" ]] && exit 0

# Only lintable extensions
case "${file}" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.vue) ;;
  *) exit 0 ;;
esac

# Find nearest package.json
pkg_dir="$(zh_nearest_package_dir "${file}")" || exit 0

# Skip if package.json doesn't reference eslint at all
if ! grep -q '"eslint"' "${pkg_dir}/package.json" 2>/dev/null; then
  exit 0
fi

# Detect package manager
runner="npx"
if [[ -f "${pkg_dir}/pnpm-lock.yaml" ]] || [[ -f "$(dirname "${pkg_dir}")/pnpm-lock.yaml" ]]; then
  runner="pnpm exec"
elif [[ -f "${pkg_dir}/yarn.lock" ]]; then
  runner="yarn"
fi

# Run with timeout to avoid hanging the hook
( cd "${pkg_dir}" && timeout 20 ${runner} eslint --fix --quiet "${file}" 2>&1 ) >/dev/null || true

exit 0
