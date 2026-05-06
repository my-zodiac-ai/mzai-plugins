# mzai-plugins — Gap Analysis & Improvement Proposal

> **Date:** 2026-05-06
> **Scope:** mzai-plugins ↔ my_zodiac_ai ↔ companion-ai ↔ astro-ai-landing
> **Author:** AI agent audit (honest, no flattery — per global rule)

---

## TL;DR — Key Findings

1. **mzai-plugins has zero hooks and zero plugin-level slash commands.** All three projects rely on inline hooks in `.claude/settings.json` instead. This is the largest reusability gap.
2. **~70% of useful agents/skills live in local `.claude/` folders**, never extracted to the plugin marketplace. They get re-invented per project.
3. **The plugin marketplace is MZAI-stack-only** (NestJS + Vue 3 + Quasar). companion-ai (Nuxt 3 + Prisma + Tailwind) and astro-ai-landing (Nuxt 4 + @nuxt/content + i18n SaaS) are unsupported by anything except generic plugins.
4. **speckit is duplicated 4 times** — 1 plugin + 3 local copies. This is a maintenance trap.
5. **High-value missing categories**: i18n coverage automation, Prisma migration safety, SSE streaming review, GSAP audit, blog/content SEO, Capacitor mobile lifecycle (some exist as local skills only).

---

## 1. Current State Inventory

### 1.1 mzai-plugins/plugins/ (the marketplace — 8 plugins)

| Plugin | Skills | Agents | Hooks | Commands | Stack focus |
|---|---|---|---|---|---|
| `astrology-data-validator` | 1 | 1 | 0 | 0 | Swiss Ephemeris validation |
| `cowork-plugin-management` | 2 | 0 | 0 | 0 | Plugin authoring (Anthropic) |
| `speckit` | 29 | 0 | 0 | 0 | SDLC lifecycle |
| `speckit-product-forge` | 29 | 0 | 0 | 0 | Product Forge v1.5.0 |
| `zodiac-design-review` | 6 | 5 | 0 | 0 | Vue/Quasar design audits |
| `zodiac-dev-toolkit` | 11 | 3 | 0 | 0 | NestJS/Vue/Quasar patterns |
| `zodiac-quality-gate` | 8 | 7 | 0 | 0 | Code quality audits |
| `zodiac-research-lab` | 6 | 3 | 0 | 0 | Feature research |
| **Total** | **92** | **19** | **0** | **0** | — |

### 1.2 Local `.claude/` content NOT in plugins

#### `my_zodiac_ai/.claude/`

**Local-only agents (7):** `animation-reviewer`, `api-contract-reviewer`, `eda-compliance`, `fsd-compliance`, `i18n-validator`, `migration-safety-reviewer`, `unit-test-writer`

**Local-only skills (40+):** `admin-panel-dev`, `api-changelog`, `bundle-analyzer`, `capacitor-build`, `capacitor-mobile-ops`, `chaos-engineering`, `docker-compose-ops`, `dotagents`, `env-config-manager`, `event-catalog`, `gsap-animation-gen`, `gsap-preset-gen`, `i18n-workflow`, `k6-load-testing`, `langfuse`, `lighthouse-audit`, `log-analyzer`, `memory-profiler`, `mongodb-ops`, `newrelic-dashboard-builder`, `qdrant-inspect`, `release-workflow`, `rum-analytics`, plus several `*-workspace` and `*.skill` artifacts. Many of these are referenced by name in the host plugin manager (`anthropic-skills:*`), suggesting they were once extracted but the source-of-truth diverged.

**Local hooks (settings.json + scripts):**
- `SessionStart` → `serena-session-start.sh`
- `UserPromptSubmit` → `serena-prompt-reminder.sh`
- `PreToolUse(Edit|Write)` → `.env` block; raw GSAP import warning
- `PostToolUse(Edit|Write)` → `eslint --fix` for back/, front/; `tsc --noEmit` / `vue-tsc` for changed file

#### `companion-ai/.claude/`

**Local-only agents (8):** `cron-job-reviewer`, `eda-consistency-reviewer`, `gsap-audit`, `i18n-coverage`, `prisma-migration-reviewer`, `security-reviewer`, `streaming-pipeline-reviewer`, `subscription-gate-auditor`

**Local hooks:**
- `PostToolUse(Edit|Write)` → `eslint --fix` for `apps/api`, `apps/web`
- `PreToolUse(Edit|Write)` → console reminder when `schema.prisma` is touched

