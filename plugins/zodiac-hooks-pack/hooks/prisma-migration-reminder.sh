#!/usr/bin/env bash
# prisma-migration-reminder.sh — PreToolUse hook (non-blocking)
# When schema.prisma is touched, remind to run migrate dev + generate.
#
# Disable: ZODIAC_HOOK_PRISMA_DISABLE=1

source "$(dirname "$0")/../lib/_common.sh"

zh_globally_disabled && exit 0
[[ "${ZODIAC_HOOK_PRISMA_DISABLE:-0}" == "1" ]] && exit 0

file="$(zh_get_file_path)"
[[ -z "${file}" ]] && exit 0

if [[ "${file}" == *"schema.prisma" ]]; then
  pkg_dir="$(zh_nearest_package_dir "${file}")" || pkg_dir="(workspace)"
  zh_warn ""
  zh_warn "📐 Prisma schema edited: $(basename "${file}")"
  zh_warn "   After this change, remember to run:"
  zh_warn "     cd ${pkg_dir}"
  zh_warn "     npx prisma migrate dev --name <descriptive_name>"
  zh_warn "     npx prisma generate"
  zh_warn "   Skipping either step will cause runtime/type errors."
  zh_warn ""
fi

exit 0
