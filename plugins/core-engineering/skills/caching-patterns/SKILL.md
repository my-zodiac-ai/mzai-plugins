---
name: caching-patterns
description: >
  Application caching method — cache-aside, TTL policy, cache stampede protection, explicit
  invalidation, and background recomputation. Stack-agnostic (Redis, Keyv, in-memory, anything).
  Use for "add caching", "cache this endpoint", "invalidate cache", "TTL strategy", "distributed
  lock", "background job", "кэширование", "добавь кэш", "инвалидация кэша", "распределённый лок".
x-scope: core
x-stack: any
---

# Caching Patterns

The method, independent of any cache backend or framework. For a concrete mapping see a stack
adapter (e.g. `adapter-nestjs` → `nestjs-caching`).

## When to use
Adding or reviewing any read-through cache, choosing a TTL, preventing stampede, invalidating on
writes, or moving expensive work to a background job.

## Cache-aside (primary pattern)
1. Build a deterministic key from a documented prefix + identifying parts.
2. Read cache; on hit, return.
3. On miss, compute, then write with an explicit TTL.
4. Cache access MUST degrade, not crash: treat the cache client as optional.

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
- For expensive recomputations, guard with a distributed lock (key + TTL) and double-check the
  cache/store after acquiring. Always release in `finally`.

## In-memory layer
- Use a bounded LRU (max entries + ttl) for single-instance hot data; a shared cache for
  cross-instance state. Bounded only — never an unbounded map.

## Background recomputation
- Move heavy/async work to a queue with retries + backoff + bounded retention.
- Name jobs `{feature}-{action}`; always configure `attempts` and `backoff`.

## Rules
1. Cache client is optional — the app works without it.
2. Wrap every cache op in try/catch; degrade on failure.
3. Always use the key generator; never inline key strings.
4. Invalidate via events across modules.
5. TTL on everything; LRU bounded; queues always retry.

## Example (domain overlay — illustrative only)
A project maps prefixes in its own config, e.g. `WEATHER`, `PROFILE`, `ENTITLEMENT`, with
project-chosen TTLs (entitlements short so subscription changes apply fast; expensive computed
data long). Those values belong in the product repo, not in this skill.