**Local skills:** dozens of `forge-*` and `speckit-*` (mostly duplicates of plugin content).

#### `astro-ai-landing/.claude/`

**Local-only agents (8):** `answerCapsule-writer`, `blog-cross-linker`, `blog-freshness-auditor`, `blog-translator`, `content-seo-auditor`, `nuxt-perf-advisor`, `seo-auditor`, `unit-test-writer`

**Local-only skills (5):** `blog-post`, `i18n-add`, `perf-check`, `playwright-cli`, `seo-check`

**Local hooks:**
- `PreToolUse(Edit|Write)` → blocks edits to `.env`, `pnpm-lock.yaml`, `package-lock.json` (exit 2)
- `PostToolUse(Edit|Write)` → `oxfmt --write` on `.ts`/`.js`
- `PostToolUse(Edit|Write)` → `validate-blog-frontmatter.py`

**Dedicated commands (9):** speckit duplicates.

---

## 2. Gap Analysis (per dimension)

### 2.1 Hooks — biggest gap

The marketplace has zero hook contributions. Hooks are the cheapest, highest-leverage safety net Claude has, and three projects independently re-implemented near-identical patterns. Concrete duplication observed:

| Hook pattern | Where it exists | Where it should be |
|---|---|---|
| Block edits to `.env`/lockfiles | my_zodiac_ai, astro-ai-landing | Reusable plugin |
| ESLint --fix on save (TS/Vue) | my_zodiac_ai, companion-ai | Reusable plugin |
| TypeScript check after edit | my_zodiac_ai only | Reusable plugin |
| Prisma schema reminder | companion-ai only | Reusable plugin |
| GSAP raw-import warning | my_zodiac_ai only | Reusable plugin (companion-ai also uses GSAP) |
| Frontmatter validation | astro-ai-landing only | Reusable plugin (any @nuxt/content user) |
| Serena session reminder | my_zodiac_ai only | All three projects use Serena |

### 2.2 Stack coverage — second biggest gap

zodiac-dev-toolkit assumes NestJS + Vue 3 + Quasar. Reality:

| Project | Backend | Frontend | DB | Mobile |
|---|---|---|---|---|
| my_zodiac_ai | NestJS 11 | Vue 3 + Quasar | MongoDB + Mongoose | Capacitor 8 |
| companion-ai | NestJS 11 | Nuxt 3 + Tailwind | PostgreSQL + Prisma | Capacitor 8 + RevenueCat |
| astro-ai-landing | Nuxt server routes | Nuxt 4 + Tailwind | (none — landing) | (none) |

**Uncovered surfaces:**
- Nuxt 3/4 patterns (composables, server routes, middleware, modules)
- Prisma schema migrations and best practices
- Tailwind without Quasar (utility-first conventions)
- @nuxt/content workflows (collections, queries, hooks)
- Multi-tenant architecture (the platform pivot from 2026-04 needs this)
- RevenueCat mobile billing (different from DodoPayments-only patterns)

### 2.3 Cross-project shared workflows that could be plugins

These three projects share astrology and AI infrastructure but currently re-implement workflows:

- **i18n coverage**: my_zodiac_ai has 11 locales, companion-ai has 6, astro-ai-landing has 10. Each has a different validator.
- **SSE streaming review**: companion-ai has streaming-pipeline-reviewer; my_zodiac_ai has streaming AI for transits/horoscopes; both should share.
- **Subscription gates**: companion-ai has subscription-gate-auditor; my_zodiac_ai has tier-aware features. Both should share.
- **Astrology domain**: zodiac-dev-toolkit/astrology-domain skill exists, but companion-ai also uses zodiac/birth chart logic.

### 2.4 The speckit problem

`speckit` is duplicated 4× (1 plugin + 3 local copies). Skills inside speckit-product-forge are also duplicated locally. Symptoms:

- companion-ai's local `forge-*` skills ↔ speckit-product-forge plugin skills — identical names, possibly drifted bodies
- astro-ai-landing's local `commands/speckit.*.md` ↔ speckit plugin skills — slash command shims
- my_zodiac_ai's local `commands/speckit.*.md` ↔ same

This makes upgrades brittle. Plugins should be the canonical source; local copies should be deleted or pinned.

### 2.5 Subagents — gaps

Currently in plugins (19 agents): all stack-specific or audit-focused. Missing:

