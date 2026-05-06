---
name: architecture-audit
description: >
  Audit code for architecture compliance — EDA, DDD, FSD, bounded contexts, dependency rules,
  circular dependencies, adapter patterns, and ADR conformance. Use when the user asks to
  "check architecture", "architecture audit", "проверь архитектуру", "EDA compliance",
  "FSD compliance", "check bounded contexts", "dependency boundaries", "circular deps check",
  "validate architecture", or wants to verify that code follows established architectural patterns
  and decisions. Trigger proactively when reviewing cross-module changes or new module creation.
---

# Architecture Audit

Verify code adherence to architectural decisions, module boundaries, and established patterns.

## Prerequisite

Before auditing, read the project's architecture docs to understand the rules:
- `docs/AI_ARCHITECTURE.md` — ADRs, boundaries, dependency rules
- `docs/AI_PATTERNS.md` — canonical code patterns (EDA, DDD, FSD)
- `CLAUDE.md` — architectural mandates

If these files don't exist, fall back to universal best practices and note the absence.

## Audit Dimensions

### 1. EDA Compliance (Backend)

| Rule | Check | Violation |
|---|---|---|
| Events after save | Event emitted only after `await repo.save()` | Emitting inside transactions or before persist |
| No throw in listeners | All `@OnEvent` handlers wrapped in try/catch | Unhandled throws in async listeners |
| correlationId | All domain events include correlationId | Events without correlation tracking |
| Cross-module via events | Side effects across bounded contexts use events, not direct calls | Direct service injection across modules |
| Event naming | `{Entity}{PastTense}Event` convention | Inconsistent naming |

### 2. DDD Compliance (Backend)

| Rule | Check |
|---|---|
| Repository pattern | Interfaces in domain layer, implementations in infrastructure |
| Symbol-token DI | Dependencies injected via `Symbol()` tokens, not class references |
| Value Objects | Business rules encapsulated in VOs, not scattered in services |
| Bounded contexts | Each module owns its data and domain logic |
| No anemic model | Entities contain business logic, not just data containers |
| No God services | No service >500 lines; split into command handlers |

### 3. FSD Compliance (Frontend)

| Rule | Check |
|---|---|
| Layer hierarchy | `app → pages → widgets → features → entities → shared` (no upward imports) |
| Public API | All cross-slice imports go through `index.ts` |
| No cross-feature | Features don't import from other features directly |
| No legacy additions | New code never placed in `legacy/` directory |
| Path aliases | Using `@features`, `@shared`, etc. instead of relative paths |
| Slice structure | Each feature has `api/`, `model/`, `ui/`, `index.ts` |

### 4. Dependency Rules

Check the dependency graph between bounded contexts:

```
infrastructure ← (all other modules)
shared ← (all modules)
core ← astrology, ai, business, notifications-v2
astrology → business (allowed, partially)
ai → astrology (allowed, for context)
```

**Forbidden:**
- `infrastructure` depending on business modules
- `astrology` depending on `ai` (one-directional)
- Circular dependencies between bounded contexts
- `forwardRef()` usage (ADR-002: fully eliminated)

### 5. Adapter Pattern Usage

Verify that cross-module communication uses adapters:
- `AuthSharedModule` for auth ↔ users
- `SharedSchemasModule` for shared Mongoose schemas
- `SystemEventsModule` for event-based decoupling
- Symbol-token interfaces for cross-boundary DI

### 6. ADR Conformance

Check against all active ADRs (read from `docs/AI_ARCHITECTURE.md`):
- ADR-001: EDA for side effects
- ADR-002: No forwardRef (CI should block)
- ADR-003: Notifications V2 system
- ADR-004: FSD mandatory for frontend
- ADR-005: Vitest only (no Jest)
- ADR-006: Multi-provider AI with ai-manager
- ADR-007: ENABLED_ASTROLOGY_SYSTEMS env var

## Output Format

```markdown
# Architecture Audit Report

## Summary
- **Compliance Score**: X/100
- **EDA**: PASS/WARN/FAIL | **DDD**: PASS/WARN/FAIL | **FSD**: PASS/WARN/FAIL
- **Boundary Violations**: N | **ADR Violations**: N

## Boundary Violations
### [ARCH-001] Direct cross-module import
- **From**: `back/src/modules/ai/chat/chat.service.ts:12`
- **To**: `back/src/modules/business/payments/payment.service.ts`
- **Rule**: AI module should not directly depend on business module
- **Fix**: Create event `ChatSessionCompletedEvent` and handle in business module

## EDA Violations
...

## FSD Violations
...

## ADR Non-Conformance
...

## Architecture Health
- Module coupling metrics
- Dependency depth analysis
- Recommendations for decoupling
```
