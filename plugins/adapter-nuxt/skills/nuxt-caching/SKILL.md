---
name: nuxt-caching
description: >
  Nitro/Nuxt mapping of the caching-patterns core — routeRules (ISR/SWR/headers),
  cachedFunction/cachedEventHandler, and useStorage for shared cache. Use for "cache a Nuxt route",
  "ISR in Nuxt", "cache API response", "routeRules", "кэш в Nuxt", "stale-while-revalidate".
x-scope: adapter:nuxt
x-stack: nuxt
---

# Nuxt/Nitro Caching (adapter)

Apply the `caching-patterns` core first (cache-aside, TTL policy, invalidation, stampede). This maps
it to Nitro.

## Mechanisms
| Goal | Mechanism |
|------|-----------|
| Cache/prerender a page route | `routeRules` in `nuxt.config` — `prerender`, `isr: <seconds>`, `swr: <seconds>`, `cache: { maxAge }` |
| Cache an expensive function (cache-aside) | `cachedFunction(fn, { maxAge, name, getKey })` |
| Cache a server handler's response | `cachedEventHandler(handler, { maxAge, getKey })` |
| Shared cache store (cross-instance) | `useStorage('cache')` (back it with Redis driver in `nitro.storage`) |

## Rules (inherited from core)
1. Explicit `maxAge` (TTL) on everything — no unbounded cache.
2. Deterministic `getKey` from request-identifying parts; never cache per-user data under a shared key.
3. Cache must degrade — a cache miss/error returns fresh data, never a 500.
4. Invalidate on write: `useStorage('cache').removeItem(key)` after the mutating action.
5. Prefer `swr`/`isr` for content pages; `cachedFunction` for expensive computed data.

## Example
```ts
// nuxt.config.ts — ISR home, SWR API, no-store for user area
routeRules: {
  '/':            { isr: 3600 },
  '/api/feed':    { swr: 300 },
  '/account/**':  { cache: false, headers: { 'cache-control': 'no-store' } },
}

// server/utils/getForecast.ts — cache-aside via Nitro
export const getForecast = cachedFunction(
  async (region: string) => computeForecast(region),
  { name: 'forecast', maxAge: 60 * 60, getKey: (region) => region },
)
```
For the TTL policy and invalidation rules, see the core `caching-patterns` skill.
