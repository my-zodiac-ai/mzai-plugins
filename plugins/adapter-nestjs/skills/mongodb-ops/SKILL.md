---
name: mongodb-ops
description: |
  MongoDB database operations beyond migrations for My Zodiac AI — seed data generation, schema/index analysis, aggregation pipeline building from natural language, and backup/restore workflows. Uses the connected MongoDB MCP server directly. Trigger this skill whenever the user mentions: seeding data, test fixtures, dev data, "заполни базу", "сгенерируй данные", analyzing collections, checking indexes, "проверь индексы", "анализ схемы", building aggregations, "напиши агрегацию", "aggregation pipeline", backup, restore, "бэкап", "дамп базы", export/import collections, data cleanup, "почисти коллекцию", or any database operation that isn't a schema migration. Also trigger when the user asks about collection sizes, data distribution, slow queries, or database health — even if they don't say "mongodb" explicitly.
x-scope: adapter:nestjs
x-stack: nestjs
---

# MongoDB Ops — Database Operations for My Zodiac AI

This skill handles all MongoDB operations beyond schema migrations (which are covered by `run-migration`). It leverages the MongoDB MCP server that's already connected to the project.

## Before You Start

Every operation begins with **discovery** — you don't assume which database or collections exist. Start by orienting yourself:

```
Step 1: mcp__mongodb-mcp-server__list-databases
Step 2: mcp__mongodb-mcp-server__list-collections  (database: "<discovered_db>")
Step 3: mcp__mongodb-mcp-server__collection-schema  (for relevant collections)
```

This matters because environments differ (dev vs staging vs prod), collection names evolve, and schemas drift. Fresh discovery prevents stale assumptions.

---

## Capabilities

### 1. Seed Data Generation

Generate realistic test/dev data that respects Mongoose schemas, relationships, and business rules.

**When the user asks:** "seed the database", "create test data", "заполни базу тестовыми данными", "need fixtures for development"

**Workflow:**

1. **Discover** the target database and collections (steps above)
2. **Inspect schemas** — for each target collection, call `collection-schema` to understand field types, required fields, and enums
3. **Check existing data** — use `count` to see if the collection already has data. Ask the user before overwriting
4. **Generate domain-appropriate data** — this is an astrology app, so seed data should feel real:
   - Users: realistic names, valid birth dates (1950–2005), proper zodiac signs matching the birth date, varied locales (uk/en/ru)
   - Horoscopes: period-appropriate content (daily/weekly/monthly), valid zodiac pairings
   - Subscriptions: mix of free/premium/trial tiers with realistic dates
   - Relationships: pairs of users with valid synastry data
5. **Insert via MCP** — use `insert-many` with batches of 50-100 documents

**Example — seeding users:**

```
mcp__mongodb-mcp-server__collection-schema
  database: "my_zodiac_ai"
  collection: "users"

mcp__mongodb-mcp-server__count
  database: "my_zodiac_ai"
  collection: "users"

mcp__mongodb-mcp-server__insert-many
  database: "my_zodiac_ai"
  collection: "users"
  documents: [
    {
      "email": "test.aries@example.com",
      "name": "Олена Коваль",
      "birthDate": "1995-03-25T00:00:00Z",
      "zodiacSign": "aries",
      "locale": "uk",
      "isVerified": true,
      "isDeleted": false,
      "createdAt": "2024-01-15T10:00:00Z",
      "updatedAt": "2024-01-15T10:00:00Z"
    },
    ...
  ]
```

**Key rules for seed data:**
- Always include `createdAt`/`updatedAt` timestamps (Mongoose `timestamps: true` convention)
- Use ObjectId strings where references are needed — generate valid 24-hex-char strings
- Respect unique indexes (check with `collection-indexes` first) — don't create duplicate emails
- Include a mix of edge cases: users without email (OAuth-only), expired trials, soft-deleted records
- For date fields that represent astronomical events, use astronomically valid values

**Cleanup pattern** — always offer a way to remove seeded data:
```
mcp__mongodb-mcp-server__delete-many
  database: "my_zodiac_ai"
  collection: "users"
  filter: { "email": { "$regex": "@example\\.com$" } }
```

