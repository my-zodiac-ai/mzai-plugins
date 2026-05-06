---
name: devops-deploy
description: >
  DevOps, CI/CD, Capacitor builds, and deployment patterns for My Zodiac AI.
  Use when the user asks to "deploy", "build for mobile", "Capacitor build",
  "CI/CD", "monitoring", "NewRelic", "Docker", "деплой", "билд", "мобильная сборка",
  "мониторинг", or needs guidance on production deployment, mobile builds, or
  infrastructure configuration.
---

# DevOps & Deploy — My Zodiac AI

## Project Commands

```bash
# Backend
pnpm --dir back start:dev       # Dev server with hot reload
pnpm --dir back build           # Production build
pnpm --dir back start:prod      # Production start
pnpm --dir back lint            # ESLint
pnpm --dir back test            # Unit tests
pnpm --dir back test:cov        # Coverage

# Frontend
pnpm --dir front dev            # Vite dev server
pnpm --dir front build          # Production build
pnpm --dir front preview        # Preview production build
pnpm --dir front lint           # ESLint
pnpm --dir front test           # Unit tests
pnpm --dir front test:e2e       # Playwright E2E
```

> Always check `package.json` for actual script names before running.

## Capacitor Mobile Builds

### iOS

```bash
cd front
pnpm build                      # Build web assets
npx cap sync ios                # Sync to iOS project
npx cap open ios                # Open in Xcode
# In Xcode: Product → Archive → Distribute
```

### Android

```bash
cd front
pnpm build                      # Build web assets
npx cap sync android            # Sync to Android project
npx cap open android            # Open in Android Studio
# Build → Generate Signed Bundle/APK
```

### Key Capacitor Config

```typescript
// front/capacitor.config.ts
const config: CapacitorConfig = {
  appId: 'com.myzodiac.ai',
  appName: 'My Zodiac AI',
  webDir: 'dist/spa',
  server: {
    androidScheme: 'https',
  },
  plugins: {
    PushNotifications: { presentationOptions: ['badge', 'sound', 'alert'] },
    SplashScreen: { launchAutoHide: false },
  },
};
```

### Native Plugin Usage

```typescript
import { Capacitor } from '@capacitor/core';
import { PushNotifications } from '@capacitor/push-notifications';
import { Haptics, ImpactStyle } from '@capacitor/haptics';

// Platform check
if (Capacitor.isNativePlatform()) {
  await PushNotifications.requestPermissions();
  await Haptics.impact({ style: ImpactStyle.Medium });
}
```

## Monitoring

### NewRelic (Backend)

- APM agent: auto-instrumented in production
- Custom metrics via `MetricsService` from `@common/observability/`
- Winston logger integration for structured logging

### PostHog (Frontend)

- Event tracking for user actions
- Feature flags for gradual rollout
- Session recording for debugging

### NewRelic Browser (Frontend)

- Page load performance
- JavaScript error tracking
- AJAX monitoring

## Environment Variables

Backend secrets managed via `.env`:
- Database: `MONGODB_URI`, `REDIS_URL`
- Auth: `JWT_SECRET`, `JWT_EXPIRATION`
- AI: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GOOGLE_AI_KEY`
- Payments: `DODO_API_KEY`, `APPLE_SHARED_SECRET`
- Push: `FIREBASE_PROJECT_ID`, `APN_KEY`
- Monitoring: `NEW_RELIC_LICENSE_KEY`, `POSTHOG_API_KEY`

**NEVER hardcode secrets.** Always use environment variables.

## Pre-Deploy Checklist

1. All tests passing (`pnpm test` in both back/ and front/)
2. Lint clean (`pnpm lint`)
3. Build succeeds (`pnpm build`)
4. No new security vulnerabilities (`pnpm audit`)
5. Database migrations applied (if any schema changes)
6. Feature flags configured for gradual rollout
7. Monitoring alerts set up for new endpoints
8. Rollback plan documented
