---
name: prisma-migrations
description: >
  Prisma migrations — dev vs deploy workflow, safe zero-downtime (expand/contract) changes,
  destructive-change detection, and rollback/forward-fix strategy. Use for "Prisma migration",
  "migrate dev", "migrate deploy", "rename a column safely", "zero downtime migration",
  "миграция Prisma", "безопасная миграция", "откатить миграцию".
x-scope: adapter:prisma
x-stack: prisma
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Prisma Migrations (adapter)

## Workflow
| Context | Command |
|---------|---------|
| Local: edit schema → create + apply migration | `prisma migrate dev --name <descriptive>` |
| CI/prod: apply pending migrations | `prisma migrate deploy` |
| Inspect drift / pending | `prisma migrate status` |
| Generate client after schema change | `prisma generate` |

Always `prisma generate` after a schema change (the hooks-pack Prisma reminder nudges this).

## Zero-downtime: expand → migrate → contract
Never do a breaking rename/drop in one deploy while old code runs. Three phases across releases:
1. **Expand** — add the new column/table (nullable/with default); deploy. Old + new code both work.
2. **Backfill + dual-write** — backfill data; new code writes both old and new; deploy.
3. **Contract** — once nothing reads the old column, drop it; deploy.

A "rename" = add new + backfill + switch reads + drop old (4 steps), not `RENAME` in one shot.

## Rules
1. **`migrate dev` is local-only** — it can reset the dev DB. **Never** run it against prod; prod uses `migrate deploy`.
2. **Review generated SQL** in `migrations/<ts>/migration.sql` before merging — watch for `DROP`, `NOT NULL` on existing tables, type narrowing (destructive).
3. **Adding a NOT NULL column** to a populated table needs a default or a backfill in the same migration, else it fails.
4. **No down-migrations in Prisma** — recover by a new forward-fix migration; keep changes small and reversible-by-design.
5. **One logical change per migration**, descriptive name; commit the migration with the code that needs it.
6. **Long index builds** on big tables: use a concurrent/online strategy where the DB supports it to avoid locking.

## Example
```bash
# 1. expand
#    schema.prisma: add `phone String?`
prisma migrate dev --name add_user_phone_nullable
# 2. backfill (script or SQL), then deploy code that dual-writes
# 3. contract later: make NOT NULL / drop legacy column in a separate migration
prisma migrate deploy        # in CI/prod
prisma migrate status        # verify no drift
```
For DB-agnostic migration planning, this mirrors the expand/contract method used by the
SpecKit Product Forge `migration-plan` step (external).