- **Prisma migration auditor** — exists locally in companion-ai
- **SSE/streaming pipeline reviewer** — exists locally in companion-ai
- **Subscription gate auditor** — exists locally in companion-ai
- **Cron/scheduled job reviewer** — exists locally in companion-ai (also relevant for MZAI BullMQ)
- **GSAP audit** — exists locally in companion-ai
- **i18n coverage** — exists locally in companion-ai (different from i18n-validator in MZAI)
- **SEO auditor / content auditor** — exists locally in astro-ai-landing
- **Nuxt perf advisor** — exists locally in astro-ai-landing
- **Blog freshness / cross-linker** — exists locally in astro-ai-landing

---

## 3. Concrete Proposals

Proposals are ordered by **value × reach** (high reach = used in 2+ projects). Each proposal lists the destination path inside the marketplace.

### 3.1 NEW PLUGIN — `zodiac-hooks-pack` (HIGH PRIORITY)

**Why:** Zero hooks in marketplace today. Cheapest win.

**Destination:** `plugins/zodiac-hooks-pack/`

**Contents:**

```
plugins/zodiac-hooks-pack/
├── .claude-plugin/plugin.json
├── README.md
└── hooks/
    ├── block-sensitive-files.sh         # .env, *.keystore, lockfiles, secrets
    ├── eslint-on-save.sh                # auto-detects pnpm/npm, runs --fix
    ├── tsc-after-edit.sh                # back/front/api/web aware
    ├── prisma-migration-reminder.sh     # warn on schema.prisma
    ├── gsap-import-guard.sh             # block raw `from 'gsap'` outside animations/
    ├── frontmatter-validator.py         # @nuxt/content compatible
    ├── serena-session-reminder.sh       # nudge Serena usage
    └── i18n-key-checker.sh              # warn if Vue/SFC adds string literal that should be t()
```

Plus a `hooks-config-examples/` directory with snippets for each project's `settings.json` (PreToolUse/PostToolUse matchers, env-vars, paths).

**Migration plan:**
1. Lift hooks from `my_zodiac_ai/.claude/settings.json` and `companion-ai/.claude/settings.json` and `astro-ai-landing/.claude/settings.json` into versioned scripts
2. Each project's local `settings.json` becomes 1-line shims pointing at plugin scripts via `${CLAUDE_PLUGIN_ROOT}`
3. Single-source updates without per-project edits

### 3.2 NEW PLUGIN — `nuxt-toolkit` (HIGH PRIORITY — covers 2/3 projects)

**Why:** companion-ai and astro-ai-landing run on Nuxt. zodiac-dev-toolkit's `vue-frontend-patterns` skill is Quasar-specific and unhelpful for them.

**Destination:** `plugins/nuxt-toolkit/`

**Skills to include:**

| Skill | Source |
|---|---|
| `nuxt-server-routes` | new — composables vs server/api vs server/routes |
| `nuxt-content-workflows` | extracted from astro-ai-landing patterns |
| `nuxt-i18n-multilocale` | merged from astro + companion-ai |
| `nuxt-perf-advisor` | port from astro-ai-landing/.claude/agents/ |
| `nuxt-seo-meta` | extracted from astro-ai-landing useSEO patterns |
| `tailwind-without-quasar` | new — utility-first conventions, design tokens |
| `vueuse-first` | per CLAUDE.md rule "always check VueUse first" |

**Agents:**
- `nuxt-perf-advisor` (lifted from astro-ai-landing)
- `seo-auditor` (lifted from astro-ai-landing)
- `content-seo-auditor` (lifted from astro-ai-landing)

### 3.3 NEW PLUGIN — `companion-stack-toolkit` (MEDIUM)

**Why:** companion-ai is now positioned as a multi-tenant platform (per memory: 2026-04 platform pivot). Spinoffs (Relationship Coach, etc.) will need the same patterns.

**Destination:** `plugins/companion-stack-toolkit/`

**Skills:**
- `prisma-patterns` — schema, migrations, Prisma vs Mongoose tradeoffs
- `sse-streaming-pipeline` — backend SSE setup, frontend EventSource handling
- `revenuecat-mobile-billing` — distinct from DodoPayments
- `qdrant-vector-memory` — embedding patterns (companion-ai uses Qdrant)
- `multi-tenant-architecture` — tenant isolation, white-label patterns

**Agents (port from companion-ai/.claude/agents/):**
- `prisma-migration-reviewer`
- `streaming-pipeline-reviewer`
- `subscription-gate-auditor`
- `cron-job-reviewer`
- `eda-consistency-reviewer`

### 3.4 NEW PLUGIN — `content-blog-toolkit` (MEDIUM — astro-ai-landing focused)

