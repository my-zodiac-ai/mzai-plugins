---
name: nuxt-server-routes
description: >
  Nuxt/Nitro server layer — server/api vs server/routes vs server/middleware, defineEventHandler,
  reading body/query/params, validation, errors (createError), and runtimeConfig for secrets.
  Use for "add an API route in Nuxt", "server middleware", "Nitro handler", "серверный роут",
  "защитить эндпоинт", "validate request body Nuxt".
x-scope: adapter:nuxt
x-stack: nuxt
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Nuxt Server Routes (adapter)

Nitro powers the server layer. Put backend logic here — not in components.

## Where things go
| Path | Purpose |
|------|---------|
| `server/api/<name>.<method>.ts` | JSON API endpoint → `/api/<name>` (method from filename: `.get.ts`, `.post.ts`) |
| `server/routes/<path>.ts` | Non-`/api` routes (webhooks, sitemaps, RSS) |
| `server/middleware/<name>.ts` | Runs on every request (auth, logging) — no return value |
| `server/utils/*.ts` | Auto-imported server-only helpers |

## Rules
1. **`defineEventHandler(async (event) => ...)`** for every handler.
2. **Read input** with helpers: `getQuery(event)`, `getRouterParam(event, 'id')`, `await readBody(event)`, `getHeader(event, 'authorization')`.
3. **Validate input** at the boundary (zod/valibot); on failure `throw createError({ statusCode: 400, statusMessage, data })`.
4. **Secrets** come from `useRuntimeConfig(event)` (server keys are private; only `runtimeConfig.public` reaches the client). Never hardcode (see core standard — no infra literals).
5. **Auth** as `server/middleware` or a `requireUser(event)` util; return 401 via `createError`.
6. **Errors**: throw `createError`; don't leak stack traces; set proper status codes.
7. **Webhooks** go in `server/routes/` (raw body via `readRawBody(event)` for signature verification).

## Example
```ts
// server/api/orders.post.ts
import { z } from 'zod'
const Body = z.object({ items: z.array(z.string()).min(1), currency: z.string().length(3) })

export default defineEventHandler(async (event) => {
  const user = await requireUser(event)                       // server/utils/requireUser.ts
  const parsed = Body.safeParse(await readBody(event))
  if (!parsed.success) throw createError({ statusCode: 400, statusMessage: 'Invalid body', data: parsed.error.flatten() })
  const cfg = useRuntimeConfig(event)
  return createOrder({ userId: user.id, ...parsed.data }, cfg)
})
```
