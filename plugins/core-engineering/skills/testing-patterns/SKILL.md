---
name: testing-patterns
description: >
  Test-Driven Development and testing patterns for any JS/TS project — unit, integration,
  and E2E. Detects the test runner (Vitest/Jest/Playwright) instead of assuming one.
  Use when the user asks to "write tests", "add unit test", "create spec", "TDD",
  "test coverage", "fix failing test", "напиши тест", "покрой тестами", "тестирование",
  "Vitest", "Jest", "Playwright", "MSW", or needs guidance on test structure for
  backend or frontend.
x-scope: core
x-stack: any
---

# TDD & Testing Patterns

Stack-agnostic testing method. Detect the project's runner and conventions first
(`package.json` scripts, `vitest.config.*` / `jest.config.*` / `playwright.config.*`),
then apply the patterns below. Examples at the bottom use one concrete stack; the method
is the same everywhere.

## Test layers (map to your project)

| Layer | Typical tools | What it covers |
|-------|---------------|----------------|
| Unit | Vitest / Jest | One function/class/component in isolation, deps mocked |
| Integration | Vitest / Jest (+ Supertest for HTTP) | A module against real collaborators (DB, cache) |
| E2E | Playwright / Cypress | User-visible flows through the running app |
| API mocking | MSW / nock | Deterministic network in unit/component tests |

Use the runner the repo already has — do **not** introduce a second one. If the repo
standardizes on Vitest, don't add Jest (and vice-versa).

## TDD workflow

```
1. Write a failing test FIRST
2. Implement the minimal code to pass
3. Refactor while keeping tests green
4. Repeat
```

## Test rules (universal)

1. **AAA structure** — Arrange → Act → Assert in every test.
2. **Isolation** — each test independent; no shared mutable state; reset between tests.
3. **Test-first** — write the failing test before the implementation.
4. **Behavior, not implementation** — assert observable outcomes, not internals.
5. **Reuse fixtures/builders** — keep a shared `test/` helpers/mocks module.
6. **Mock external dependencies** — never hit real APIs/DB in unit tests.
7. **One logical assertion per test** (multiple `expect`s are fine if they check one behavior).
8. **Side effects** — assert events/messages are emitted after the state change that triggers them.
9. **Frontend** — provide an i18n mock (`$t: (key) => key`) so text assertions are key-based.
10. **E2E** — use the Page Object Model; keep selectors out of test bodies.
11. **Coverage is a signal, not a target** — cover critical paths; don't game the percentage.

## Running tests

Read the scripts from `package.json` (don't hardcode). Typical shapes:

```bash
<pm> test                 # unit
<pm> test:integration     # integration
<pm> test:e2e             # E2E
<pm> test:cov             # coverage
# monorepo: scope to a workspace, e.g. `pnpm --dir <workspace> test`
```

---

## Example: My Zodiac AI stack (NestJS + Vue 3 + Quasar + Vitest)

Illustrative only — concrete syntax for one project. Map the structure to your own stack.

Architecture: backend unit/integration/e2e via Vitest (+ Supertest) under `back/`; frontend
unit via Vitest + Vue Test Utils and E2E via Playwright under `front/`; MSW for API mocking.

### Backend unit test (NestJS + Mongoose)

```typescript
// back/src/modules/core/users/handlers/__tests__/register-user.handler.spec.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { Test } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';

vi.mock('isomorphic-dompurify', () => ({
  sanitize: vi.fn((input: string) => input.replace(/<[^>]*>/g, '')),
}));

describe('RegisterUserCommandHandler', () => {
  let handler: RegisterUserCommandHandler;
  let mockUserModel: any;
  let mockEventEmitter: any;

  beforeEach(async () => {
    mockUserModel = { create: vi.fn(), findOne: vi.fn() };
    mockEventEmitter = { emit: vi.fn() };
    const module = await Test.createTestingModule({
      providers: [
        RegisterUserCommandHandler,
        { provide: getModelToken(User.name), useValue: mockUserModel },
        { provide: EventEmitterService, useValue: mockEventEmitter },
      ],
    }).compile();
    handler = module.get(RegisterUserCommandHandler);
  });

  it('registers a user and emits an event', async () => {
    const command = buildEmailCommand({ email: 'test@example.com' });          // Arrange
    mockUserModel.create.mockResolvedValue(buildSavedUserStub());
    const result = await handler.execute(command);                             // Act
    expect(result).toBeDefined();                                              // Assert
    expect(mockUserModel.create).toHaveBeenCalledOnce();
    expect(mockEventEmitter.emit).toHaveBeenCalledWith(
      SystemEvents.USER_REGISTERED,
      expect.objectContaining({ userId: expect.any(String) }),
    );
  });
});
```

### Frontend component test (Vue Test Utils + Pinia)

```typescript
import { describe, it, expect } from 'vitest';
import { mount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import AlertCard from '../AlertCard.vue';

describe('AlertCard', () => {
  const mockAlert = { id: '1', title: 'Mars Square Saturn', severity: 'high', isActive: true };

  it('renders title and severity, emits details on click', async () => {
    const wrapper = mount(AlertCard, {
      props: { alert: mockAlert },
      global: { plugins: [createTestingPinia()], mocks: { $t: (k: string) => k } },
    });
    expect(wrapper.text()).toContain('Mars Square Saturn');
    await wrapper.find('.q-btn').trigger('click');
    expect(wrapper.emitted('details')).toEqual([['1']]);
  });
});
```

### Pinia store test

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { useForecastStore } from '../forecast.store';

vi.mock('../../api/forecast.api', () => ({ forecastApi: { getDaily: vi.fn() } }));

describe('useForecastStore', () => {
  beforeEach(() => setActivePinia(createPinia()));

  it('fetches data and sets state', async () => {
    const store = useForecastStore();
    forecastApi.getDaily.mockResolvedValue({ items: [{ id: '1', isActive: true }] });
    await store.fetch('user-123');
    expect(store.loading).toBe(false);
    expect(store.hasItems).toBe(true);
  });
});
```
