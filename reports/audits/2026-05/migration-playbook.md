# Migration Playbook — local `.claude/` → mzai-plugins

> **Status:** Phase 1 (`zodiac-hooks-pack`) ✅ done
> **Next:** Phases 2–5 below
> **Date:** 2026-05-06

This playbook lists every local `.claude/` artifact across the three projects
and routes it to one of:

- **MOVE** → extract to plugin (delete local)
- **PARAMETERIZE** → extract to plugin after path-genericizing
- **KEEP** → stays local (project-specific, WIP, or doesn't need versioning)
- **DELETE** → duplicate of plugin content (no need for local copy)

## Phase 1 — Hooks consolidation ✅ DONE

`zodiac-hooks-pack` now lives at `plugins/zodiac-hooks-pack/`. After this
playbook completes, each project's `.claude/settings.json` shrinks
significantly. See `examples/` in the plugin for drop-in replacements.

---

## Phase 2 — Speckit deduplication (P0, ~1 hr)

### Source-of-truth: `plugins/speckit/` and `plugins/speckit-product-forge/`

| Local copy | Action | Notes |
|---|---|---|
| `companion-ai/.claude/skills/speckit-*` (~20) | DELETE | All duplicate plugin content |
| `companion-ai/.claude/skills/forge-*` (~4) | DELETE | Duplicate Product Forge plugin |
| `companion-ai/.claude/skills/speckit-product-forge-*` (~30) | DELETE | Same |
| `companion-ai/.claude/skills/speckit-v-model-*` (~17) | DELETE if v-model unused (likely) |
| `astro-ai-landing/.claude/commands/speckit.*.md` (9) | DELETE | Plugin provides via skills |
| `my_zodiac_ai/.claude/commands/speckit.product-forge.*.md` (15+) | DELETE | Plugin provides |
| `my_zodiac_ai/.claude/commands/speckit.*.md` (10+) | DELETE | Plugin provides |

**Pre-delete check (mandatory):** for each batch, run `diff` against plugin
version. If local has substantive customizations → lift them upstream first.
Most local copies are stale snapshots, but verify.

**Bash one-liner to find diffs:**
```bash
for f in companion-ai/.claude/skills/speckit-*/SKILL.md; do
  base=$(basename $(dirname "$f"))
  plugin_eq="mzai-plugins/plugins/speckit/skills/${base#speckit-}/SKILL.md"
  [ -f "$plugin_eq" ] && diff -q "$f" "$plugin_eq"
done
```

---

## Phase 3 — Lift local skills to existing plugins (P1, ~2 days)

### From `my_zodiac_ai/.claude/skills/` → `plugins/zodiac-dev-toolkit/skills/`

| Local skill | Action | Destination | Why |
|---|---|---|---|
| `bundle-analyzer` | MOVE | zodiac-dev-toolkit | Used by all front projects |
| `capacitor-mobile-ops` | MOVE | zodiac-dev-toolkit | Both MZAI + companion-ai use Capacitor |
| `chaos-engineering` | MOVE | zodiac-dev-toolkit | Stack-agnostic |
| `chaos-engineering-workspace` | KEEP local | — | `*-workspace` = local fork variant |
| `docker-compose-ops` | MOVE | zodiac-dev-toolkit | All 3 projects use compose |
| `dotagents` | KEEP local | — | Personal tool config |
| `env-config-manager` | PARAMETERIZE → MOVE | zodiac-dev-toolkit | Hardcoded paths inside |
| `env-config-manager-workspace` | KEEP local | — | Workspace variant |
| `event-catalog` | PARAMETERIZE → MOVE | zodiac-dev-toolkit | EventEmitter2 patterns |
| `event-catalog-workspace` | KEEP local | — | |
| `gsap-animation-gen` | MERGE → MOVE | zodiac-dev-toolkit/skills/gsap-patterns | Combine with gsap-preset-gen |
| `gsap-preset-gen` | MERGE → MOVE | zodiac-dev-toolkit/skills/gsap-patterns | |
| `i18n-workflow` | RENAME → MOVE | zodiac-dev-toolkit/skills/mzai-i18n-workflow | Disambiguate from nuxt-toolkit version |
| `k6-load-testing` | MOVE | zodiac-dev-toolkit | Stack-agnostic |
| `langfuse` | MOVE | zodiac-dev-toolkit | LLM observability |
| `lighthouse-audit` | MOVE | zodiac-dev-toolkit | All web projects |
| `log-analyzer` | PARAMETERIZE → MOVE | zodiac-dev-toolkit | NewRelic/PostHog detection |
| `memory-profiler` | MOVE | zodiac-dev-toolkit | NestJS-relevant |
| `memory-profiler-workspace` | KEEP local | — | |
| `memory-profiler.skill` | KEEP local | — | Variant artifact |
| `mongodb-ops` | MOVE | zodiac-dev-toolkit | MZAI uses Mongoose; not relevant for companion-ai |
| `newrelic-dashboard-builder` | MOVE | zodiac-dev-toolkit | All 3 use NewRelic |
| `newrelic-dashboard-builder-workspace` | KEEP local | — | |
| `playwright-cli` | MOVE | zodiac-dev-toolkit | All 3 use Playwright |
| `qdrant-inspect` | MOVE | (companion-stack-toolkit) | Qdrant is companion-ai-specific |
| `release-workflow` | PARAMETERIZE → MOVE | zodiac-dev-toolkit | Hardcoded paths |
| `rum-analytics` | MOVE | zodiac-dev-toolkit | Web vitals — all projects |
| `admin-panel-dev.skill` | KEEP local | — | MZAI admin only |
| `admin-panel-dev` | MOVE | zodiac-dev-toolkit | If actively used; otherwise KEEP |
| `api-changelog` | MOVE | zodiac-dev-toolkit | Stack-agnostic |

### From `astro-ai-landing/.claude/skills/` → new `plugins/content-blog-toolkit/`

| Local skill | Action | Destination |
|---|---|---|
| `blog-post` | MOVE | content-blog-toolkit/skills/blog-post-creation |
| `i18n-add` | MERGE | content-blog-toolkit/skills/blog-translation |
| `seo-check` | MOVE | content-blog-toolkit/skills/seo-content-audit |
| `perf-check` | DUPLICATE → MOVE | nuxt-toolkit/skills/nuxt-perf-advisor |
| `playwright-cli` | DELETE local | Plugin already provides |

### From `companion-ai/.claude/skills/` → `companion-stack-toolkit/`

Most companion-ai local skills are duplicates of speckit-product-forge.
After Phase 2 dedup, the remaining local content for new plugin is empty;
the value is in the **agents** (Phase 4).

---

## Phase 4 — Lift local agents to plugins (P1, ~1 day)

### From `my_zodiac_ai/.claude/agents/`

| Local agent | Action | Destination |
|---|---|---|
| `animation-reviewer.md` | MOVE | zodiac-design-review/agents/ |
| `api-contract-reviewer.md` | MOVE | zodiac-dev-toolkit/agents/ |
| `eda-compliance.md` | AUDIT, then MERGE-OR-DELETE | overlap with zodiac-quality-gate/agents/architecture-auditor |
| `fsd-compliance.md` | AUDIT, then MERGE-OR-DELETE | same overlap concern |
| `i18n-validator.md` | MOVE | zodiac-dev-toolkit/agents/ |
| `migration-safety-reviewer.md` | MOVE | zodiac-dev-toolkit/agents/ (Mongoose-aware) |
| `unit-test-writer.md` | CONSOLIDATE | companion-ai has same name — diff first |

### From `companion-ai/.claude/agents/`

| Local agent | Action | Destination |
|---|---|---|
| `cron-job-reviewer.md` | MOVE | zodiac-dev-toolkit/agents/ (BullMQ also in MZAI) |
| `eda-consistency-reviewer.md` | AUDIT vs zodiac-quality-gate/architecture-auditor |
| `gsap-audit.md` | MOVE | zodiac-design-review/agents/ |
| `i18n-coverage.md` | MOVE | zodiac-dev-toolkit/agents/ (or merge with i18n-validator from MZAI) |
| `prisma-migration-reviewer.md` | MOVE | new companion-stack-toolkit/agents/ |
| `security-reviewer.md` | DELETE if duplicate | zodiac-quality-gate/agents/security-auditor exists |
| `streaming-pipeline-reviewer.md` | MOVE | new companion-stack-toolkit/agents/ |
| `subscription-gate-auditor.md` | MOVE | new companion-stack-toolkit/agents/ |

### From `astro-ai-landing/.claude/agents/`

All 8 → new `plugins/content-blog-toolkit/agents/`:

| Local agent | New home |
|---|---|
| `answerCapsule-writer.md` | content-blog-toolkit/agents/ |
| `blog-cross-linker.md` | content-blog-toolkit/agents/ |
| `blog-freshness-auditor.md` | content-blog-toolkit/agents/ |
| `blog-translator.md` | content-blog-toolkit/agents/ |
| `content-seo-auditor.md` | content-blog-toolkit/agents/ |
| `nuxt-perf-advisor.md` | new nuxt-toolkit/agents/ |
| `seo-auditor.md` | content-blog-toolkit/agents/ |
| `unit-test-writer.md` | DELETE if duplicate of MZAI version |

---

## Phase 5 — Build new plugins (P1/P2, ~5–10 days)

### `plugins/nuxt-toolkit/` (P1)

For companion-ai + astro-ai-landing. See gap-analysis report §3.2.

```
plugins/nuxt-toolkit/
├── skills/
│   ├── nuxt-server-routes/
│   ├── nuxt-content-workflows/
│   ├── nuxt-i18n-multilocale/
│   ├── nuxt-perf-advisor/
│   ├── nuxt-seo-meta/
│   ├── tailwind-without-quasar/
│   └── vueuse-first/
└── agents/
    └── nuxt-perf-advisor.md  (lifted from astro-ai-landing)
```

### `plugins/companion-stack-toolkit/` (P2)

For companion-ai's Prisma + SSE + RevenueCat + multi-tenant patterns.

```
plugins/companion-stack-toolkit/
├── skills/
│   ├── prisma-patterns/
│   ├── sse-streaming-pipeline/
│   ├── revenuecat-mobile-billing/
│   ├── qdrant-vector-memory/
│   └── multi-tenant-architecture/
└── agents/
    ├── prisma-migration-reviewer.md  (lifted)
    ├── streaming-pipeline-reviewer.md
    ├── subscription-gate-auditor.md
    └── eda-consistency-reviewer.md
```

### `plugins/content-blog-toolkit/` (P2)

For astro-ai-landing + future content-heavy projects.

```
plugins/content-blog-toolkit/
├── skills/
│   ├── blog-post-creation/
│   ├── blog-translation/
│   ├── blog-cross-linking/
│   ├── blog-freshness-audit/
│   ├── seo-content-audit/
│   └── answer-capsule-generation/
└── agents/
    ├── blog-translator.md
    ├── blog-cross-linker.md
    ├── blog-freshness-auditor.md
    ├── content-seo-auditor.md
    ├── seo-auditor.md
    └── answerCapsule-writer.md
```

### `plugins/astrology-shared/` (P3 — defer)

Foundational refactor. Wait until platform pivot stabilizes.

---

## Things deliberately NOT migrated

| Item | Why kept local |
|---|---|
| `.serena/` directories | Personal Serena memory, per-project context |
| Memory files (Serena `memories/`) | Tribal knowledge, not portable |
| Worktree configs | Per-machine paths |
| `*-workspace` skill variants | Local forks during experimentation |
| `*.skill` artifacts (vs `*/SKILL.md` dirs) | Workspace metadata, not the skill content itself |
| `my_zodiac_ai/.claude/launch.json` | IDE config |
| Project-specific phase specs (`features/01-*/`, etc.) | Domain content of one project |
| `serena-prompt-reminder.sh` (UserPromptSubmit) | Project-specific reminder text; can stay inline |
| `astro-ai-landing` oxfmt hook | Stack-unique (only astro-ai-landing uses oxc); kept inline until 2nd project adopts |

---

## Suggested execution order

1. **Now (today, 1 hr):** Phase 2 dedup. Run diff scripts, verify zero substantive diffs, then `rm -rf` duplicates. This is pure subtraction — nothing to break.

2. **This week (2 hr):** Update each project's `.claude/settings.json` to enable `zodiac-hooks-pack@mzai-plugins` and remove inline hooks. Use `examples/` files as templates. Verify hooks still fire by editing a test file.

3. **Next sprint:** Phase 3 (lift skills) — start with stack-agnostic ones (k6, lighthouse, playwright, langfuse, rum-analytics). Skip `*-workspace` variants. PARAMETERIZE category needs careful path replacement.

4. **Sprint after:** Phase 4 (lift agents) — start with no-conflict ones. AUDIT category requires comparing two agent prompts before deciding merge/keep/delete.

5. **Following:** Phase 5 (build new plugins) — `nuxt-toolkit` first (highest leverage), then `content-blog-toolkit`, then `companion-stack-toolkit` (after platform pivot stabilizes).

---

## Risks restated

- The host already exposes 50+ `anthropic-skills:*` mirroring local content. **Decide canonicity before lifting more** — otherwise mzai-plugins lifts will collide with anthropic-skills.
- The `eda-compliance` / `fsd-compliance` / `architecture-auditor` overlap is a real correctness risk — agents arguing in parallel is worse than one agent. **Audit before merging.**
- Platform pivot in flight (companion-ai → multi-tenant). Don't fully build `companion-stack-toolkit` until extraction lands.
- Some local skills look orphaned (`*-workspace` variants, `dotagents`). **Don't lift them just because they exist** — verify usage first.
