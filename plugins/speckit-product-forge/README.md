# SpecKit Product Forge

**Product Forge v1.5.0** — Full feature lifecycle for **My Zodiac AI** (NestJS 11 + Vue 3.5 + Quasar 2.18 + MongoDB 7 + Redis 7 + Capacitor 8 + BullMQ 5 + TypeScript 5.9 + Vitest 4).

Drives a feature from problem discovery through research, product-spec, planning, implementation, verification, testing, release-readiness, and post-launch retrospective — with human-in-the-loop gates, cross-artifact sync-verify between every phase, and a complete audit trail.

## Feature modes

Mode is resolved from `.product-forge/config.yml` (`default_feature_mode`):

| Mode | Phases |
|------|--------|
| **lite** | problem-discovery (opt) → product-spec → plan → implement → verify |
| **standard** *(default for My Zodiac AI)* | research → product-spec → revalidate → bridge → plan → tasks → pre-impl-review → implement → code-review → verify → test-plan → test-run → release-readiness |
| **v-model** | Extension pack: acceptance → architecture-design → system-design → module-design → hazard-analysis → unit/integration/system tests → trace → peer-review → audit-report |

## Start here

```
/speckit.product-forge.forge
```

The orchestrator reads `.forge-status.yml`, auto-detects resume point, and walks the feature through every phase with approval gates.

Feature folders live in `features/NNN-feature-name/` with research artifacts under `features/<slug>/research/`.

## Phase map (standard mode)

| Phase | Skill | Artifact | Conditional |
|-------|-------|----------|-------------|
| 0 | `problem-discovery` | `problem-discovery/problem-statement.md` | optional |
| 1 | `research` | `research/` (5 dimensions) | |
| 2 | `product-spec` | `product-spec/README.md` | |
| 3 | `revalidate` | `review.md` (APPROVED) | |
| 4 | `bridge` | `spec.md` (SpecKit bridge) | |
| 4.5 | `i18n-harvest` | `i18n/keys.yml` | multi-locale features |
| 5 | `plan` | `plan.md` | |
| 5B | `tasks` | `tasks.md` | |
| 5.5 | `migration-plan` | `migrations/migration-plan.md` | MongoDB schema changes |
| 5C | `pre-impl-review` | `pre-impl-review.md` | optional |
| 6 | `implement` | Implementation gaps | |
| 6B | `code-review` | `code-review.md` | optional |
| 7 | `verify-full` | `verify-report.md` | |
| 8A | `test-plan` | `testing/test-plan.md` | optional |
| 8B | `test-run` | `test-report.md` | optional |
| 9 | `release-readiness` | `release-readiness.md` | optional |
| 9.5 | `monitoring-setup` | `monitoring/slo.md` | optional |
| 9B | `experiment-design` | `experiment/experiment-design.md` | experiment flag |
| post-launch | `retrospective` | `retrospective.md` | |

## Cross-cutting & utilities

| Skill | Purpose |
|-------|---------|
| `status` | Show feature progress from `.forge-status.yml` |
| `sync-verify` | 7-layer artifact consistency check |
| `change-request` | Formal scope change with impact analysis |
| `portfolio` | Cross-feature view, conflicts, merge order |
| `feature-flag-cleanup` | Stale flag audit |
| `api-docs` | OpenAPI 3.1 + Postman from plan.md contracts |
| `security-check` | Feature-scoped OWASP audit |
| `tracking-plan` | Event taxonomy, funnel definitions, SDK snippets |
| `backfill` | Generate specs from already-shipped code |

## All 29 skills

| Skill | Trigger |
|-------|---------|
| `forge` | `/speckit.product-forge.forge` — full lifecycle orchestrator |
| `status` | `/speckit.product-forge.status` |
| `problem-discovery` | `/speckit.product-forge.problem-discovery` |
| `research` | `/speckit.product-forge.research` |
| `product-spec` | `/speckit.product-forge.product-spec` |
| `revalidate` | `/speckit.product-forge.revalidate` |
| `bridge` | `/speckit.product-forge.bridge` |
| `i18n-harvest` | `/speckit.product-forge.i18n-harvest` |
| `plan` | `/speckit.product-forge.plan` |
| `tasks` | `/speckit.product-forge.tasks` |
| `migration-plan` | `/speckit.product-forge.migration-plan` |
| `pre-impl-review` | `/speckit.product-forge.pre-impl-review` |
| `implement` | `/speckit.product-forge.implement` |
| `code-review` | `/speckit.product-forge.code-review` |
| `verify-full` | `/speckit.product-forge.verify-full` |
| `test-plan` | `/speckit.product-forge.test-plan` |
| `test-run` | `/speckit.product-forge.test-run` |
| `release-readiness` | `/speckit.product-forge.release-readiness` |
| `monitoring-setup` | `/speckit.product-forge.monitoring-setup` |
| `experiment-design` | `/speckit.product-forge.experiment-design` |
| `retrospective` | `/speckit.product-forge.retrospective` |
| `sync-verify` | `/speckit.product-forge.sync-verify` |
| `change-request` | `/speckit.product-forge.change-request` |
| `portfolio` | `/speckit.product-forge.portfolio` |
| `feature-flag-cleanup` | `/speckit.product-forge.feature-flag-cleanup` |
| `api-docs` | `/speckit.product-forge.api-docs` |
| `security-check` | `/speckit.product-forge.security-check` |
| `tracking-plan` | `/speckit.product-forge.tracking-plan` |
| `backfill` | `/speckit.product-forge.backfill` |

## Requirements

- `.specify/memory/constitution.md` — project constitution (My Zodiac AI specific)
- `.product-forge/config.yml` — feature mode, tech stack, codebase path
- `features/` — feature folders following the NNN-slug convention

## What changed in v1.5.0

- Mode resolution reads `default_feature_mode` from `.product-forge/config.yml`
- V-Model extension pack support
- Automatic escalation from `lite` → `standard` based on triggers
- State lock protocol and phase digest requirement
- New phases: 4.5 (i18n-harvest), 5.5 (migration-plan), 9.5 (monitoring-setup), 9B (experiment-design)
- New cross-cutting skills: `portfolio`, `feature-flag-cleanup`, `backfill`
