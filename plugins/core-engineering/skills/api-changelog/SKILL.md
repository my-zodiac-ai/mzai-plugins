---
name: api-changelog
description: >
  Generate API changelogs from git diffs in your API controllers and DTOs
  (NestJS-style decorators shown by default; adapt the patterns to your framework).
  Automatically detects breaking changes, new endpoints, modified request/response
  schemas, and deprecated fields — then writes a structured changelog entry to
  docs/api-changelog/. Use this skill whenever the user asks to "generate API changelog",
  "what changed in the API", "changelog for API", "API changes since last release",
  "сгенерируй changelog API", "что изменилось в API", "breaking changes",
  "изменения в контроллерах", or after modifying controllers/DTOs and before a release.
  Also trigger when the user mentions "API diff", "endpoint changes",
  "DTO changes", "schema changes", or "migration notes for API consumers".
x-scope: core
x-stack: any
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# API Changelog Generator

Generate structured, consumer-facing changelogs for API changes by analyzing git diffs
in your API's controllers and DTOs. The changelog helps mobile clients, external integrators,
and frontend developers understand what changed, what broke, and how to migrate.

> The detection patterns in Step 3 use **NestJS + class-validator decorators** as the worked
> example. The method is framework-agnostic — map them to your framework's equivalents
> (Express routers, FastAPI path operations, Spring controllers, etc.).

## When to Use

- After modifying controllers or DTOs, before merging a PR
- Before a release to summarize all API changes since the last version
- When someone asks "what changed in the API?"
- When checking for unintentional breaking changes

## Workflow

### Step 1: Determine the Diff Range

Ask the user what to compare against if not obvious from context. Common scenarios:

| User says | Git command |
|-----------|-------------|
| "changes in this branch" | `git diff main...HEAD` |
| "changes since last release" | `git diff $(git describe --tags --abbrev=0)...HEAD` |
| "changes in last commit" | `git diff HEAD~1...HEAD` |
| "changes since v2.1.0" | `git diff v2.1.0...HEAD` |
| nothing specific | Default to `git diff main...HEAD` |

### Step 2: Extract API-Relevant Changes

Run a filtered git diff to find only controller and DTO files:

```bash
git diff <range> --name-only -- '*.controller.ts' '*.dto.ts'
```

Then get the full diff for those files:

```bash
git diff <range> -- '*.controller.ts' '*.dto.ts'
```

Also check for changes in related files that affect the API surface:

```bash
git diff <range> --name-only -- '*.enum.ts' '*.interface.ts' '*.types.ts' | head -20
```

### Step 3: Analyze Changes

For each changed file, categorize the changes into these buckets:

#### Controllers — look for:
- **New endpoints**: Added `@Get()`, `@Post()`, `@Patch()`, `@Put()`, `@Delete()` decorators
- **Removed endpoints**: Deleted route handlers
- **Changed routes**: Modified path in decorator (e.g., `@Get('users')` → `@Get('accounts')`)
- **Changed HTTP method**: e.g., `@Post()` → `@Patch()`
- **Version changes**: Modified `version` in `@Controller()` decorator
- **Guard/auth changes**: Added or removed `@Public()`, `@UseGuards()`, `@ApiBearerAuth()`
- **Rate limiting**: Changed `@Throttle()` parameters

#### DTOs — look for:
- **New required fields**: Added properties with `@IsNotEmpty()` or without `@IsOptional()`
- **Removed fields**: Deleted properties from DTO classes
- **Type changes**: Changed property types (e.g., `string` → `number`)
- **Validation changes**: Modified validators (e.g., `@MinLength(6)` → `@MinLength(8)`)
- **New optional fields**: Added properties with `@IsOptional()` or `@ApiPropertyOptional()`
- **Renamed fields**: Property name changed (detect via paired add/remove of similar fields)

#### Enums/Interfaces — look for:
- **Removed enum values**: Consumers may be sending these
- **Added enum values**: Usually non-breaking, but note for awareness
- **Interface shape changes**: New required fields, removed fields

### Step 4: Classify Breaking Changes

A change is **breaking** if it can cause existing API consumers to fail without code changes on their side. Specifically:

**Breaking (flag with warning):**
- Removed endpoint
- Changed route path or HTTP method
- Removed or renamed DTO field (request or response)
- Changed field type in a way that breaks existing payloads
- Added new **required** field to a request DTO
- Removed enum value that clients may be sending
- Added auth requirement to previously public endpoint
- Changed API version without maintaining backward compat

