---
name: code-quality-audit
description: >
  Audit code for SOLID, DRY, YAGNI, KISS violations, clean code principles, readability, reusability,
  and deduplication. Use when the user asks to "check code quality", "review SOLID compliance",
  "find duplicated code", "проверь качество кода", "найди дублирование", "refactor suggestions",
  "clean code audit", "code smell", "SOLID check", or wants a comprehensive code quality assessment.
  Also trigger proactively after significant code changes or before PR reviews.
---

# Code Quality Audit

Deep audit of code quality across SOLID, DRY, YAGNI, KISS, clean code, readability, and reusability dimensions.

## Scope Detection

Determine what to audit based on context:

1. **Explicit target** — user names files, modules, or a PR diff
2. **Recent changes** — run `git diff --name-only HEAD~5` to find recently changed files
3. **Full module** — user names a bounded context or FSD slice

If the scope is unclear, ask. For large scopes (>20 files), break into batches and report per-batch.

## Audit Dimensions

### 1. SOLID Principles

| Principle | What to check | Severity |
|---|---|---|
| **S** — Single Responsibility | Classes/functions doing more than one thing; services >300 lines; components mixing UI + business logic | High |
| **O** — Open/Closed | Switch/if chains that grow with new types; lack of strategy/adapter patterns | Medium |
| **L** — Liskov Substitution | Subtypes that break parent contracts; overridden methods with different semantics | High |
| **I** — Interface Segregation | Fat interfaces forcing unused method implementations; God DTOs | Medium |
| **D** — Dependency Inversion | Direct imports of concrete classes instead of interfaces/tokens; tight coupling to infrastructure | High |

**Project-specific**: Check for Symbol-token DI pattern usage. Direct service injection across bounded contexts = violation.

### 2. DRY (Don't Repeat Yourself)

Search for:
- Duplicated logic blocks (>5 lines of similar code)
- Copy-pasted API calls, validation logic, error handling
- Similar components/services that could be abstracted
- Repeated patterns that should be shared utilities or composables

**Tool**: Use `Grep` to find similar patterns across files.

### 3. YAGNI (You Aren't Gonna Need It)

Flag:
- Unused exports, functions, interfaces, types
- Overly generic abstractions with only one consumer
- Configuration options nobody uses
- Dead feature flags / commented-out code blocks

### 4. KISS (Keep It Simple, Stupid)

Flag:
- Overly clever one-liners that sacrifice readability
- Nested ternaries deeper than 2 levels
- Complex generic types where simple ones suffice
- Premature abstractions (abstract class with one implementation)

### 5. Clean Code & Readability

- **Naming**: vague names (`data`, `temp`, `handler`), abbreviations, inconsistent casing
- **Function length**: >40 lines = warning, >80 lines = violation
- **Nesting depth**: >3 levels of if/for/try = violation
- **Magic numbers/strings**: hardcoded values without named constants
- **Comments**: outdated comments, comments explaining "what" instead of "why"

### 6. Deduplication & Reusability

- Identify code that appears in 2+ places and propose shared abstractions
- Check for composables/hooks that should exist but don't
- Find utility functions buried in feature code that belong in `shared/`

## Output Format

Produce a structured markdown report:

```markdown
# Code Quality Audit Report

## Summary
- **Score**: X/100
- **Critical**: N findings | **Warning**: N findings | **Info**: N findings
- **Scope**: [files/modules audited]

## Critical Findings
### [CQ-001] SRP violation in UserService
- **File**: `back/src/modules/core/users/user.service.ts:45-120`
- **Principle**: Single Responsibility
- **Issue**: UserService handles authentication, profile updates, AND notification preferences
- **Fix**: Extract NotificationPreferencesService; move auth logic to auth module
- **Effort**: Medium

## Warnings
...

## Refactoring Opportunities
### Deduplication
- `fetchWithRetry` pattern duplicated in 4 API modules → extract to `shared/lib/http`
...

## Positive Observations
- Good use of Value Objects in astrology domain
- Consistent Pinia store patterns across features
```

Rate overall score: violations weighted by severity (Critical = -10, Warning = -3, Info = -1, base = 100).

## If Project Has `docs/AI_PATTERNS.md`

Read it first — it defines the project's canonical patterns. Violations of those patterns are automatically Critical severity.
