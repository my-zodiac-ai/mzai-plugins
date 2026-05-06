---
name: tdd-testing
description: >
  Test-Driven Development patterns with Vitest for My Zodiac AI monorepo.
  Use when the user asks to "write tests", "add unit test", "create spec",
  "TDD", "test coverage", "fix failing test", "напиши тест", "покрой тестами",
  "тестирование", "Vitest", "Playwright", "MSW", or needs guidance on testing
  patterns for backend (NestJS) or frontend (Vue 3).
---

# TDD & Testing — My Zodiac AI

## Test Architecture

| Type | Tool | Location | Config |
|------|------|----------|--------|
| Unit (backend) | Vitest | `back/src/**/*.spec.ts` | `back/vitest.config.ts` |
| Integration (backend) | Vitest | `back/src/**/*.integration.spec.ts` | `back/vitest.integration.config.ts` |
| E2E (backend) | Vitest + Supertest | `back/test/` | `back/vitest.e2e.config.ts` |
| Unit (frontend) | Vitest + Vue Test Utils | `front/src/**/*.spec.ts` | `front/vitest.config.ts` |
| E2E (frontend) | Playwright | `front/e2e/` | `front/playwright.config.ts` |
| API mocking | MSW | `front/src/` | — |

**Vitest is the ONLY test framework** — never use Jest.

## TDD Workflow

```
1. Write failing test FIRST
2. Implement minimal code to pass
3. Refactor while keeping tests green
4. Repeat
```

## Backend Unit Test Pattern

```typescript
// back/src/modules/core/users/handlers/__tests__/register-user.handler.spec.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { Test } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { Types } from 'mongoose';

// Module-level mocks
vi.mock('isomorphic-dompurify', () => ({
  sanitize: vi.fn((input: string) => input.replace(/<[^>]*>/g, '')),
}));

describe('RegisterUserCommandHandler', () => {
  let handler: RegisterUserCommandHandler;
  let mockUserModel: any;
  let mockEventEmitter: any;

  beforeEach(async () => {
    mockUserModel = {
      create: vi.fn(),
      findOne: vi.fn(),
    };
    mockEventEmitter = {
      emit: vi.fn(),
    };

    const module = await Test.createTestingModule({
      providers: [
        RegisterUserCommandHandler,
        { provide: getModelToken(User.name), useValue: mockUserModel },
        { provide: EventEmitterService, useValue: mockEventEmitter },
      ],
    }).compile();

    handler = module.get(RegisterUserCommandHandler);
  });

  describe('execute', () => {
    it('should register user and emit event', async () => {
      // Arrange
      const command = buildEmailCommand({ email: 'test@example.com' });
      mockUserModel.create.mockResolvedValue(buildSavedUserStub());

      // Act
      const result = await handler.execute(command);

      // Assert
      expect(result).toBeDefined();
      expect(mockUserModel.create).toHaveBeenCalledOnce();
      expect(mockEventEmitter.emit).toHaveBeenCalledWith(
        SystemEvents.USER_REGISTERED,
        expect.objectContaining({ userId: expect.any(String) }),
      );
    });
  });
});
```

## Frontend Unit Test Pattern

```typescript
// front/src/features/cosmic-weather/ui/__tests__/ForgeAlertCard.spec.ts
import { describe, it, expect } from 'vitest';
import { mount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import ForgeAlertCard from '../ForgeAlertCard.vue';

describe('ForgeAlertCard', () => {
  const mockAlert = {
    id: '1',
    title: 'Mars Square Saturn',
    severity: 'high',
    description: 'Tension between action and restriction',
    isActive: true,
  };

  it('renders alert title and severity', () => {
    const wrapper = mount(ForgeAlertCard, {
      props: { alert: mockAlert },
      global: {
        plugins: [createTestingPinia()],
        mocks: { $t: (key: string) => key },
      },
    });

    expect(wrapper.text()).toContain('Mars Square Saturn');
    expect(wrapper.text()).toContain('cosmicWeather.severity');
  });

  it('emits details event on button click', async () => {
    const wrapper = mount(ForgeAlertCard, {
      props: { alert: mockAlert },
      global: {
        plugins: [createTestingPinia()],
        mocks: { $t: (key: string) => key },
      },
    });

    await wrapper.find('.q-btn').trigger('click');
    expect(wrapper.emitted('details')).toEqual([['1']]);
  });
});
```

## Pinia Store Test Pattern

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { useCosmicWeatherStore } from '../cosmic-weather.store';

vi.mock('../../api/cosmic-weather.api', () => ({
  cosmicWeatherApi: {
    getDaily: vi.fn(),
  },
}));

describe('useCosmicWeatherStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it('fetches weather and sets state', async () => {
    const store = useCosmicWeatherStore();
    const mockData = { forgeAlerts: [{ id: '1', isActive: true }] };
    cosmicWeatherApi.getDaily.mockResolvedValue(mockData);

    await store.fetchWeather('user-123');

    expect(store.weather).toEqual(mockData);
    expect(store.loading).toBe(false);
    expect(store.hasAlerts).toBe(true);
  });
});
```

## Test Rules

1. **AAA structure**: Arrange → Act → Assert in every test
2. **Isolation**: Each test independent, no shared mutable state
3. **TDD**: Write failing test BEFORE implementation
4. **Cover behavior, not implementation** details
5. **Reuse test utils** from `@test/mocks` and `@test/helpers`
6. **Mock external dependencies** — never hit real APIs/DB in unit tests
7. **Use `vi.fn()`** for mocks, `vi.mock()` for module-level mocks
8. **Event listeners**: Test that events are emitted after DB save
9. **Frontend**: Always provide i18n mock `$t: (key) => key`
10. **Playwright E2E**: Use Page Object Model pattern

## Running Tests

```bash
# Backend
pnpm --dir back test                    # Unit tests
pnpm --dir back test:integration        # Integration tests
pnpm --dir back test:e2e               # E2E tests
pnpm --dir back test:cov               # Coverage report

# Frontend
pnpm --dir front test                   # Unit tests
pnpm --dir front test:e2e              # Playwright E2E
```
