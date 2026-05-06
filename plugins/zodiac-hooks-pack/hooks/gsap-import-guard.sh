#!/usr/bin/env bash
# gsap-import-guard.sh — PreToolUse hook (non-blocking warning)
# Warns when raw `gsap` is imported outside the project's animations/ layer.
#
# Rationale (my_zodiac_ai convention):
#   front/src/animations/ wraps GSAP via useGsap composable. Direct imports
#   bypass that wrapper, fragmenting animation patterns and missing centralized
#   timeline management.
#
# Auto-detects projects that use GSAP. No-ops if gsap not in package.json.
#
# Disable: ZODIAC_HOOK_GSAP_DISABLE=1

source "$(dirname "$0")/../lib/_common.sh"

zh_globally_disabled && exit 0
[[ "${ZODIAC_HOOK_GSAP_DISABLE:-0}" == "1" ]] && exit 0

file="$(zh_get_file_path)"
[[ -z "${file}" ]] && exit 0

# Only Vue/TS/JS files
case "${file}" in
  *.vue|*.ts|*.tsx|*.js|*.jsx) ;;
  *) exit 0 ;;
esac

# Skip files inside animations/ — those are allowed to import gsap raw
case "${file}" in
  */animations/*|*/animation/*) exit 0 ;;
esac

# Only warn for frontend source paths (otherwise too noisy)
case "${file}" in
  */front/src/*|*/apps/web/*|*/app/*) ;;
  *) exit 0 ;;
esac

# Detect if project uses GSAP at all
pkg_dir="$(zh_nearest_package_dir "${file}")" || exit 0
if ! grep -q '"gsap"' "${pkg_dir}/package.json" 2>/dev/null; then
  exit 0
fi

content="$(zh_get_content)"
[[ -z "${content}" ]] && exit 0

# Match raw GSAP imports
if echo "${content}" | grep -qE "(from\s+['\"]gsap['\"]|require\(['\"]gsap['\"]\)|import\s+gsap\s+from)"; then
  zh_warn ""
  zh_warn "⚠️  GSAP import detected outside animations/ layer."
  zh_warn "   File: ${file}"
  zh_warn "   Convention: import { useGsap } from '@/animations' instead."
  zh_warn "   Override: ZODIAC_HOOK_GSAP_DISABLE=1"
  zh_warn ""
fi

exit 0
