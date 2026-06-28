# Worked example #2 — fix the dead hooks (stdin read in subshell)

Concrete fix for **C3 / H1** (`01-CRITIQUE.md`). Two advisory hooks (`gsap-import-guard.sh`,
`i18n-key-checker.sh`) never fire. This shows the root cause and a minimal, testable fix.

## Root cause
`plugins/zodiac-hooks-pack/lib/_common.sh:20-27` caches stdin inside `zh_read_payload`,
but every caller invokes it through command substitution, e.g. in `gsap-import-guard.sh`:

```bash
file="$(zh_get_file_path)"     # zh_get_file_path runs in a SUBSHELL → it calls
                               # zh_read_payload → cat - consumes stdin in that subshell
content="$(zh_get_content)"    # parent _ZH_PAYLOAD still ""; cat - again → stdin EMPTY
[[ -z "${content}" ]] && exit 0   # always true → hook silently no-ops
```

`_ZH_PAYLOAD` set in a subshell does not survive to the parent, and stdin is not seekable
(the code comment even says so). So the "cache" never works across two `$(...)` calls.

Proof:
```
$ printf '{"tool_input":{"file_path":"/a/b.vue","new_string":"X"}}' \
   | { f=$(zh_get_file_path); c=$(zh_get_content); echo "f=[$f] c=[$c]"; }
f=[/a/b.vue] c=[]      # content lost
```

## Fix — read stdin ONCE in the hook, pass payload as an argument

### `lib/_common.sh` (helpers take payload as `$1`)
```bash
# ---------- Stdin parsing ----------
# Read the JSON payload ONCE at the top of each hook, then pass it to helpers.
# Do NOT read stdin inside a function called via $(...) — the subshell loses it.

zh_read_payload() { cat -; }     # call exactly once, at hook top-level

zh_get_file_path() {             # $1 = payload
  ZH_PAYLOAD="${1:-}" python3 -c "
import os, json
try:
    d = json.loads(os.environ.get('ZH_PAYLOAD','') or '{}')
    print((d.get('tool_input') or {}).get('file_path',''))
except Exception:
    print('')
" 2>/dev/null
}

zh_get_content() {               # $1 = payload
  ZH_PAYLOAD="${1:-}" python3 -c "
import os, json
try:
    d = json.loads(os.environ.get('ZH_PAYLOAD','') or '{}')
    ti = d.get('tool_input') or {}
    if isinstance(ti.get('edits'), list):
        print('\n'.join(str(e.get('new_string','')) for e in ti['edits']))
    elif 'new_string' in ti: print(ti.get('new_string',''))
    elif 'content' in ti:    print(ti.get('content',''))
    else: print('')
except Exception:
    print('')
" 2>/dev/null
}

zh_get_tool_name() {             # $1 = payload
  ZH_PAYLOAD="${1:-}" python3 -c "
import os, json
try: print(json.loads(os.environ.get('ZH_PAYLOAD','') or '{}').get('tool_name',''))
except Exception: print('')
" 2>/dev/null
}
```

### Each content-reading hook (e.g. `gsap-import-guard.sh`)
```bash
source "$(dirname "$0")/../lib/_common.sh"
zh_globally_disabled && exit 0
[[ "${ZODIAC_HOOK_GSAP_DISABLE:-0}" == "1" ]] && exit 0

payload="$(zh_read_payload)"                 # <-- read ONCE here
file="$(zh_get_file_path "$payload")"
content="$(zh_get_content "$payload")"
[[ -z "$file" || -z "$content" ]] && exit 0
# ... existing path-gate + grep checks ...
```

## Add the missing positive-detection test (`tests/smoke.sh`)
The current smoke test only asserts no-op cases (`smoke.sh:87-94,112-116`), so a dead hook
shows green. Add, per H-8 / CI-6:
```bash
# gsap-import-guard: POSITIVE — must warn on raw gsap import in a gated path with gsap dep
tmp="$(mktemp -d)"; echo '{"dependencies":{"gsap":"3"}}' > "$tmp/package.json"
mkdir -p "$tmp/front/src"
out="$(printf '{"tool_input":{"file_path":"%s/front/src/a.ts","new_string":"import gsap from '\''gsap'\''"}}' "$tmp" \
      | CLAUDE_PROJECT_DIR="$tmp" bash hooks/gsap-import-guard.sh 2>&1)"
[[ -n "$out" ]] && echo "PASS gsap positive" || { echo "FAIL gsap positive"; exit 1; }
```
Mirror the same for `i18n-key-checker.sh`.

## Also fix the false safety claim (H6)
`README.md` (hooks) claims "file paths are validated as absolute", but `zh_in_project`
(`_common.sh:116`) is never called. Either call it in the hooks before acting, or delete the claim.

## Acceptance
- Both hooks print a warning on a qualifying payload; `tests/smoke.sh` has a positive case per advisory hook.
- `grep -rn 'zh_in_project' hooks/` shows it used, or the README claim is removed.
- `bash -n` clean on all scripts.
