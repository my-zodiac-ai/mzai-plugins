#!/usr/bin/env bash
# block-sensitive-files.sh — PreToolUse hook
# Blocks edits to files that should never be touched via Claude:
# secrets (.env*), key/cert material, lockfiles, OAuth tokens.
#
# Exit code 2 with stderr message blocks the operation in Claude Code.
# Disable: ZODIAC_HOOK_BLOCK_SENSITIVE_DISABLE=1

source "$(dirname "$0")/../lib/_common.sh"

zh_globally_disabled && exit 0
[[ "${ZODIAC_HOOK_BLOCK_SENSITIVE_DISABLE:-0}" == "1" ]] && exit 0

payload="$(zh_read_payload)"
file="$(zh_get_file_path "${payload}")"
[[ -z "${file}" ]] && exit 0

# Patterns to block. Order matters only for the error message.
# basename match (no path prefix needed):
basename_blocked=(
  ".env"
  ".env.local"
  ".env.production"
  ".env.development"
  ".env.staging"
  ".env.test"
  "pnpm-lock.yaml"
  "package-lock.json"
  "yarn.lock"
  "Gemfile.lock"
  "Cargo.lock"
  "uv.lock"
  "poetry.lock"
  ".npmrc"
  "id_rsa"
  "id_ed25519"
)

# suffix match (extension-based):
suffix_blocked=(
  ".keystore"
  ".jks"
  ".p12"
  ".pem"
  ".cert"
  ".crt"
  ".key"
  ".pfx"
  ".mobileprovision"
)

# substring match (anywhere in path):
substring_blocked=(
  "/secrets/"
  "/.aws/credentials"
  "/.ssh/"
  "google-services.json"
  "GoogleService-Info.plist"
  "firebase-adminsdk"
  "service-account"
)

base="$(basename "${file}")"

# Skip .env.example and .env.example-style files (safe to edit)
case "${base}" in
  *.example|*.sample|*.template) exit 0 ;;
esac

for blocked in "${basename_blocked[@]}"; do
  if [[ "${base}" == "${blocked}" ]]; then
    zh_warn "⛔ blocked by zodiac-hooks-pack: editing '${blocked}' is not allowed via Claude."
    zh_warn "   Reason: secrets / lockfile / credential file. Edit manually."
    zh_warn "   Override (this session only): ZODIAC_HOOK_BLOCK_SENSITIVE_DISABLE=1"
    exit 2
  fi
done

for suffix in "${suffix_blocked[@]}"; do
  if [[ "${file}" == *"${suffix}" ]]; then
    zh_warn "⛔ blocked by zodiac-hooks-pack: '${suffix}' files are credential material."
    zh_warn "   File: ${file}"
    zh_warn "   Override: ZODIAC_HOOK_BLOCK_SENSITIVE_DISABLE=1"
    exit 2
  fi
done

for needle in "${substring_blocked[@]}"; do
  if [[ "${file}" == *"${needle}"* ]]; then
    zh_warn "⛔ blocked by zodiac-hooks-pack: '${needle}' indicates sensitive data."
    zh_warn "   File: ${file}"
    zh_warn "   Override: ZODIAC_HOOK_BLOCK_SENSITIVE_DISABLE=1"
    exit 2
  fi
done

exit 0
