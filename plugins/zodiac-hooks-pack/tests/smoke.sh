#!/usr/bin/env bash
# Smoke tests for zodiac-hooks-pack hook scripts.
# Verifies each hook handles common inputs without crashing and produces
# expected exit codes for blocking/advisory cases.
#
# Run: bash tests/smoke.sh
# Exit code: 0 if all green, 1 if any failure.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "${HERE}/.." && pwd)"
HOOKS="${PLUGIN_ROOT}/hooks"

PASS=0
FAIL=0

assert_exit() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "${actual}" == "${expected}" ]]; then
    printf '  ✓ %s (exit %s)\n' "${desc}" "${actual}"
    PASS=$((PASS+1))
  else
    printf '  ✗ %s (expected exit %s, got %s)\n' "${desc}" "${expected}" "${actual}"
    FAIL=$((FAIL+1))
  fi
}

run_hook() {
  local hook="$1" payload="$2"
  printf '%s' "${payload}" | bash "${HOOKS}/${hook}" >/dev/null 2>&1
  echo $?
}

run_hook_py() {
  local hook="$1" payload="$2"
  printf '%s' "${payload}" | python3 "${HOOKS}/${hook}" >/dev/null 2>&1
  echo $?
}

echo
echo "── block-sensitive-files.sh ──"
assert_exit "blocks .env" 2 \
  "$(run_hook block-sensitive-files.sh '{"tool_input":{"file_path":"/foo/.env"}}')"
assert_exit "allows .env.example" 0 \
  "$(run_hook block-sensitive-files.sh '{"tool_input":{"file_path":"/foo/.env.example"}}')"
assert_exit "blocks pnpm-lock.yaml" 2 \
  "$(run_hook block-sensitive-files.sh '{"tool_input":{"file_path":"/foo/pnpm-lock.yaml"}}')"
assert_exit "blocks .keystore" 2 \
  "$(run_hook block-sensitive-files.sh '{"tool_input":{"file_path":"/foo/release.keystore"}}')"
assert_exit "blocks google-services.json" 2 \
  "$(run_hook block-sensitive-files.sh '{"tool_input":{"file_path":"/android/app/google-services.json"}}')"
assert_exit "allows regular .ts" 0 \
  "$(run_hook block-sensitive-files.sh '{"tool_input":{"file_path":"/src/foo.ts"}}')"
assert_exit "no-op on empty payload" 0 \
  "$(run_hook block-sensitive-files.sh '{}')"
assert_exit "respects ZODIAC_HOOKS_DISABLE" 0 \
  "$(printf '%s' '{"tool_input":{"file_path":"/.env"}}' | ZODIAC_HOOKS_DISABLE=1 bash "${HOOKS}/block-sensitive-files.sh" >/dev/null 2>&1; echo $?)"

echo
echo "── eslint-on-save.sh ──"
assert_exit "no-op on .md" 0 \
  "$(run_hook eslint-on-save.sh '{"tool_input":{"file_path":"/foo/README.md"}}')"
assert_exit "no-op on missing file" 0 \
  "$(run_hook eslint-on-save.sh '{"tool_input":{"file_path":"/nonexistent/foo.ts"}}')"
assert_exit "no-op on empty payload" 0 \
  "$(run_hook eslint-on-save.sh '{}')"

echo
echo "── tsc-after-edit.sh ──"
assert_exit "no-op on .json" 0 \
  "$(run_hook tsc-after-edit.sh '{"tool_input":{"file_path":"/foo/package.json"}}')"
assert_exit "no-op on missing file" 0 \
  "$(run_hook tsc-after-edit.sh '{"tool_input":{"file_path":"/nonexistent/foo.ts"}}')"
assert_exit "no-op on empty payload" 0 \
  "$(run_hook tsc-after-edit.sh '{}')"

echo
echo "── prisma-migration-reminder.sh ──"
assert_exit "warns on schema.prisma" 0 \
  "$(run_hook prisma-migration-reminder.sh '{"tool_input":{"file_path":"/apps/api/prisma/schema.prisma"}}')"
assert_exit "no-op on regular .ts" 0 \
  "$(run_hook prisma-migration-reminder.sh '{"tool_input":{"file_path":"/foo/users.service.ts"}}')"
assert_exit "no-op on empty payload" 0 \
  "$(run_hook prisma-migration-reminder.sh '{}')"

echo
echo "── gsap-import-guard.sh ──"
assert_exit "no-op outside frontend" 0 \
  "$(run_hook gsap-import-guard.sh '{"tool_input":{"file_path":"/back/src/foo.ts","new_string":"import gsap from \"gsap\""}}')"
assert_exit "no-op on .json" 0 \
  "$(run_hook gsap-import-guard.sh '{"tool_input":{"file_path":"/front/src/package.json"}}')"
assert_exit "no-op on empty payload" 0 \
  "$(run_hook gsap-import-guard.sh '{}')"

echo
echo "── frontmatter-validator.py ──"
assert_exit "no-op on .ts" 0 \
  "$(run_hook_py frontmatter-validator.py '{"tool_input":{"file_path":"/foo/bar.ts"}}')"
assert_exit "no-op on .md outside content/" 0 \
  "$(run_hook_py frontmatter-validator.py '{"tool_input":{"file_path":"/foo/README.md"}}')"
assert_exit "no-op on missing file" 0 \
  "$(run_hook_py frontmatter-validator.py '{"tool_input":{"file_path":"/nonexistent/content/blog/post.md"}}')"
assert_exit "no-op on empty payload" 0 \
  "$(run_hook_py frontmatter-validator.py '{}')"

echo
echo "── serena-session-reminder.sh ──"
assert_exit "no-op when no .serena dir" 0 \
  "$(printf '' | bash "${HOOKS}/serena-session-reminder.sh"; echo $?)"

echo
echo "── i18n-key-checker.sh ──"
assert_exit "opt-in: silent without flag" 0 \
  "$(run_hook i18n-key-checker.sh '{"tool_input":{"file_path":"/front/src/foo.vue","new_string":"<template><p>Hello World</p></template>"}}')"
assert_exit "no-op on .ts even with flag" 0 \
  "$(printf '%s' '{"tool_input":{"file_path":"/foo.ts"}}' | ZODIAC_HOOK_I18N_ENABLE=1 bash "${HOOKS}/i18n-key-checker.sh" >/dev/null 2>&1; echo $?)"

echo
printf "── Result: %d passed, %d failed ──\n" "${PASS}" "${FAIL}"
[[ "${FAIL}" -eq 0 ]]
