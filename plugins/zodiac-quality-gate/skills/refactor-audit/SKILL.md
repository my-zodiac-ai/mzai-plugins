---
name: refactor-audit
description: >
  Identify refactoring opportunities — simplification, dead code removal, consolidation,
  pattern extraction, and structural improvements. Use when the user asks to "suggest refactoring",
  "simplify code", "find dead code", "clean up", "упрости код", "найди мёртвый код",
  "что можно отрефакторить", "consolidate", "remove unused", or wants to improve code structure
  without changing behavior. Trigger proactively after feature completion or during maintenance sprints.
---

# Refactor Audit

Identify concrete, safe refactoring opportunities that improve maintainability without changing behavior.

## Audit Dimensions

### 1. Dead Code Detection

Search for:
- **Unused exports**: functions, classes, types, constants exported but never imported elsewhere
- **Unreachable code**: code after `return`, `throw`, or in impossible branches
- **Commented-out blocks**: code that's been commented out (not documentation comments)
- **Dead feature flags**: flags that are always true/false in all environments
- **Unused dependencies**: packages in `package.json` not imported anywhere
- **Empty files**: files with only exports/imports but no logic
- **Legacy remnants**: code in `legacy/` that has been fully migrated

**Technique**: Cross-reference exports with imports project-wide using `Grep`.

### 2. Simplification Opportunities

| Pattern | Simplification |
|---|---|
| Nested if/else chains (>3 levels) | Early returns / guard clauses |
| Switch with fallthrough | Strategy pattern or Map lookup |
| Repeated null checks | Optional chaining or null coalescing |
| Complex boolean expressions | Extract to named function |
| Promise chains (.then) | async/await |
| Manual array operations | Array methods (map, filter, reduce) |
| try/catch wrapping every function | Centralized error handling |

### 3. Consolidation

Find groups of similar code that should be unified:
- **Similar services** doing the same thing differently
- **Similar components** with slight variations → extract shared component with props
- **Similar API calls** → extract shared API client method
- **Similar validation rules** → extract shared DTO or validation composable
- **Similar event handlers** → extract shared handler pattern

### 4. Pattern Extraction

Identify emerging patterns that should be formalized:
- Code that manually implements what a shared utility would solve
- Repeated `try/catch + log` patterns → extract error handling utility
- Repeated cache key construction → extract cache key builder
- Repeated auth/guard patterns → extract shared guard

### 5. Structural Improvements

- **Large files** (>400 lines): propose splitting strategy
- **Deep nesting**: refactor to reduce cognitive complexity
- **Long parameter lists** (>5 params): introduce options object or builder
- **Primitive obsession**: identify values that should be Value Objects
- **Feature envy**: methods that use more data from other classes than their own

### 6. Test Refactoring

- Repeated test setup → extract test factories/fixtures
- Flaky tests → identify root cause (timing, order dependency, shared state)
- Missing test utilities → propose shared mock/helper patterns
- Tests testing implementation details → suggest behavior-focused alternatives

## Safety Rules

Every refactoring suggestion must:
1. **Not change behavior** — pure structural improvement
2. **Have clear before/after** — show what changes
3. **Be independently mergeable** — each refactoring is a standalone PR
4. **Include risk assessment** — what could go wrong
5. **Reference tests** — either existing tests that verify safety, or tests to add first

## Output Format

```markdown
# Refactor Audit Report

## Summary
- **Dead code**: ~N lines removable
- **Simplifications**: N opportunities
- **Consolidations**: N groups
- **Estimated cleanup effort**: N hours

## Quick Wins (< 30 min each)
### [REF-001] Remove dead `LegacyNotificationService`
- **Files**: `back/src/modules/infrastructure/notifications-legacy/legacy-notification.service.ts`
- **Evidence**: No imports found project-wide; fully replaced by notifications-v2
- **Risk**: Low — run tests after removal
- **LOC removed**: ~150

## Medium Refactorings (1-4 hours)
### [REF-005] Extract shared cache key builder
- **Files affected**: 8 services that construct cache keys manually
- **Pattern**: `${prefix}:${userId}:${date}` repeated with slight variations
- **Proposal**: `shared/lib/cache-key.builder.ts` with typed builder
- **Risk**: Low — add unit tests for builder, then replace usage

## Large Refactorings (1+ days)
...

## Refactoring Roadmap
| Priority | Item | Effort | Impact |
|---|---|---|---|
| 1 | Remove dead code | 2h | Reduces cognitive load |
| 2 | Quick wins | 4h | Improves readability |
| 3 | Consolidations | 1d | Reduces maintenance surface |
```
