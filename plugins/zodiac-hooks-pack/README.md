# zodiac-hooks-pack

Reusable Claude Code hooks for the My Zodiac AI ecosystem
(`my_zodiac_ai`, `companion-ai`, `astro-ai-landing`).

Self-detecting, fail-soft, individually disable-able. Replaces the inline
hooks scattered across each project's `.claude/settings.json`.

## What's inside

| Hook | When | What it does | Default |
|---|---|---|---|
| `block-sensitive-files.sh` | PreToolUse(Edit\|Write\|MultiEdit) | Blocks edits to `.env*`, lockfiles, keystores, certificates, OAuth credentials. **Exits 2** to abort. | enabled |
| `eslint-on-save.sh` | PostToolUse | Runs `eslint --fix --quiet` in nearest workspace. Auto-detects pnpm/yarn/npm. Skips if no `eslint` in `package.json`. Silent on success. | enabled |
| `tsc-after-edit.sh` | PostToolUse | Runs `tsc --noEmit` (or `vue-tsc` for `.vue`) in nearest workspace. Throttled (5 min/workspace), 30s timeout. First 20 error lines to stderr. | enabled |
| `prisma-migration-reminder.sh` | PreToolUse | When `schema.prisma` is edited, prints reminder to run `prisma migrate dev` + `prisma generate`. Non-blocking. | enabled |
| `gsap-import-guard.sh` | PreToolUse | Warns when raw `gsap` is imported outside `animations/` layer. Auto-skips projects without GSAP. | enabled |
| `frontmatter-validator.py` | PostToolUse | Validates YAML frontmatter on `.md` files in `content/` (@nuxt/content). Reports missing required keys. | enabled |
| `serena-session-reminder.sh` | SessionStart | Nudges Claude to use Serena MCP for symbolic ops on TS/JS. Auto-skips projects without `.serena/`. | enabled |
| `i18n-key-checker.sh` | PreToolUse | Heuristic warning for hardcoded UI strings in Vue templates. **Opt-in only.** | disabled |

## Install

In your project's `.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "zodiac-hooks-pack@mzai-plugins": true
  }
}
```

That's it. All applicable hooks activate automatically. Each hook
self-detects whether it applies to the current file/project and no-ops
silently when it doesn't.

## Project-specific examples

See `examples/` for drop-in `settings.json` replacements per project:

- `examples/my-zodiac-ai-settings.json`
- `examples/companion-ai-settings.json`
- `examples/astro-ai-landing-settings.json`

## Disabling hooks

Three levels of granularity:

1. **All hooks off:**
   ```bash
   export ZODIAC_HOOKS_DISABLE=1
   ```
2. **Specific hook off** (per script):
   ```bash
   export ZODIAC_HOOK_BLOCK_SENSITIVE_DISABLE=1
   export ZODIAC_HOOK_ESLINT_DISABLE=1
   export ZODIAC_HOOK_TSC_DISABLE=1
   export ZODIAC_HOOK_PRISMA_DISABLE=1
   export ZODIAC_HOOK_GSAP_DISABLE=1
   export ZODIAC_HOOK_FRONTMATTER_DISABLE=1
   export ZODIAC_HOOK_SERENA_DISABLE=1
   export ZODIAC_HOOK_I18N_DISABLE=1
   ```
3. **Opt-in only** (i18n-key-checker):
   ```bash
   export ZODIAC_HOOK_I18N_ENABLE=1   # heuristic, may have false positives
   ```

## Override `block-sensitive-files.sh`

If you genuinely need to edit a normally-blocked file (e.g., scaffolding
a new lockfile):

```bash
ZODIAC_HOOK_BLOCK_SENSITIVE_DISABLE=1 claude-code ...
```

`.env.example`, `.env.sample`, `.env.template` are always allowed
(no override needed).

## Customize `frontmatter-validator.py`

```bash
export ZODIAC_FRONTMATTER_REQUIRED="title,description,date,author,locale"
```

Default required keys: `title,description,date`.

## Safety notes

- All scripts use `set -u` (unset var = error) but **not** `set -e` —
  hooks must never abort midway.
- All variables are quoted. The stdin JSON payload is read exactly once per hook
  and parsed via `python3` (passed through an env var, never interpolated into
  the shell), so a malicious `file_path`/content value cannot inject commands.
- No script interprets file content or file names as code.
- `tsc-after-edit.sh` throttles per-workspace to avoid blocking on every edit.
- `eslint-on-save.sh` and `tsc-after-edit.sh` use `timeout` to prevent hangs.
- `block-sensitive-files.sh` is the only hook that can abort (exit 2);
  all others are advisory (exit 0).

## Architecture

```
plugins/zodiac-hooks-pack/
├── .claude-plugin/
│   └── plugin.json              # declares hooks via CLAUDE_PLUGIN_ROOT
├── hooks/                       # 8 hook scripts
│   ├── block-sensitive-files.sh
│   ├── eslint-on-save.sh
│   ├── tsc-after-edit.sh
│   ├── prisma-migration-reminder.sh
│   ├── gsap-import-guard.sh
│   ├── frontmatter-validator.py
│   ├── serena-session-reminder.sh
│   └── i18n-key-checker.sh
├── lib/
│   └── _common.sh               # shared helpers (sourced by all .sh hooks)
├── examples/                    # per-project settings.json drop-ins
│   ├── my-zodiac-ai-settings.json
│   ├── companion-ai-settings.json
│   └── astro-ai-landing-settings.json
├── tests/
│   └── smoke.sh                 # smoke test against synthetic stdin
└── README.md
```

## Migration from inline hooks

Each project today has hooks inline in `.claude/settings.json`. To migrate:

1. Add `"zodiac-hooks-pack@mzai-plugins": true` under `enabledPlugins`.
2. Delete the corresponding inline `hooks` blocks in `.claude/settings.json`.
3. Keep any project-unique hooks inline (e.g., astro-ai-landing's `oxfmt`).

See `examples/` for exact diffs.

## Versioning

`0.1.0` — initial extraction from inline hooks across the three projects.

Future versions will add:
- `oxfmt-on-save.sh` (extract from astro-ai-landing)
- `vitest-changed-files.sh` (run only impacted tests on save)
- `commit-msg-conventional.sh` (validate commit messages)
