# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

**Language/Version**: TypeScript 5.9
**Primary Dependencies**:
  - Backend: NestJS 11, Mongoose/MongoDB, BullMQ, Redis, class-validator, class-transformer
  - Frontend: Vue 3 (Composition API + `<script setup>`), Quasar 2, Pinia, VueUse, vue-i18n
  - AI: Anthropic Claude SDK, OpenAI SDK, Google GenAI SDK (via ai-manager orchestration)
  - Astrology: Swiss Ephemeris (swisseph), Lunar-typescript
  - Mobile: Capacitor (iOS/Android)
**Storage**: MongoDB (Mongoose ODM) + Redis (Keyv + BullMQ)
**Testing**: Vitest (unit/integration), Playwright (E2E), mongodb-memory-server, MSW
**Target Platform**: Web (SPA) + iOS + Android (via Capacitor)
**Project Type**: Monorepo (back/ + front/)
**Performance Goals**: <200ms p95 API response, LCP <2.5s, FID <100ms, CLS <0.1
**Constraints**: Bundle <1MB gzipped, 10 languages i18n, WCAG 2.1 AA, dark mode required
**Scale/Scope**: [Adjust per feature]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

[Gates determined based on constitution file — check EDA/DDD compliance for backend, FSD compliance for frontend, no forwardRef, events after DB commit, no cross-feature imports]

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (My Zodiac AI Monorepo)

```text
back/
├── src/
│   ├── modules/{domain}/           # Bounded context modules (EDA/DDD)
│   │   ├── {domain}.module.ts
│   │   ├── {domain}.service.ts
│   │   ├── {domain}.controller.ts
│   │   ├── schemas/                # Mongoose schemas
│   │   ├── dto/                    # Request/Response DTOs
│   │   ├── events/                 # Domain events
│   │   ├── listeners/              # Event listeners (cross-module side effects)
│   │   ├── adapters/               # Interface abstractions (no circular deps)
│   │   ├── jobs/                   # BullMQ job processors
│   │   └── interfaces/             # TypeScript interfaces & tokens
│   ├── common/                     # Shared guards, pipes, decorators
│   └── infrastructure/             # Redis, cache, database config
└── test/                           # E2E and integration tests

front/
├── src/
│   ├── app/                        # App layer (router, global providers)
│   ├── pages/                      # Page components (orchestrators only)
│   ├── widgets/                    # Composite UI blocks
│   ├── features/{feature-name}/    # FSD feature slices
│   │   ├── model/                  # Composables, business logic
│   │   ├── ui/                     # Feature-specific components
│   │   ├── api/                    # API calls
│   │   └── index.ts                # Public API (barrel export)
│   ├── entities/{entity-name}/     # Domain entities
│   │   ├── model/
│   │   ├── ui/
│   │   ├── api/
│   │   └── index.ts
│   └── shared/
│       ├── ui/                     # Shared Quasar-based components
│       ├── lib/                    # Shared utilities
│       ├── api/                    # API client, interceptors
│       └── config/                 # App config, constants
└── test/                           # Component & E2E tests
```

**Structure Decision**: My Zodiac AI uses a monorepo with `back/` (NestJS) and `front/` (Vue 3 + Quasar) workspaces managed by pnpm.


## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., forwardRef usage] | [current need] | [why adapter pattern insufficient] |
| [e.g., direct feature import] | [specific problem] | [why event-based communication insufficient] |

## Architecture Decisions

### Backend Patterns (EDA/DDD)

- **Bounded Context**: Which module(s) own this feature?
- **Domain Events**: What events does this feature emit/listen to?
- **Adapters**: Are cross-module dependencies needed? Define interface tokens.
- **BullMQ Jobs**: Is deferred/heavy processing needed?
- **Caching Strategy**: What cache keys, TTLs, and invalidation events?

### Frontend Patterns (FSD)

- **FSD Layer**: Where does this feature live? (feature/ entity/ widget/ page/)
- **State Management**: Pinia store design, composable API
- **i18n**: New translation keys needed (all 10 languages)
- **Responsive**: Mobile-first breakpoints (360px, 768px, 1440px)
- **Dark Mode**: Ensure `body.body--dark` support
- **Accessibility**: ARIA attributes, focus management, keyboard navigation
