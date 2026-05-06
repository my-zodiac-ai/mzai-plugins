# When to Use Which Skill — zodiac-dev-toolkit Decision Tree

> Quick reference: pick the right skill for your task.

## Backend Tasks

| Задача | Скилл | Почему |
|--------|-------|--------|
| Создать новый NestJS модуль/сервис | **nestjs-backend-patterns** | EDA/DDD паттерны, module structure |
| Добавить event или listener | **nestjs-backend-patterns** | EDA events, listener safety rules |
| Создать REST endpoint | **api-design** | Controller, DTO, validation, pagination |
| Добавить кэширование (Redis) | **redis-caching** | Cache-aside, TTL, invalidation patterns |
| Добавить фоновую задачу (BullMQ) | **redis-caching** | Queue patterns, job config, processors |
| Добавить distributed lock | **redis-caching** | Redlock pattern |
| Добавить push/in-app уведомление | **notifications-push** | FCM, APN, templates, scheduling |
| Работать с платежами/подписками | **payments-subscriptions** | Webhooks, lifecycle, tier management |
| Интегрировать AI (OpenAI/Claude/Gemini) | **ai-llm-patterns** | Fallback chain, cost optimizer, caching |
| Интегрировать Claude API конкретно | **claude-api-integration** | Messages API, streaming, prompt caching |
| Добавить астрологический расчёт | **astrology-domain** | Swiss Ephemeris, natal charts, aspects |
| Написать тест (backend) | **tdd-testing** | Vitest patterns, mocks, AAA structure |
| Собрать/задеплоить backend | **devops-deploy** | Build commands, env vars, monitoring |

## Frontend Tasks

| Задача | Скилл | Почему |
|--------|-------|--------|
| Создать новый FSD feature slice | **vue-frontend-patterns** | FSD structure, public API, components |
| Создать Pinia store | **vue-frontend-patterns** | Setup store pattern, loading/error state |
| Создать Vue компонент | **vue-frontend-patterns** | Composition API, Quasar, glass tokens |
| Написать тест (frontend) | **tdd-testing** | Vue Test Utils, Pinia testing, MSW |
| Собрать мобилку (Capacitor) | **devops-deploy** | iOS/Android build, sync, native plugins |

## Cross-Cutting

| Задача | Скилл | Альтернативный плагин |
|--------|-------|----------------------|
| Code review (backend) | Агент **nestjs-reviewer** | zodiac-quality-gate (code-quality-audit) |
| Code review (frontend) | Агент **vue-reviewer** | zodiac-quality-gate (architecture-audit) |
| Починить билд | Агент **build-resolver** | — |
| Полная реализация фичи из спеки | — | **zodiac-feature-forge** (orchestrate-feature) |
| Верификация спеки vs код | — | **spec-verifier** (verify-spec) |
| Полный аудит кода | — | **zodiac-quality-gate** (full-quality-gate) |
| Дизайн-ревью | — | **zodiac-design-review** (comprehensive-review) |
| Исследование фичи | — | **zodiac-research-lab** (deep-research) |
