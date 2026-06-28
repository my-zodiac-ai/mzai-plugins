---
name: codebase-analysis
description: >
  Analyze the My Zodiac AI codebase to find integration points for a new feature.
  Use when the user asks "где в коде", "codebase analysis", "точка интеграции",
  "куда добавить", "how to integrate", "what exists already",
  or needs to understand how a feature fits into the existing architecture.
x-scope: domain:astrology
x-stack: any
---

# Codebase Integration Analysis

> **Domain plugin (astrology research).** If your environment provides a general `codebase-analysis` skill, use it for the generic method; this skill adds the astrology-app specifics (domain competitors, domain UX, monetization angles).

Analyze the My Zodiac AI codebase to determine exactly where and how a new feature
should be integrated.

## Project Structure Context

My Zodiac AI is a monorepo:
- `back/` — NestJS 11 backend (EDA + DDD, MongoDB, Redis, BullMQ)
- `front/` — Vue 3 + Quasar frontend (FSD architecture, Capacitor mobile)
- AI orchestration via `ai-manager` module

Read project docs first:
- `docs/AI_CONTEXT.md` — stack overview and structure
- `docs/AI_ARCHITECTURE.md` — ADR and module boundaries
- `docs/AI_PATTERNS.md` — EDA, DDD, FSD patterns

## Process

### 1. Scan Existing Architecture

**Backend analysis:**
- Read `back/src/modules/` directory structure — list all modules
- Identify which module(s) are most related to the new feature
- Check existing services, controllers, DTOs, events in related modules
- Look at `back/src/shared/` for reusable infrastructure
- Check database schemas in related modules (MongoDB schemas/models)
- Review existing event patterns (what events are emitted, what handlers exist)

**Frontend analysis:**
- Read `front/src/` directory structure — understand FSD layers
- Identify existing pages, features, entities related to the feature
- Check router configuration for navigation patterns
- Look at existing stores (Pinia) for state management patterns
- Check shared components and design tokens

**AI analysis (if relevant):**
- Check `ai-manager` module for existing AI provider integrations
- Look at prompt templates and AI orchestration patterns
- Check which AI models are used for what purposes

### 2. Identify Integration Points

Produce a detailed map:

**New Backend Module (if needed):**
- Module name following existing conventions
- Required services and their responsibilities
- Database schemas (MongoDB collections)
- Events to emit (following EDA pattern)
- Events to listen to from other modules
- API endpoints (REST controllers)
- DTOs for validation
- Required adapters (if crossing module boundaries)

**Frontend Integration:**
- FSD layer placement (pages/features/entities/shared)
- New routes and navigation entries
- Pinia store structure
- API client methods
- Components to create
- Existing components to modify (if any)

**Cross-cutting Concerns:**
- Authentication/authorization requirements
- Caching strategy (Redis)
- Background jobs (BullMQ)
- AI integration needs
- Mobile-specific considerations (Capacitor plugins)

### 3. Dependency Analysis

- What existing modules does this feature depend on?
- What existing modules might need to know about this feature (via events)?
- Are there circular dependency risks?
- Do any shared types/enums need updating?

### 4. Effort Estimation

Provide T-shirt sizing:
| Component | Effort | Notes |
|-----------|--------|-------|
| Backend module | S/M/L/XL | What's involved |
| Database schemas | S/M/L/XL | Complexity |
| Frontend pages | S/M/L/XL | Number and complexity |
| AI integration | S/M/L/XL | If applicable |
| Tests | S/M/L/XL | Unit + integration + e2e |
| **Total** | **S/M/L/XL** | |

## Rules

- READ actual files — don't assume structure from docs alone
- Follow existing patterns — if the codebase uses adapters, use adapters
- Respect module boundaries — don't propose cross-module direct imports
- EDA is mandatory for cross-module side effects
- FSD is mandatory for new frontend code
- Never propose `forwardRef()` as a solution
- Check `CLAUDE.md` for project-specific rules before recommending
