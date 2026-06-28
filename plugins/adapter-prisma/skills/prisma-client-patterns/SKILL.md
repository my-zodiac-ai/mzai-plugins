---
name: prisma-client-patterns
description: >
  Prisma Client query patterns — avoid N+1 (include/select), transactions ($transaction),
  pagination (cursor vs offset), select-only projections, and singleton client / connection
  management. Use for "Prisma query", "N+1 in Prisma", "Prisma transaction", "pagination Prisma",
  "запрос Prisma", "N+1 запросы", "транзакция Prisma".
x-scope: adapter:prisma
x-stack: prisma
---

# Prisma Client Patterns (adapter)

Implements the performance rules from Engineering Canon §6 (avoid N+1, paginate, index hot paths)
on Prisma.

## Rules
1. **Avoid N+1** — load relations in one query with `include`/`select`, not a loop of awaits.
2. **`select` only what you need** — narrows columns and payload; don't `findMany()` whole rows for a list.
3. **Transactions** — multi-write invariants go in `prisma.$transaction([...])` (batch) or the
   interactive `$transaction(async (tx) => ...)` for read-then-write. Keep them short.
4. **Pagination** — cursor-based for large/infinite lists (`cursor`, `take`, `skip: 1`); offset
   (`skip`/`take`) only for small bounded sets — offset degrades on large tables.
5. **Singleton client** — instantiate `PrismaClient` once per process (in serverless/Nuxt dev, guard
   with a global to avoid exhausting connections on HMR).
6. **No raw user input in `$queryRawUnsafe`** — use parameterized `$queryRaw` tagged templates (OWASP, Canon §5).
7. **Connection pool** — size it for the runtime (serverless: small pool or a proxy/pgbouncer).

## Examples
```ts
// Singleton (prevents connection exhaustion on dev HMR / serverless)
export const prisma = globalThis.__prisma ?? new PrismaClient()
if (process.env.NODE_ENV !== 'production') globalThis.__prisma = prisma

// No N+1: one query with a projected relation
const users = await prisma.user.findMany({
  select: { id: true, email: true, orders: { select: { id: true, total: true } } },
})

// Transaction: read-then-write invariant
await prisma.$transaction(async (tx) => {
  const acct = await tx.account.findUniqueOrThrow({ where: { id } })
  if (acct.balance < amount) throw new Error('insufficient funds')
  await tx.account.update({ where: { id }, data: { balance: { decrement: amount } } })
})

// Cursor pagination
const page = await prisma.order.findMany({ take: 20, ...(cursor && { cursor: { id: cursor }, skip: 1 }), orderBy: { id: 'asc' } })
```
