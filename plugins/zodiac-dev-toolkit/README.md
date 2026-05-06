# zodiac-dev-toolkit

Complete engineering toolkit for **My Zodiac AI** — a monorepo with NestJS backend + Vue 3/Quasar frontend + Capacitor mobile.

## Skills

| Skill | Triggers | What it does |
|-------|----------|-------------|
| **nestjs-backend-patterns** | "create module", "EDA event", "add adapter", "NestJS паттерн" | EDA/DDD architecture, event listeners, repository pattern, adapter tokens, bounded contexts |
| **vue-frontend-patterns** | "create component", "FSD slice", "Pinia store", "Vue компонент" | FSD structure, Composition API, Pinia stores, Quasar components, Capacitor mobile |
| **astrology-domain** | "natal chart", "transit", "synastry", "Swiss Ephemeris" | Astrology calculations, Swiss Ephemeris integration, cosmic weather, planetary positions |
| **ai-llm-patterns** | "AI generation", "optimize costs", "prompt", "semantic cache" | Multi-provider fallback, cost optimization, semantic caching, prompt building |
| **tdd-testing** | "write test", "TDD", "Vitest", "coverage" | Vitest patterns for backend (NestJS) and frontend (Vue), TDD workflow, Playwright E2E |
| **api-design** | "create endpoint", "DTO", "REST API" | Controller patterns, DTOs, validation, pagination, versioning, error responses |
| **devops-deploy** | "deploy", "Capacitor build", "CI/CD", "monitoring" | Build commands, Capacitor iOS/Android, NewRelic, PostHog, environment config |
| **claude-api-integration** | "Claude API", "Anthropic SDK", "streaming" | Messages API, streaming, prompt caching, cost tracking, provider pattern |
| **redis-caching** | "add caching", "Redis TTL", "BullMQ queue", "distributed lock" | Cache-aside pattern, TTL strategies, invalidation, BullMQ queues, Redlock |
| **notifications-push** | "push notification", "FCM", "APN", "in-app notification" | Firebase, APN, WebSocket delivery, scheduling, templates, AI content pipeline |
| **payments-subscriptions** | "payment flow", "Apple IAP", "Google billing", "subscription" | DodoPayments, Apple/Google receipts, webhooks, tier management, subscription lifecycle |

## Agents

| Agent | Triggers | Purpose |
|-------|----------|---------|
| **nestjs-reviewer** | "review backend code", "check EDA compliance" | Code review for NestJS: EDA, DDD, adapters, error handling |
| **vue-reviewer** | "review frontend code", "check FSD" | Code review for Vue: FSD, i18n, TypeScript, design system |
| **build-resolver** | "build failing", "fix type errors" | Minimal surgical fixes for TypeScript/Vite/NestJS build errors |

## Tech Stack

- **Backend**: NestJS 11, TypeScript 5.9, MongoDB, Redis, BullMQ, EventEmitter2
- **Frontend**: Vue 3.5, Quasar 2.18, Pinia 3, Vite, Capacitor 8
- **AI**: OpenAI, Anthropic Claude, Google Gemini (multi-provider fallback)
- **Astrology**: Swiss Ephemeris (sweph), Lunar-typescript
- **Testing**: Vitest, Playwright, MSW, Vue Test Utils
- **Payments**: DodoPayments, Apple IAP, Google Play Billing
- **Notifications**: Firebase, APN, WebPush, Socket.io
- **Monitoring**: NewRelic, PostHog
