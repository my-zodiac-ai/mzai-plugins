---
name: prisma-schema-patterns
description: >
  Prisma schema modeling — relations (1-1/1-n/m-n), indexes & composite uniques, enums, JSON,
  soft-delete, timestamps, and naming via @map/@@map. Use for "design Prisma schema", "add a model",
  "Prisma relation", "index in Prisma", "схема Prisma", "связь моделей", "добавь модель".
x-scope: adapter:prisma
x-stack: prisma
---

# Prisma Schema Patterns (adapter)

## Rules
1. **Relations**: define both sides; name the FK field explicitly; pick `onDelete` (`Cascade`/`Restrict`/`SetNull`) deliberately.
2. **Index hot query paths** (`@@index`) and enforce business uniqueness (`@unique` / `@@unique`). Every field you filter/sort by in a hot path should be indexed (see Engineering Canon §6).
3. **Timestamps**: `createdAt DateTime @default(now())`, `updatedAt DateTime @updatedAt`.
4. **Enums** over free strings for fixed sets.
5. **Soft delete**: `deletedAt DateTime?` + always filter `where: { deletedAt: null }` (or a Client Extension) — don't rely on it for hard constraints.
6. **DB vs app naming**: keep `camelCase` in the schema, map to DB conventions with `@map`/`@@map` (e.g. snake_case).
7. **Money/precision**: `Decimal` (not Float) for currency; store amounts in minor units if your stack expects it.
8. **m-n**: prefer an explicit join model when the relation carries data; implicit `@relation` only for pure links.

## Example
```prisma
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  orders    Order[]
  createdAt DateTime @default(now())
  deletedAt DateTime?
  @@map("users")
}

model Order {
  id        String      @id @default(cuid())
  user      User        @relation(fields: [userId], references: [id], onDelete: Cascade)
  userId    String
  total     Decimal     @db.Decimal(12, 2)
  status    OrderStatus @default(PENDING)
  createdAt DateTime    @default(now())
  @@index([userId, status])
  @@map("orders")
}

enum OrderStatus { PENDING PAID CANCELLED }
```