### 2. Schema & Index Analysis

Audit collection schemas, find missing indexes, detect anomalies, and report on data health.

**When the user asks:** "check indexes", "analyze the schema", "проверь индексы", "are there missing indexes?", "database health", "why is this query slow?"

**Workflow:**

1. **Discover** all collections in the target database
2. **For each collection** (or the ones the user specified):

   a. **Schema analysis:**
   ```
   mcp__mongodb-mcp-server__collection-schema
     database: "my_zodiac_ai"
     collection: "users"
     sampleSize: 100   # increase for better accuracy
   ```

   b. **Index audit:**
   ```
   mcp__mongodb-mcp-server__collection-indexes
     database: "my_zodiac_ai"
     collection: "users"
   ```

   c. **Size check:**
   ```
   mcp__mongodb-mcp-server__collection-storage-size
     database: "my_zodiac_ai"
     collection: "users"
   ```

   d. **Document count:**
   ```
   mcp__mongodb-mcp-server__count
     database: "my_zodiac_ai"
     collection: "users"
   ```

3. **Cross-reference with Mongoose schemas** — read the `.schema.ts` files from the codebase to compare what Mongoose expects vs what MongoDB actually has. Look for:
   - Fields in the DB that aren't in the schema (orphaned data from old migrations)
   - Fields in the schema with `index: true` or `unique: true` that don't have corresponding DB indexes
   - Collections referenced in `MongooseModule.forFeature()` that are empty or missing

4. **Query performance check** — if the user reports slow queries, use `explain`:
   ```
   mcp__mongodb-mcp-server__explain
     database: "my_zodiac_ai"
     collection: "users"
     method: [{ "find": { "email": "test@example.com" } }]
     verbosity: "executionStats"
   ```
   Look for `COLLSCAN` (no index used) and high `totalDocsExamined` vs `nReturned` ratios.

5. **Report findings** in a structured format:
   - Collection name, doc count, storage size
   - Index coverage: which query patterns are covered, which aren't
   - Schema drift: mismatches between code and DB
   - Recommendations: indexes to add, orphaned fields to clean up

### 3. Aggregation Pipeline Builder

Build MongoDB aggregation pipelines from natural-language descriptions.

**When the user asks:** "write an aggregation", "напиши агрегацию", "how many users signed up per day?", "aggregate payments by tier", any analytical question about the data

**Workflow:**

1. **Understand the question** — what data does the user want? What grouping, filtering, sorting?
2. **Discover the schema** — `collection-schema` on the relevant collection(s) to know what fields exist and their types
3. **Build the pipeline** step by step — explain each stage:

   ```
   mcp__mongodb-mcp-server__aggregate
     database: "my_zodiac_ai"
     collection: "users"
     pipeline: [
       { "$match": { "isDeleted": false, "createdAt": { "$gte": "2024-01-01T00:00:00Z" } } },
       { "$group": {
           "_id": { "$dateToString": { "format": "%Y-%m-%d", "date": "$createdAt" } },
           "count": { "$sum": 1 }
         }
       },
       { "$sort": { "_id": 1 } }
     ]
   ```

4. **Run and validate** — execute the pipeline and check the results make sense
5. **Optimize if needed** — use `explain` to check performance:
   ```
   mcp__mongodb-mcp-server__explain
     database: "my_zodiac_ai"
     collection: "users"
     method: [{ "aggregate": [<pipeline>] }]
     verbosity: "executionStats"
   ```

**Common pipeline patterns for this project:**
- **User signups over time:** `$match` (isDeleted:false) → `$group` by date → `$sort`
- **Revenue by tier:** join `subscriptions` + `transactions` via `$lookup`, then `$group`
- **AI usage stats:** aggregate `ai-metrics` by model, date, cost
- **Notification delivery rates:** `$group` on status field in notifications collection
- **Horoscope generation frequency:** aggregate `horoscope-caches` by zodiacSign + period