**Why:** astro-ai-landing's blog/content workflows are mature but locked in `.claude/agents/`.

**Destination:** `plugins/content-blog-toolkit/`

**Skills:**
- `blog-post-creation` — port from astro-ai-landing/.claude/skills/blog-post
- `blog-translation` — multi-locale workflows
- `blog-cross-linking` — internal SEO
- `blog-freshness-audit`
- `seo-content-audit` — gap analysis, hreflang, schema.org
- `answer-capsule-generation` — for AI search optimization

**Agents (port from astro-ai-landing/.claude/agents/):**
- `blog-translator`
- `blog-cross-linker`
- `blog-freshness-auditor`
- `answerCapsule-writer`

### 3.5 EXTEND zodiac-dev-toolkit — add missing skills (MEDIUM)

Lift these from `my_zodiac_ai/.claude/skills/` into the plugin:

| Local skill | Action |
|---|---|
| `bundle-analyzer` | Move to plugin (already referenced as `anthropic-skills:bundle-analyzer`) |
| `capacitor-mobile-ops` | Move to plugin (referenced as `anthropic-skills:capacitor-mobile-ops`) |
| `chaos-engineering` | Move to plugin |
| `docker-compose-ops` | Move to plugin |
| `env-config-manager` | Move to plugin |
| `event-catalog` | Move to plugin |
| `gsap-animation-gen` + `gsap-preset-gen` | Merge into `zodiac-dev-toolkit/skills/gsap-patterns/` |
| `i18n-workflow` | Move to plugin (rename to `mzai-i18n-workflow` to distinguish from nuxt-toolkit version) |
| `k6-load-testing` | Move to plugin |
| `lighthouse-audit` | Move to plugin |
| `log-analyzer` | Move to plugin |
| `memory-profiler` | Move to plugin |
| `mongodb-ops` | Move to plugin |
| `newrelic-dashboard-builder` | Move to plugin |
| `release-workflow` | Move to plugin |
| `rum-analytics` | Move to plugin |
| `qdrant-inspect` | Move to companion-stack-toolkit |
| `langfuse` | Move to plugin (LLM observability) |

The host system already lists these as `anthropic-skills:*` — meaning a sister plugin exists somewhere. Either:
- (a) consolidate into mzai-plugins to avoid divergence, or
- (b) treat anthropic-skills as canonical and remove local copies

Pick one path; today both exist and will drift.

### 3.6 EXTEND zodiac-dev-toolkit/agents — add missing agents

Lift from `my_zodiac_ai/.claude/agents/`:

- `animation-reviewer` → `zodiac-design-review/agents/animation-reviewer.md` (better fit there)
- `api-contract-reviewer` → `zodiac-dev-toolkit/agents/`
- `eda-compliance` → consolidate with `zodiac-quality-gate/agents/architecture-auditor` (redundant?)
- `fsd-compliance` → consolidate with `zodiac-quality-gate/agents/architecture-auditor`
- `i18n-validator` → `zodiac-dev-toolkit/agents/`
- `migration-safety-reviewer` → `zodiac-dev-toolkit/agents/` (Mongoose-aware)
- `unit-test-writer` → `zodiac-dev-toolkit/agents/`

Honest note: there is overlap risk between `eda-compliance` agent and `architecture-auditor` agent. Audit before lifting — either merge or document the boundary.

### 3.7 NEW PLUGIN — `astrology-shared` (LOW — but high reach)

**Why:** All 3 projects deal with astrology. Currently zodiac-dev-toolkit/astrology-domain is the only place — but it's Quasar-coupled in description. Extract pure-domain knowledge.

**Destination:** `plugins/astrology-shared/`

**Skills:**
- `astrology-domain-knowledge` — Swiss Ephemeris, aspects, houses, transits, planets (stack-agnostic)
- `zodiac-content-templates` — common copy patterns (horoscope structure, blog patterns)
- `astrology-glossary-i18n` — terminology across 11 locales

This becomes a dependency of zodiac-dev-toolkit, companion-stack-toolkit, content-blog-toolkit.

### 3.8 KILL DUPLICATE — speckit consolidation (LOW EFFORT, HIGH IMPACT)

Single source of truth: `plugins/speckit/` and `plugins/speckit-product-forge/`.

**Action:**
1. Delete `companion-ai/.claude/skills/speckit-*` (62 entries)
2. Delete `companion-ai/.claude/skills/forge-*` (4 entries)
3. Delete `astro-ai-landing/.claude/commands/speckit.*.md` (9 entries)
4. Delete `my_zodiac_ai/.claude/commands/speckit.product-forge.*.md` if marketplace covers them
5. Each project enables `speckit@mzai-plugins` and `speckit-product-forge@mzai-plugins` in `.claude/settings.json`

