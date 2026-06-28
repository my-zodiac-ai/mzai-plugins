---
name: nuxt-data-fetching
description: >
  Nuxt 3/4 data fetching — choose correctly between useFetch, useAsyncData, and $fetch;
  avoid double-fetching (hydration), handle SSR payload transfer, errors, and caching keys.
  Use when fetching data in a Nuxt app, "useFetch vs $fetch", "data fetching in Nuxt",
  "почему запрос дважды", "fetch on server", "useAsyncData", "Nuxt API call".
x-scope: adapter:nuxt
x-stack: nuxt
---

# Nuxt Data Fetching (adapter)

Pick the right primitive — this is the #1 source of Nuxt bugs (double fetches, hydration
mismatches, leaked secrets).

## Decision table
| Need | Use | Notes |
|------|-----|-------|
| Fetch for rendering a component/page (SSR + client) | `useFetch(url, opts)` | Auto SSR→client payload transfer; dedup by key |
| Fetch + custom/derived async logic | `useAsyncData(key, fn)` | Wrap any async fn; you control the key |
| Imperative call (event handler, after mount, server route) | `$fetch(url)` | No SSR transfer; runs where called |
| Server-only secret/3rd-party call | `$fetch` inside `server/api/*` | Keep keys server-side; never in client `useFetch` to a 3rd party |

## Rules
1. **Don't wrap `$fetch` in `useAsyncData` without a stable key** — causes double fetch (server + client).
2. **Stable explicit keys** for `useAsyncData`/`useFetch` so SSR payload is reused on hydration.
3. **`server: true` (default)** fetches during SSR; use `{ server: false }` for client-only (e.g. user-specific after auth) and `{ lazy: true }` to not block navigation.
4. **Pick fields** with `transform`/`pick` to shrink the SSR payload (it's serialized into HTML).
5. **Errors**: surface `error` from `useFetch`; for fatal, `throw createError({ statusCode, statusMessage })`.
6. **Secrets/3rd-party APIs**: call them from `server/api/*` via `$fetch`, expose only your own route to the client.
7. **Auth headers on SSR**: forward cookies with `useRequestHeaders(['cookie'])`.

## Example
```ts
// Page: SSR-rendered list, stable key, slim payload
const { data, error, refresh } = await useFetch('/api/orders', {
  key: 'orders-list',
  query: { page },                      // reactive — refetches on change
  transform: (rows) => rows.map(({ id, total }) => ({ id, total })),
})

// server/api/orders.get.ts — secret stays server-side
export default defineEventHandler(async (event) => {
  const me = await requireUser(event)
  return $fetch('https://billing.internal/orders', {
    headers: { authorization: `Bearer ${useRuntimeConfig().billingKey}` },
    query: { userId: me.id },
  })
})
```