**Non-breaking:**
- Added new endpoint
- Added optional field to request DTO
- Added field to response DTO
- Added new enum value
- Relaxed validation (e.g., shorter MinLength)
- Added new API version while keeping old one

**Potentially breaking (flag with caution):**
- Tightened validation (e.g., longer MinLength)
- Changed response shape (added nesting, renamed response fields)
- Changed error codes or error response format

### Step 5: Generate the Changelog Entry

Use the [Keep a Changelog](https://keepachangelog.com/) format. Write the entry to
`docs/api-changelog/` with the filename pattern `YYYY-MM-DD-<short-slug>.md`.

If a `docs/api-changelog/` directory doesn't exist, create it. Also maintain a
`docs/api-changelog/README.md` index that links to all entries (create if missing).

#### Changelog Template

```markdown
# API Changelog — [short description]

**Date:** YYYY-MM-DD
**Diff range:** `<git range used>`
**Author:** [from git config or "auto-generated"]

## Breaking Changes

> These changes require updates from API consumers. See Migration Notes below.

- **[BREAKING]** `DELETE /v1/auth/sessions` — Endpoint removed.
  Replaced by `POST /v1/auth/logout`.
- **[BREAKING]** `POST /v1/users` — Field `username` is now required
  (was optional). Type: `string`, min length: 3.

## Added

- `GET /v2/orders/summary` — New endpoint for order summaries.
  Returns `OrderSummaryResponseDto`.
- `POST /v1/orders/bulk` — New bulk-create endpoint.
- Field `currency` added to `CreateOrderDto` (optional, `string`).

## Changed

- `PATCH /v1/users/profile` — Field `bio` max length increased from 200 → 500.
- `POST /v1/auth/login` — Rate limit changed from 10/min → 5/min.
- `GET /v1/orders` — Response now includes `totalCount` field.

## Deprecated

- `GET /v1/orders/legacy` — Use `GET /v2/orders` instead.
  Will be removed in v3.0.0.

## Removed

- `GET /v1/debug/health-verbose` — Internal debug endpoint removed.

## Security

- `POST /v1/payments/webhook` — Added HMAC signature verification.
- `GET /v1/users/search` — Now requires authentication (was `@Public()`).

---

## Migration Notes

### Removed: `DELETE /v1/auth/sessions`

**Before:**
```http
DELETE /v1/auth/sessions
Authorization: Bearer <token>
```

**After:**
```http
POST /v1/auth/logout
Authorization: Bearer <token>
```

### New required field: `username` in `POST /v1/users`

Add `username` (string, min 3 chars) to your registration payload:
```json
{
  "email": "user@example.com",
  "password": "...",
  "username": "jane_doe"
}
```
```

#### Writing Guidelines

- Write from the perspective of an API consumer, not the backend developer. They care
  about "what do I need to change in my code?" not "we refactored the service layer."
- Include the full HTTP method + path for every entry so it's grep-able.
- For DTO changes, mention the field name, type, and which endpoint uses it.
- Migration notes are required for every breaking change — show before/after examples.
- If there are no changes in a category, omit that section entirely.
- Keep descriptions concise — one line per change, details in migration notes.

### Step 6: Update the Index

After writing the changelog entry, update `docs/api-changelog/README.md`:

```markdown
# API Changelog Index

| Date | Description | Breaking? |
|------|-------------|-----------|
| [2025-03-15](./2025-03-15-auth-refactor.md) | Auth endpoints restructured | Yes |
| [2025-03-01](./2025-03-01-orders-v2.md) | Orders v2 endpoints | No |
```

Add the new entry at the top. If the file doesn't exist, create it with a header and the first entry.

### Step 7: Summary

After generating the changelog, present a brief summary to the user:

- Total changes found: N
- Breaking changes: N (list them briefly)
- New endpoints: N
- File written to: `docs/api-changelog/YYYY-MM-DD-slug.md`

If breaking changes were found, explicitly warn:

> **Warning:** N breaking change(s) detected. Make sure mobile clients and external
> consumers are updated before deploying. See Migration Notes in the changelog.

## Edge Cases

- **No API changes found**: If the diff contains no controller/DTO changes, tell the
  user "No API surface changes detected in this range" and skip file creation.
- **Only internal changes**: If controllers changed but only in internal logic (no
  route/param/response changes), note "Internal implementation changes only — no
  API surface impact."
- **Monorepo context**: Only look at files under your API source dir (e.g. `src/`, `apps/api/src/`, `back/src/`) — ignore frontend changes.
- **Large diffs**: If more than 30 files changed, suggest narrowing the range or
  focusing on a specific module.