**Tips for good pipelines:**
- Put `$match` stages as early as possible — they reduce the working set
- Use `$project` to drop unneeded fields before heavy stages like `$lookup`
- For date grouping, `$dateToString` is cleaner than manual year/month extraction
- When joining collections, always specify `let` + `pipeline` form of `$lookup` for efficiency

### 4. Backup & Restore

Export and import collection data for staging environments, pre-migration snapshots, or data transfer.

**When the user asks:** "backup the database", "export this collection", "бэкап", "дамп", "restore from backup", "copy data to staging"

**Two modes available:**

#### Mode A: MCP Export (default — works everywhere)

```
mcp__mongodb-mcp-server__export
  database: "my_zodiac_ai"
  collection: "users"
  exportTitle: "users-backup-2024-03-30"
  exportTarget: [{ "find": {} }]
  jsonExportFormat: "relaxed"
```

For selective export (e.g., only premium users):
```
mcp__mongodb-mcp-server__export
  database: "my_zodiac_ai"
  collection: "users"
  exportTitle: "premium-users-backup"
  exportTarget: [{ "find": { "currentTier": "premium" } }]
```

For aggregation-based export:
```
mcp__mongodb-mcp-server__export
  database: "my_zodiac_ai"
  collection: "users"
  exportTitle: "user-stats-export"
  exportTarget: [{ "aggregate": [{ "$group": { "_id": "$zodiacSign", "count": { "$sum": 1 } } }] }]
```

#### Mode B: mongodump/mongorestore (when CLI tools available)

Check availability first:
```bash
which mongodump && echo "available" || echo "not available"
```

If available:
```bash
# Full database backup
mongodump --uri="$MONGODB_URI" --db=my_zodiac_ai --out=./backup/$(date +%Y-%m-%d)

# Single collection
mongodump --uri="$MONGODB_URI" --db=my_zodiac_ai --collection=users --out=./backup/users-$(date +%Y-%m-%d)

# Restore
mongorestore --uri="$MONGODB_URI" --db=my_zodiac_ai --drop ./backup/2024-03-30/my_zodiac_ai/
```

**Safety rules for backup/restore:**
- **Always ask before `--drop`** — this deletes existing data before restoring
- Before restore, show the user what collections will be affected and their current doc counts
- For staging copies, suggest renaming the target database to avoid overwriting production
- Log the backup location and timestamp so the user can find it later

### 5. Data Cleanup & Maintenance

Manage orphaned data, expired caches, and collection hygiene.

**When the user asks:** "clean up old data", "почисти кэши", "remove expired sessions", "data maintenance"

**Common cleanup operations:**

```
# Count expired cache entries before deleting
mcp__mongodb-mcp-server__count
  database: "my_zodiac_ai"
  collection: "horoscope-caches"
  query: { "expiresAt": { "$lt": "2024-01-01T00:00:00Z" } }

# Delete with confirmation
mcp__mongodb-mcp-server__delete-many
  database: "my_zodiac_ai"
  collection: "horoscope-caches"
  filter: { "expiresAt": { "$lt": "2024-01-01T00:00:00Z" } }
```

**Safety protocol for destructive operations:**
1. Always `count` first to show what will be affected
2. Ask the user to confirm before `delete-many`, `drop-collection`, or `update-many`
3. For large deletions (>1000 docs), suggest batching or creating a backup first
4. Never touch `users` or `subscriptions` collections without explicit confirmation

---

## Environment Awareness

The connection string determines which environment you're operating in. Before any write operation:

1. Check which database you're connected to
2. If it looks like production (no `-dev`, `-staging`, `-test` suffix, or the user hasn't confirmed), **warn loudly** before proceeding with writes
3. For seed data, prefer databases with `-dev` or `-test` suffixes
4. For backups, always note the source environment in the export title

---

## What This Skill Does NOT Cover

- **Schema migrations** — use the `run-migration` skill instead
- **Mongoose schema changes** (adding/removing fields in `.schema.ts` files) — that's regular code work
- **Atlas configuration** (clusters, network access, users) — out of scope
- **Redis operations** — separate infrastructure, use `redis-caching` skill
