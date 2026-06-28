#!/usr/bin/env bash
# i18n-key-checker.sh — PreToolUse hook (non-blocking, opt-in heuristic)
# Warns when a Vue/TS frontend file adds what looks like a hardcoded
# user-facing string instead of a translation key.
#
# Heuristic is intentionally conservative — only flags multi-word capitalized
# strings inside Vue templates (>{{ }}<, <button>, <p> etc). Misses many,
# false-positives few.
#
# OPT-IN by default — set ZODIAC_HOOK_I18N_ENABLE=1 to activate.
# Disable: ZODIAC_HOOK_I18N_DISABLE=1

source "$(dirname "$0")/../lib/_common.sh"

zh_globally_disabled && exit 0
[[ "${ZODIAC_HOOK_I18N_DISABLE:-0}" == "1" ]] && exit 0
[[ "${ZODIAC_HOOK_I18N_ENABLE:-0}" != "1" ]] && exit 0

payload="$(zh_read_payload)"
file="$(zh_get_file_path "${payload}")"
[[ -z "${file}" ]] && exit 0

# Only Vue files in frontend source paths
case "${file}" in
  *.vue) ;;
  *) exit 0 ;;
esac

case "${file}" in
  */front/src/*|*/apps/web/*|*/app/*) ;;
  *) exit 0 ;;
esac

# Detect if project uses i18n
pkg_dir="$(zh_nearest_package_dir "${file}")" || exit 0
if ! grep -qE '"(@nuxtjs/i18n|vue-i18n)"' "${pkg_dir}/package.json" 2>/dev/null; then
  exit 0
fi

content="$(zh_get_content "${payload}")"
[[ -z "${content}" ]] && exit 0

# Look for plausible hardcoded UI strings: text between > and < that's
# multiword + starts with capital letter, NOT inside {{ }} or v-text/v-html.
# This is fuzzy on purpose.
hits=$(echo "${content}" | python3 -c "
import sys, re
text = sys.stdin.read()
# Pull only template section (between <template> tags) to reduce false positives
m = re.search(r'<template[^>]*>(.*?)</template>', text, re.DOTALL)
if not m:
    sys.exit(0)
body = m.group(1)
# Strip {{ }} expressions
body = re.sub(r'\{\{[^}]*\}\}', '', body)
# Find tag inner-text: >Text content here<
candidates = re.findall(r'>\s*([A-Z][a-zA-Z0-9\\'\\-]+(?:\s+[A-Z]?[a-zA-Z0-9\\'\\-]+){1,8})\s*<', body)
seen = set()
for c in candidates:
    c = c.strip()
    # Skip very short or non-words
    if len(c) < 6 or len(c.split()) < 2:
        continue
    seen.add(c)
for s in list(seen)[:5]:
    print(f'  - \"{s}\"')
" 2>/dev/null)

if [[ -n "${hits}" ]]; then
  zh_warn ""
  zh_warn "🌐 i18n: possible hardcoded UI strings in $(basename "${file}"):"
  zh_warn "${hits}"
  zh_warn "   Use t('key') / \$t('key') with i18n keys instead."
  zh_warn "   Override: ZODIAC_HOOK_I18N_DISABLE=1"
  zh_warn ""
fi

exit 0
