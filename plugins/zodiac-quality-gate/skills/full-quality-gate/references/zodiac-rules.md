# My Zodiac AI — Project-Specific Rules

> Reference file loaded by quality gate auditors when running inside the My Zodiac AI project.
> Read this file to understand project-specific patterns and conventions.

## Stack

- **Backend**: NestJS 11 + MongoDB (Mongoose) + Redis + BullMQ + EventEmitter2, TypeScript 5.9
- **Frontend**: Vue 3 + Quasar 2.18 + Pinia 3 + Vue Router 4, TypeScript 5.9, Capacitor 8
- **AI**: Anthropic Claude + OpenAI + Google GenAI, orchestrated via `ai-manager`
- **Astrology**: Swiss Ephemeris (western zodiac) + Lunar-typescript
- **Testing**: Vitest (unit/integration) + Playwright (E2E) + MSW (API mocking) + Supertest

## Architectural Mandates

### Backend (EDA + DDD)

1. **EDA is mandatory** for all cross-module side effects
2. **Events emitted only AFTER** successful `await repo.save(entity)`
3. **Never throw** from `@OnEvent` async listeners — always try/catch + log
4. **No `forwardRef()`** — fully eliminated (ADR-002), CI blocks new usage
5. **Symbol-token DI** for cross-boundary dependencies
6. **Adapters** for breaking circular dependencies (AuthSharedModule, SharedSchemasModule, etc.)
7. **Domain events** named `{Entity}{PastTense}Event` with `correlationId`

### Frontend (FSD)

1. **Feature-Sliced Design mandatory** for all new code
2. **Layer hierarchy**: `app → pages → widgets → features → entities → shared` (no upward imports)
3. **Public API only** — import through `index.ts`, never deep paths
4. **No cross-feature imports** — features communicate via shared entities or events
5. **No new code in `legacy/`** directory
6. **Path aliases** required: `@features`, `@shared`, `@entities`, etc.

### Bounded Contexts (Backend)

```
core (auth, users, onboarding, restrictions)
astrology (western, lunar, horoscopes, relationships, cosmic-weather, cosmic-self, cosmic-story)
ai (ai-manager, prompts, chat, streaming)
business (payments, analytics, reports, admin, gdpr, bookmarks, sagas)
notifications-v2 (delivery, content, engine, queues, scheduling)
infrastructure (redis, queue, database, monitoring, email, events, cache)
```

### Dependency Rules

- `infrastructure ← (all modules)` — infrastructure never depends on business
- `astrology` → `ai` is FORBIDDEN (one-directional: ai → astrology is OK)
- No circular dependencies between bounded contexts
- Cross-module communication via events or adapter interfaces

## Testing Rules

- **Vitest only** (Jest is forbidden — ADR-005)
- **AAA structure**: Arrange → Act → Assert
- **Shared mocks** from `@test/mocks` and `@test/helpers`
- **TDD preferred**: write failing test before implementation
- **Isolation**: each test is independent, no order dependency

## Commands

```bash
# Quality checks
pnpm --dir back lint
pnpm --dir back validate:architecture
pnpm --dir back check:circular-deps
pnpm --dir back check:eda-compliance
pnpm --dir front lint
pnpm --dir front type-check
pnpm --dir front security:check

# Tests
pnpm --dir back test
pnpm --dir back test:integration
pnpm --dir front test
pnpm --dir front test:e2e
```

## Anti-Patterns (Always Flag)

### Backend
- Event emitted inside transaction (race condition)
- `throw` in `@OnEvent` handler (breaks event loop)
- `forwardRef()` (masked circular dependency)
- Direct cross-module service injection (boundary violation)
- God service >500 lines (SRP violation)
- Anemic domain model (logic in services, not entities)
- Hardcoded user-facing strings (use nestjs-i18n)

### Frontend
- Direct cross-feature import (FSD violation)
- Business logic in Vue component (untestable)
- New code in `legacy/` (architecture violation)
- Global state without Pinia (unmanageable)
- Direct API calls from component (no error handling/caching layer)
