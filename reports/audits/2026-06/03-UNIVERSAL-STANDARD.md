# Universal Skill & Plugin Standard (mzai-plugins)

> **Status:** proposed standard v1.0 — the contract every plugin/skill/agent/hook in this marketplace must satisfy.
> **Audience:** anyone authoring or refactoring a plugin in `my-zodiac-ai/mzai-plugins`.
> **Goal:** make every artifact reusable across the org's JS/TS stacks (NestJS, Nuxt 3/4, Vue 3/Quasar, Prisma/Mongoose, Capacitor) — **universal core + thin stack adapters** — with zero hardcoded project identity.
> **Grounding:** [Claude Code – Create plugins](https://code.claude.com/docs/en/plugins), [Anthropic – Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices), [Anthropic – Equipping agents with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills), [GitHub spec-kit](https://github.com/github/spec-kit).

Rules are numbered (`S-*` skills, `P-*` plugins, `H-*` hooks, `D-*` docs, `SDD-*` spec-driven flow, `CI-*` validation). The backlog references these IDs.

---

## 1. The core model: Universal Core + Thin Stack Adapter

The single most important rule. Every capability is split into two layers:

- **Universal core** — the *method*, *principles*, and *decision procedure*, expressed with **zero** framework names, project paths, or infra IDs. A core skill works in any JS/TS repo (often any repo). Example: "cache-aside with TTL, stampede protection, and explicit invalidation keys" — true for Redis, Keyv, in-memory, anything.
- **Stack adapter** — a thin, clearly-scoped overlay that maps the universal core onto one concrete stack. Example: "NestJS + ioredis: use `CacheModule`, key prefix from config, `@Cacheable` decorator." Adapters are **short** and only contain stack-specific syntax/commands, never re-explain the method.

```
plugins/
  core-engineering/            # universal-core plugin: principles, methods, language-agnostic
  adapter-nestjs/              # thin: maps core onto NestJS
  adapter-nuxt/                # thin: maps core onto Nuxt 3/4
  adapter-vue-quasar/          # thin: maps core onto Vue 3 + Quasar
  domain-astrology/            # product domain (stays out of "engineering" plugins)
```

**Rules:**
- **S-1.** A skill is either *core* (no stack/domain identity) or *adapter* (one stack, minimal). Never mix. If a skill needs both, split it.
- **S-2.** Adapters **reference** the core skill ("apply the `caching-patterns` core, then…"); they MUST NOT copy the core method text. Single source of truth.
- **S-3.** Product domain knowledge (astrology, Cosmic Glass, payment tiers, bounded-context names) lives ONLY in `domain-*` plugins or in the product repo — never inside an engineering skill body. Domain may appear only inside a clearly-labelled `## Example` block.
- **S-4.** Decision test for "is this portable?": *Could a Nuxt+Prisma+Postgres team use this skill unchanged?* If no, it's an adapter or it's coupled — label it as such in frontmatter (`x-scope: core | adapter:<stack> | domain:<name>`).

---

## 2. Directory & manifest layout (P-*)

Grounded in Claude Code plugin docs.

- **P-1.** Plugin manifest is `.claude-plugin/plugin.json`. **Only** `plugin.json` lives inside `.claude-plugin/`. All component dirs (`skills/`, `agents/`, `commands/`, `hooks/`) sit at the plugin **root**.
- **P-2.** `plugin.json` required/expected fields: `name` (kebab-case), `version` (SemVer), `description`, `author`, `keywords`, `license`. Author string is normalized org-wide: **`Valentyn Yakovliev`** (fix `astrology-data-validator`'s `"Valentyn"`).
- **P-3.** One skill = one directory `skills/<skill-name>/SKILL.md` (+ optional `references/`, `scripts/`, `evals/`). `name` in frontmatter MUST equal the directory name.
- **P-4.** `marketplace.json` is the catalog; it carries `name/description/source` per plugin and defers `version`/`author` to each `plugin.json`. It must list exactly the dirs present in `plugins/` (no more, no less).
- **P-5.** Repo MUST have a top-level `LICENSE`. Any vendored third-party plugin (e.g. Apache-2.0 `cowork-plugin-management`) must be acknowledged there, or referenced upstream instead of vendored.
- **P-6.** A plugin covers **one** concern. `zodiac-dev-toolkit` (backend+mobile+observability+payments+AI+testing+domain) violates this and must be split (see backlog B-07).

---

## 3. Skill authoring rules (S-*)

Grounded in Anthropic skill-authoring best practices (progressive disclosure, ≤500 lines, name+description frontmatter).

### 3.1 Frontmatter
- **S-5.** Required: `name`, `description`. Optional but recommended: `allowed-tools` (MUST be present on any skill that shells out), `x-scope` (see S-4), `x-stack` (e.g. `nestjs`, `nuxt`, `any`).
- **S-6.** `description` is the activation contract: 1–3 sentences, concrete trigger phrases, bilingual RU+EN (keep — this is a current strength). **MUST NOT contain project identity** ("for My Zodiac AI", module names). The description decides activation in OTHER repos too — pollute it and you mis-fire.
- **S-7.** `allowed-tools` MUST scope script-running skills (e.g. `Bash(playwright:*)`). Today only `playwright-cli` does this; `bundle-analyzer`, `lighthouse-audit`, `rum-analytics`, `docker-compose-ops`, `mongodb-ops` shell out without it — fix.

### 3.2 Body & progressive disclosure
- **S-8.** SKILL.md body ≤ **500 lines**. Over that, push detail into `references/*.md` loaded on demand. (`chaos-engineering` 425, `test-run` 760, `forge` 687 — audit for trimming; the 760-line one must split.)
- **S-9.** Structure: `## When to use` → `## Method/Steps` → `## Output` → `## Examples` (domain examples allowed only here) → links to `references/`. Lead with the decision procedure, not narrative.
- **S-10.** No absolute paths, ever. No `/Users/...`, no `/sessions/<id>/mnt/...`. Use repo-relative paths derived at runtime (`git rev-parse --show-toplevel`) or config.
- **S-11.** No hardcoded infrastructure identity: account IDs (`7715788`), app IDs (`538822289`), MCP instance hashes (`mcp__3dc9ae8a-...`), DB names, bundle IDs. Use placeholders + a documented config source: `${NEW_RELIC_ACCOUNT_ID}`, `${APP_NAME}`, read from `.env`/project config. Refer to MCP tools by **generic name/domain**, never the instance hash.
- **S-12.** Stack/version facts are stated as **minimums or detected**, not as fixed truths. Prefer "detect the test runner" over "Vitest only". If a version must appear, mark it `# as of <date>, verify`.
- **S-13.** Cross-references must resolve. A skill may not link to a file that isn't shipped in the plugin (see C2 in critique: forge → `../docs/*`). CI enforces this (CI-1).

### 3.3 Evals
- **S-14.** Every substantive skill SHOULD ship `evals/evals.json` with ≥3 representative tasks (prompt + expected). Per Anthropic guidance, evals come from observing real failures.
- **S-15.** Eval fixtures MUST be parameterized/synthetic — no real account IDs, branch names, or routes. An eval that only runs in one repo is not an eval.

---

## 4. Agents (when, and how to avoid duplication)

- **A-1.** Create an agent only when you need a **separate context window / parallel fan-out / restricted toolset** — not as a mirror of a skill. The current `quality-gate` (7) and `design-review` (5) skill↔agent 1:1 mirrors are bloat.
- **A-2.** If an orchestrator dispatches agents, each agent MUST be a **pure shim**: "Read skill `X`, apply it to `<target>`, return findings in `<format>`." Zero inlined methodology. Method lives in the skill (single source of truth).
- **A-3.** Agent frontmatter: unique `color` per agent in a parallel set (fix duplicate `green`); `tools` in the documented form; `model: inherit` unless there's a reason.
- **A-4.** Before adding an agent, check for an existing host/Anthropic equivalent (`deep-research`, `competitor-analysis`, `ux-research`, etc.). Prefer thin wrappers over re-implementations (kills the research-lab 6/6 duplication).

---

## 5. Hooks rules (H-*)

Hooks run shell on every Edit/Write — security- and reliability-sensitive.

- **H-1.** Read stdin **exactly once**, at the top of the hook, into a local var; pass it to helpers as an argument. NEVER read stdin inside a function called from `$(...)` (this is the C3 bug that killed two hooks). Add a regression test for the positive path.
- **H-2.** Fail-soft: every advisory hook exits 0 on any internal error; only blocking hooks (`exit 2`) abort. Keep `set -u`, avoid `set -e`.
- **H-3.** Kill switches: global (`ZODIAC_HOOKS_DISABLE=1`) + per-hook env. Keep.
- **H-4.** Never interpret file content or filename as code. Quote all expansions. Parse JSON via `python3`/`jq`, not shell interpolation. (`block-sensitive-files.sh` is the reference implementation.)
- **H-5.** Self-detecting + no-op when irrelevant (grep `package.json` for the dep, check marker dirs). Path gates must be configurable, not hardcoded to `front/src` (so Nuxt `app/`, `apps/web/` work).
- **H-6.** Expensive filesystem ops (`find`) MUST be wrapped in `timeout`.
- **H-7.** Claims in the hook README must match the code. Don't claim "paths validated as absolute" if the guard (`zh_in_project`) is never called — either wire it or drop the claim.
- **H-8.** `tests/smoke.sh` MUST include a **positive-detection** case for every advisory hook (feed a fully-qualifying payload, assert a warning is produced), not only no-op cases.

---

## 6. SDD doc-structuring convention (SDD-*)

SDD tooling is **external** to this marketplace (removed 2026-06) and installed per project — do NOT vendor it here:
- **SpecKit** — base flow, [github/spec-kit](https://github.com/github/spec-kit) (MIT). Install via `specify init`.
- **Product Forge** — product lifecycle extension on top of SpecKit, [VaiYav/speckit-product-forge](https://github.com/VaiYav/speckit-product-forge) (MIT). Install via `specify extension add product-forge --from <zip>`.

Reference the official repos and let `specify` manage versions (vendoring caused drift: the in-repo copy was tagged `v1.5.0` while upstream latest is `v1.3.0`). Canonical flow (current, June 2026): **Constitution → Specify → Plan → Tasks → Implement** (+ Clarify/Analyze/Verify gates).

The org's *usage* conventions on top of these external tools:

- **SDD-1.** Each project has ONE real `constitution.md` (non-negotiable principles), not just a template. First artifact; supersedes other practices.
- **SDD-2.** Each feature lives in `specs/<NNN-slug>/`: `spec.md` (what/why, no tech), `plan.md` (architecture/contracts), `tasks.md` (ordered, dependency-aware). One feature-dir convention org-wide.
- **SDD-3.** Project stack specifics come from the project's `constitution.md` / Product Forge `config.yml` (`project_tech_stack`, `codebase_path`) — never hardcoded into shared skills/templates.
- **SDD-4 (upstream, not our repo).** The forge `docs/` brain, v-model wiring, and `.forge-status.yml` schema belong to the external VaiYav/speckit-product-forge repo. Findings C2/H3 in `01-CRITIQUE` are upstream feedback there; if the org forks Product Forge, that fork owns the fixes.

---

## 7. Documentation rules (D-*)

- **D-1.** README counts and lists are generated from the filesystem (or CI-checked), never hand-maintained drift (README says 11, reality 23).
- **D-2.** Every plugin appears in the README table (hooks-pack is missing today).
- **D-3.** No stale absolute/sandbox paths in any doc (`/sessions/jolly-magical-ride/...`, `/sessions/kind-wonderful-gates/...`). Delete or regenerate `BUNDLING_REPORT.md`.
- **D-4.** One version per plugin, consistent across `plugin.json`, README, `init-options`, and any embedded "vX.Y" prose.
- **D-5.** Reference data (e.g. ephemeris) MUST carry per-value provenance: source, query/JD, version, date. No hand-constructed values presented as measured truth (Moon = Sun+180.00).

---

## 8. Plugin CI / self-validation (CI-*)

The cheapest fix for most of the above: a linter that runs in CI on the marketplace repo.

- **CI-1.** Broken-reference check: every `../<path>` / `references/<file>` / script referenced by a SKILL/agent must exist. (Would have caught forge→`docs/`, the `claude-api-integration` ghost.)
- **CI-2.** No-hardcode check: grep-fail the build on `/Users/`, `/sessions/`, known infra IDs (`7715788`, `538822289`), `mcp__[0-9a-f-]{8,}` hashes, absolute `PROJECT_ROOT=`.
- **CI-3.** Manifest check: `marketplace.json` plugin list == `plugins/` dirs; every `plugin.json` valid + has required fields; author normalized; one version per plugin.
- **CI-4.** README-count check: skill/agent counts in README == `find` counts.
- **CI-5.** Skill lint: frontmatter has `name`+`description`; `name`==dir; body ≤500 lines; `allowed-tools` present if skill shells out.
- **CI-6.** Hook test: `tests/smoke.sh` runs and includes positive-detection cases; `bash -n` + `py_compile` on all scripts.
- **CI-7.** Portability scan: flag domain terms (astrology/zodiac/cosmic/natal/horoscope) and stack terms (Quasar, Mongoose, `back/`, `front/`) appearing in `core-*` plugins; allowed only in `domain-*`/`adapter-*` or `## Example` blocks.

---

## 9. Definition of Done for a refactored skill

A skill is "done to standard" when:
1. `x-scope` declared (core/adapter/domain); body matches that scope (S-1…S-4).
2. Zero absolute paths, zero infra literals, zero project identity in body/description (S-10, S-11, S-6).
3. ≤500 lines; detail in `references/` (S-8).
4. All cross-refs resolve (S-13 / CI-1).
5. `allowed-tools` set if it shells out (S-7).
6. `evals/evals.json` with ≥3 parameterized cases (S-14, S-15).
7. Passes CI-1…CI-7.
8. A Nuxt+Prisma team could use it unchanged (core) or it's explicitly an adapter.

---

## Sources
- [Claude Code — Create plugins](https://code.claude.com/docs/en/plugins)
- [Anthropic — Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [Anthropic — Equipping agents for the real world with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [GitHub spec-kit](https://github.com/github/spec-kit) · [spec-driven.md](https://github.com/github/spec-kit/blob/main/spec-driven.md)