Risk: local copies may have customizations. Diff before deleting. Lift any genuine customizations into a fork plugin or upstream them.

### 3.9 NEW SKILL — `multi-project-context-loader` (MEDIUM)

**Why:** The user works across 3 projects daily. Right now switching context requires re-reading CLAUDE.md each session. A skill that loads cross-project status (memory + active phase + git branch) into one snapshot would save time.

**Destination:** `plugins/zodiac-research-lab/skills/multi-project-context-loader/`

**Output:** snapshot with active branches, last commit, open Linear issues per project, current Forge phase per feature folder.

### 3.10 SUBAGENT — `cross-project-pattern-extractor` (LOW)

Detects when the same pattern exists in 2+ projects and proposes extraction to a shared plugin. Useful for the platform pivot (companion-ai → multi-tenant).

---

## 4. Priority Matrix

Honest assessment — what to do this month vs later:

| Priority | Item | Effort | Impact | Why |
|---|---|---|---|---|
| **P0** | 3.1 zodiac-hooks-pack | 1–2 days | Very high | Zero hooks today; trivial wins (env block, eslint, tsc) |
| **P0** | 3.8 speckit deduplication | 0.5 day | Medium-high | Maintenance trap; deletes a lot of code |
| **P1** | 3.2 nuxt-toolkit | 3–5 days | High | Unlocks companion-ai + astro-ai-landing parity |
| **P1** | 3.5 lift local skills to zodiac-dev-toolkit | 2–3 days | Medium | Stops drift between local + marketplace |
| **P1** | 3.6 lift local agents | 1–2 days | Medium | Same |
| **P2** | 3.3 companion-stack-toolkit | 2–3 days | Medium | Needed for platform pivot in H2 |
| **P2** | 3.4 content-blog-toolkit | 2–3 days | Medium | astro-ai-landing focused but solid |
| **P3** | 3.7 astrology-shared | 1–2 days | Low immediate | Foundational refactor, do after pivot stabilizes |
| **P3** | 3.9 multi-project-context-loader | 1 day | Low | Nice quality-of-life |
| **P4** | 3.10 cross-project-pattern-extractor | 2 days | Low | Speculative |

---

## 5. Risks & Honest Caveats

1. **Drift between marketplace and `anthropic-skills:*`.** The host already lists 50+ `anthropic-skills:*` that mirror local skills. Before extracting more, decide if mzai-plugins should be canonical or consume from anthropic-skills. Both can't drift independently.

2. **Hooks have a security blast radius.** The proposed `zodiac-hooks-pack` runs shell commands on every Edit/Write. If a malicious file path is ever passed in, hooks could be exploited. All hook scripts must:
   - Quote variables
   - Use absolute paths
   - Not interpret content as code
   - Have a kill switch (env var to disable)

3. **The platform pivot is in-flight (per memory: 2026-04).** companion-ai → white-label multi-tenant means companion-stack-toolkit may need rework once the extraction lands. Don't over-invest in patterns that will change.

4. **eda-compliance vs architecture-auditor overlap.** May be redundant. Audit before lifting — could embarrass the marketplace if two agents argue.

5. **astro-ai-landing's stack (Nuxt 4 + oxlint + oxfmt) is bleeding-edge.** Skills written today may need updates in 6 months as Nuxt 4 patterns mature. Pin Nuxt-specific skills with explicit version compat notes.

6. **The "v-model" speckit skills (10 files in plugin) are largely unused based on local files.** Validate adoption before maintaining them — could be a dead-weight subset to deprecate.

---

## 6. Recommended Next Step

If you want to act on this report, the cheapest highest-value sequence is:

1. **Today (1 hr):** Delete duplicated speckit skills/commands in companion-ai + astro-ai-landing local folders. Enable plugin versions.
2. **This week (2 days):** Build `zodiac-hooks-pack` plugin from existing inline hooks. Replace local hooks with plugin references.
3. **Next sprint:** Build `nuxt-toolkit` plugin — biggest unlock for companion-ai and astro-ai-landing.

Everything else can wait or be done opportunistically.

---

**Companion files:**
- HTML version: `plugin-gap-analysis.html` (same directory)
- Plugin scaffolds (if needed): would live under `plugins/<new-plugin-name>/` per marketplace.json
