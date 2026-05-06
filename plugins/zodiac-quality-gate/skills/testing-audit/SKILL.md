---
name: testing-audit
description: >
  Audit test coverage, test quality, testing patterns, and testing strategy. Use when the user
  asks to "check test quality", "audit tests", "test coverage review", "проверь тесты",
  "качество тестов", "testing strategy review", "find flaky tests", "missing tests",
  "тестовое покрытие", or wants to improve the project's testing practices.
  Trigger proactively after feature implementation to verify test adequacy.
---

# Testing Audit

Evaluate testing practices — coverage gaps, test quality, flaky tests, and strategy alignment.

## Prerequisite

Read `docs/AI_TESTING.md` if available — it defines the project's testing rules and patterns.

## Audit Dimensions

### 1. Coverage Analysis

Assess test coverage by area:

| Layer | Expected Coverage | Check |
|---|---|---|
| Domain services (business logic) | >80% | Critical paths must have unit tests |
| API endpoints | >70% | Happy path + error cases + auth |
| Pinia stores | >80% | State mutations + async actions + error states |
| Vue components (critical) | >60% | User interactions, conditional rendering |
| Utility functions | >90% | Pure functions should be fully tested |
| Event listeners | >70% | Event handling + error scenarios |

Identify untested critical paths:
- Payment flows without tests
- Auth flows without tests
- AI interpretation flows without tests
- Data mutation operations without tests

### 2. Test Quality

| Quality Issue | Indicator |
|---|---|
| **Tests that never fail** | Always-true assertions (`expect(true).toBe(true)`) |
| **Implementation testing** | Asserting on internal method calls rather than behavior |
| **Brittle selectors** | Component tests using CSS classes instead of `data-testid` |
| **Missing error cases** | Only happy-path tests, no error/edge case coverage |
| **Giant test files** | Test files >500 lines without organization |
| **Missing AAA** | Tests without clear Arrange/Act/Assert structure |
| **Shared mutable state** | Tests that depend on execution order |

### 3. Testing Patterns Compliance

Check against project patterns:
- **Vitest only** (no Jest — ADR-005)
- **AAA structure** in every test
- **Shared mocks** from `@test/mocks` and `@test/helpers` (no ad-hoc mocks)
- **`createTestingPinia`** for component tests with stores
- **MSW** for API mocking in frontend
- **mongodb-memory-server** for integration tests
- **Supertest** for HTTP E2E tests

### 4. Flaky Test Detection

Identify tests likely to be flaky:
- Tests with `setTimeout` or `sleep`
- Tests depending on system time without mocking
- Tests depending on external services without mocking
- Tests with race conditions (concurrent async operations)
- Tests with order dependencies

### 5. Missing Test Categories

| Category | Status | Gap |
|---|---|---|
| Unit tests (backend) | ? | Check `**/*.spec.ts` coverage |
| Integration tests | ? | Check `**/*.integration.spec.ts` |
| E2E backend | ? | Check `test/*.e2e.spec.ts` |
| Component tests (frontend) | ? | Check `**/*.spec.ts` in `front/src/` |
| E2E frontend | ? | Check Playwright specs |
| Accessibility tests | ? | Check Playwright accessibility project |

### 6. Test Infrastructure

- Test configuration correctness (vitest.config.ts)
- CI test execution (all types run in CI?)
- Test speed (are tests slow? why?)
- Coverage reporting (configured and tracked?)

## Output Format

```markdown
# Testing Audit Report

## Summary
- **Overall Health**: GOOD / NEEDS WORK / CRITICAL
- **Estimated coverage**: Backend ~X% | Frontend ~X%
- **Untested critical paths**: N
- **Flaky tests identified**: N
- **Anti-pattern violations**: N

## Coverage Gaps (Critical)
### [TEST-001] Payment flow lacks integration tests
- **Module**: `back/src/modules/business/payments/`
- **Tests found**: 2 unit tests (mocked)
- **Missing**: Integration test with real payment provider mock, E2E test for checkout flow
- **Risk**: Payment bugs reach production undetected

## Test Quality Issues
### [TEST-005] Implementation detail testing in UserService
- **File**: `back/src/modules/core/users/user.service.spec.ts`
- **Issue**: Tests assert on internal method call counts rather than behavioral outcomes
- **Fix**: Assert on returned values and side effects instead

## Flaky Tests
...

## Anti-Pattern Violations
...

## Recommendations
1. Add integration tests for payment and AI modules
2. Fix N flaky tests
3. Migrate ad-hoc mocks to shared `@test/helpers`
```
