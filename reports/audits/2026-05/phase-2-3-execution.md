# Phase 2 + Phase 3 Execution Report

> **Date:** 2026-05-06
> **Status:** Done. Honest postmortem below — including where the original playbook was wrong.

---

## What changed

### `mzai-plugins/plugins/zodiac-dev-toolkit/skills/`

**Before:** 11 skills
**After:** 23 skills (+12 lifted)

| Skill | Source | Notes |
|---|---|---|
| `k6-load-testing` | my_zodiac_ai local | clean lift (no project-coupled paths) |
| `lighthouse-audit` | my_zodiac_ai local | works for MZAI; `front/` refs documented inside |
| `playwright-cli` | my_zodiac_ai local | clean lift |
| `langfuse` | my_zodiac_ai local | LLM observability, stack-agnostic |
| `rum-analytics` | my_zodiac_ai local | works for MZAI; `front/` refs |
| `api-changelog` | my_zodiac_ai local | clean lift |
| `bundle-analyzer` | my_zodiac_ai local | works for MZAI; `front/` refs (TODO: parameterize for Nuxt projects) |
| `newrelic-dashboard-builder` | my_zodiac_ai local | zero project-coupled paths, fully reusable |
| `mongodb-ops` | my_zodiac_ai local | Mongoose-aware (companion-ai uses Prisma — won't apply) |
| `chaos-engineering` | my_zodiac_ai local | one `back/` ref — minor |
| `docker-compose-ops` | my_zodiac_ai local | works for monorepos |
| `capacitor-mobile-ops` | my_zodiac_ai local | MZAI-coupled (29 `front/` refs); works for MZAI as-is |

### Deletions (moved to `.trash/2026-05-06-*` — recoverable)

| Project | Path | Count | Reason |
|---|---|---|---|
| companion-ai | `.claude/skills/speckit-product-forge-*` | 29 | Verified zero body diff vs plugin |
| my_zodiac_ai | `.claude/skills/speckit-product-forge-*` | 29 | Same |
| my_zodiac_ai | `.claude/skills/{7 lifted skills}` | 7 | Now live in zodiac-dev-toolkit |
| my_zodiac_ai | `.claude/skills/{5 lifted skills round 2}` | 5 | Same |

**Total:** 70 skill directories moved to `.trash/`. Reversible with `mv`.

### What I did NOT delete (and why)

Items I touched but explicitly skipped:

| Item | Why kept |
|---|---|
| `companion-ai/.claude/skills/speckit-{analyze,plan,specify,...}` (9 dirs) | Body diff 80–274 lines vs plugin — STALE or CUSTOMIZED. Need user decision. |
| `companion-ai/.claude/skills/speckit-v-model-*` (17 dirs) | 9 have plugin equivalents with **300–430 line drift**; 8 have NO plugin equivalent (audit-report, hazard-analysis, impact-analysis, implement, peer-review, plan, tasks, test-results). Deleting would lose unique content. |
| `companion-ai/.claude/skills/speckit-git-*` (5 dirs) | NO plugin equivalent. Local-only utility skills. |
| `companion-ai/.claude/skills/forge-*` (4 dirs) | NO plugin equivalent at those names. |
| `my_zodiac_ai/.claude/commands/speckit.*.md` (60 files) | Slash command shims with `handoffs:` frontmatter — different invocation contract than plugin skills. Body drift up to 435 lines. Removing breaks `/speckit.*` UX. |
| `astro-ai-landing/.claude/commands/speckit.*.md` (8 files) | Same as above. Body drift 17–282 lines. |
| `my_zodiac_ai/.claude/skills/sentry-*` (~25 dirs) | Belong to Sentry SDK plugin, not mzai. Out of scope. |
| `my_zodiac_ai/.claude/skills/*-workspace`, `*.skill` | Workspace variants / WIP. Per playbook "do not lift". |
| `my_zodiac_ai/.claude/skills/{env-config-manager,event-catalog,user-journey-testing,run-migration,storybook-generator}` | Heavy `back/` or `front/` coupling — would mislead non-MZAI projects. |
| `my_zodiac_ai/.claude/skills/qdrant-inspect` | Save for `companion-stack-toolkit` (companion-ai is the Qdrant user) |
| `astro-ai-landing/.claude/skills/{blog-post,i18n-add,perf-check,seo-check}` | Save for `content-blog-toolkit` (Phase 5) |

---

## Where the original playbook was wrong

### Wrong assumption #1: "speckit copies are duplicates"

**Reality:** Most are NOT pure duplicates. Body-content diff sizes:

- **companion-ai's speckit-product-forge-***: ✅ 0 lines drift across all 29 files → safe to delete
- **companion-ai's speckit-{analyze,...}**: ❌ 80–274 lines drift
- **my_zodiac_ai's speckit-product-forge-***: ✅ 0 lines drift across all 29 → safe
- **my_zodiac_ai's commands speckit.*.md**: ❌ 4–435 lines drift, plus `handoffs:` metadata that plugin lacks
- **astro-ai-landing's commands speckit.*.md**: ❌ 17–282 lines drift, plus `handoffs:`

**Lesson:** Mass dedup needs per-file diff verification, not name matching.

### Wrong assumption #2: "Local commands are the same UX as plugin skills"

**Reality:** They're different invocation contracts.

- Plugin `speckit:specify` is invoked via the `Skill` tool with a namespaced name.
- Local `commands/speckit.specify.md` is invoked as a `/speckit.specify` slash command, and may include `handoffs:` metadata that produces "next step" UI buttons.

Removing local commands removes the slash-command UX. Per-project decision; not bulk-deletable.

### Wrong assumption #3: "v-model skills duplicate the plugin"

**Reality:** companion-ai has 17 `speckit-v-model-*` skills. 9 mirror the plugin (with significant drift). 8 are LOCAL-ONLY:

- `speckit-v-model-audit-report`
- `speckit-v-model-hazard-analysis`
- `speckit-v-model-impact-analysis`
- `speckit-v-model-implement`
- `speckit-v-model-peer-review`
- `speckit-v-model-plan`
- `speckit-v-model-tasks`
- `speckit-v-model-test-results`

These represent unique IP. Deleting them = data loss. Should either be lifted to plugin or kept local. **User decision required.**

### Wrong assumption #4: "Lifting skills is purely additive"

**Reality:** The host already exposes these as `anthropic-skills:*` from Anthropic's marketplace. After my lift, the same skill exists in:

1. Anthropic's marketplace (e.g. `anthropic-skills:k6-load-testing`)
2. mzai-plugins (now `zodiac-dev-toolkit:k6-load-testing`)

Both can coexist (different namespaces). But this is exactly the "drift between sources" risk flagged in the gap analysis. Resolution still pending.

---

## Outstanding decisions for user

1. **What to do with the 9 speckit-v-model-* skills that exist only in companion-ai?**
   - Option A: lift to `plugins/speckit/skills/v-model-{audit-report,hazard-analysis,...}`
   - Option B: keep local in companion-ai (acknowledge they're project-specific)
   - Option C: delete (if unused)

2. **What to do with 60+ slash commands in `my_zodiac_ai/.claude/commands/speckit.*.md`?**
   - Option A: keep all (preserve `/speckit.*` UX, accept drift)
   - Option B: delete + retrain user to invoke `Skill(skill: 'speckit:specify')` via plugin
   - Option C: regenerate from plugin source with `handoffs:` re-applied (best of both)

3. **Anthropic-skills overlap:** mzai-plugins now duplicates `k6-load-testing`, `lighthouse-audit`, etc. that anthropic-skills also provides. Pick one canonical source per skill, or accept both.

4. **39 unmoved local skills in my_zodiac_ai:**
   - 25 sentry-* (out of scope — Sentry SDK plugin)
   - 5 *-workspace / *.skill (intentionally local)
   - Remaining 9 (`env-config-manager`, `event-catalog`, `user-journey-testing`, `run-migration`, `storybook-generator`, `dotagents`, `admin-panel-dev.skill`, `gsap-*`, `i18n-workflow`) — most need parameterization before lift. Should I do that work?

---

## Verification

```bash
# Plugin test still passes:
cd mzai-plugins/plugins/zodiac-hooks-pack
bash tests/smoke.sh  # → 27 passed, 0 failed

# Trash directories exist for recovery:
ls my_zodiac_ai/.trash/2026-05-06-skills-lifted-to-plugin/    # 41 dirs
ls companion-ai/.trash/2026-05-06-speckit-dedup/              # 29 dirs
```

To revert any deletion:
```bash
mv companion-ai/.trash/2026-05-06-speckit-dedup/<name> companion-ai/.claude/skills/
```

---

## Final state

| Location | Count | Delta |
|---|---|---|
| mzai-plugins/plugins/zodiac-dev-toolkit/skills/ | 23 | +12 |
| mzai-plugins/plugins/zodiac-hooks-pack/ | 1 plugin (8 hooks) | new |
| companion-ai/.claude/skills/ | ~35 | −29 |
| my_zodiac_ai/.claude/skills/ | 90 | −41 (12 lifted + 29 dupes) |
| astro-ai-landing/.claude/skills/ | 5 | unchanged (saved for Phase 5) |

**Phase 1 (hooks) ✅** · **Phase 2 (dedup) ⚠ partial — only safe-verified** · **Phase 3 (lifts) ✅ stack-agnostic only**

**Next phases pending:**
- Phase 4 (lift agents) — blocked on architecture-auditor overlap audit
- Phase 5 (new plugins: nuxt-toolkit, content-blog-toolkit, companion-stack-toolkit)
- Cleanup: drift reconciliation for ~80 stale local skills
