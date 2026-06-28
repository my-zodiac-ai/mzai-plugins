# Worked example #1 — refactor `redis-caching` → `caching-patterns` (core) + `nestjs` (adapter)

Demonstrates the **universal-core + thin-adapter** model (`03-UNIVERSAL-STANDARD.md` §1) on a real, currently hard-coupled skill.

## What was wrong with the original
Source: `plugins/zodiac-dev-toolkit/skills/redis-caching/SKILL.md` (205 lines). Coupling found:
- Domain leaks in body: cache keys `COSMIC_WEATHER/HOROSCOPE/NATAL_CHART/USER_TIER/AI_GENERATION` (`:62-69`), example `"cw:userId:2026-03-19"` (`:74`), TTL table rows "Natal chart / Daily horoscope / Cosmic weather" (`:81-86`), "Swiss Ephemeris is CPU-heavy" (`:126`).
- Framework lock: NestJS `@nestjs/cache-manager`, BullMQ queue `cosmic-weather-v2-forge-scan` (`:137,149,158`), Mongoose `this.model.findOne` (`:184-189`), Redlock module path `infrastructure/redlock/` (`:18`).
- Title itself: "Redis & Caching Patterns — My Zodiac AI" (`:12`).
- `description` names project modules (`:8-9`) → mis-fires activation in other repos.

A Nuxt+Prisma+Keyv team cannot use this unchanged → fails the portability test (S-4).

## The split
- **`core-engineering/skills/caching-patterns`** — the method (cache-aside, TTL policy, stampede protection, invalidation, background jobs), zero stack/domain. Reusable in any repo.
- **`adapter-nestjs/skills/nestjs-caching`** — thin: maps the core onto NestJS + cache-manager + BullMQ + Redlock. ~40 lines, references the core, does not re-explain it.

Domain TTLs/keys (cosmic-weather etc.) move OUT of the toolkit entirely → into the product repo's config.

---

## AFTER — core skill (`core-engineering/skills/caching-patterns/SKILL.md`)

```markdown
---
name: caching-patterns
description: >
  Application caching method — cache-aside, TTL policy, cache stampede protection,
  explicit invalidation, and background recomputation. Stack-agnostic. Use for
  "add caching", "cache this endpoint", "invalidate cache", "TTL strategy",
  "distributed lock", "background job", "кэширование", "добавь кэш", "инвалидация".
x-scope: core
x-stack: any
---

# Caching Patterns

## When to use
Adding or reviewing any read-through cache, choosing a TTL, preventing stampede,
invalidating on writes, or moving expensive work to a background job.

## Cache-aside (primary)
1. Build a deterministic key from a documented prefix + identifying parts.
2. Read cache; on hit, return.
3. On miss, compute, then write with an explicit TTL.
4. Cache access MUST degrade, not crash: treat the cache as optional.

## Key policy
- Keys come from a single generator `key(prefix, ...parts)` → `prefix:part:part`.
- Prefixes live in ONE config map owned by the project. Never hardcode key strings inline.

## TTL policy (decide per data class, not per entity)
| Data class | TTL guidance |
|---|---|
| Expensive + rarely changes | long (hours–day) |
| Changes a few times/day | medium (hours) |
| Must reflect state changes fast (e.g. entitlements) | short (minutes) |
| Counters / rate windows | sliding, sub-minute |
Rule: never store without a TTL; never rely on TTL alone for correctness-critical writes.

## Invalidation
- Invalidate on write. Prefer event-driven invalidation for cross-module changes.
- Invalidation handlers must never throw (swallow + log).
- Support prefix/batch delete for fan-out keys.

## Stampede protection
- For expensive recomputations, guard with a distributed lock (key + TTL) and
  double-check the cache/store after acquiring. Always release in `finally`.

## In-memory layer
- Use a bounded LRU (max + ttl) for single-instance hot data; shared cache for
  cross-instance state. Bounded only — no unbounded maps.

## Background recomputation
- Move heavy/async work to a queue with retries + backoff + bounded retention.
- Name jobs `{feature}-{action}`; configure `attempts` and `backoff` always.

## Rules
1. Cache client is optional — app works without it.
2. Wrap every cache op in try/catch; degrade on failure.
3. Always use the key generator; never inline key strings.
4. Invalidate via events across modules.
5. TTL on everything; LRU bounded; queues always retry.

## Example (domain overlay — illustrative only)
A project may map prefixes in its own config, e.g. `WEATHER`, `PROFILE`, `ENTITLEMENT`,
with project-chosen TTLs. Those values belong to the product repo, not this skill.
```

---

## AFTER — thin adapter (`adapter-nestjs/skills/nestjs-caching/SKILL.md`)

```markdown
---
name: nestjs-caching
description: >
  NestJS mapping of the caching-patterns core — cache-manager/Keyv, BullMQ queues,
  and Redlock distributed locks. Use when implementing caching in a NestJS service.
x-scope: adapter:nestjs
x-stack: nestjs
---

# NestJS Caching (adapter)

Apply the `caching-patterns` core first. This file only maps it to NestJS syntax.

- **Cache-aside:** inject `@Inject(CACHE_MANAGER) @Optional() cache?: Cache`;
  `cache?.get` / `cache?.set(key, val, ttlMs)`. `@Optional()` satisfies core rule #1.
- **Keys:** put the prefix map + `generateCacheKey()` in the project's `config/`.
- **Invalidation:** use `@OnEvent(..., { async: true })` listeners; never throw (core invalidation rule).
- **Stampede:** wrap with your `DistributedLockService.acquire(key, ttlMs)` (Redlock); release in `finally`.
- **Background jobs:** `BullModule.registerQueue({ name, defaultJobOptions: { attempts, backoff } })`;
  `@Processor` + `WorkerHost`. Job name `{feature}-{action}`.

See core `caching-patterns` for the method, TTL policy, and rules. Do not duplicate them here.
```

---

## Result
- Body that was 205 project-specific lines → ~70-line stack-agnostic core + ~25-line adapter.
- Zero domain terms / infra IDs / absolute paths in the core (passes CI-2, CI-7).
- A Nuxt+Keyv team uses the core unchanged and writes (or skips) their own tiny adapter.
- Single source of truth: the method exists once; the adapter only maps syntax (S-2).
