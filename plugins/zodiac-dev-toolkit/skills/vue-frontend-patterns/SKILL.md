---
name: vue-frontend-patterns
description: >
  Vue 3 + Quasar + Pinia frontend patterns with Feature-Sliced Design for My Zodiac AI.
  Use when the user asks to "create a component", "add FSD slice", "create feature",
  "add Pinia store", "frontend pattern", "Vue компонент", "создай фичу на фронте",
  "добавь страницу", "Quasar component", or needs guidance on FSD structure,
  state management, or Capacitor mobile patterns.
---

# Vue Frontend Patterns — My Zodiac AI

Apply these patterns for ALL frontend code in `front/src/`.

## Stack

- **Vue 3.5** + Composition API (`<script setup>`)
- **Quasar 2.18** — UI components + Capacitor plugins
- **Pinia 3** — state management
- **Vue Router 4** — routing
- **Vite** + TypeScript 5.9
- **Capacitor 8** — iOS/Android native
- **Vue-i18n 11** — localization
- **Axios** — HTTP client
- **Socket.io-client** — realtime
- **PostHog + NewRelic Browser** — analytics
- **Vitest + Playwright + MSW** — testing

## Feature-Sliced Design (FSD)

### Layer Hierarchy (top → bottom, no upward imports)

```
app → pages → widgets → features → entities → shared
```

### Current Scale (2026-03-18)

- `features/` — 49 slices
- `entities/` — 22 slices
- `widgets/` — 7 slices
- `shared/` — UI, hooks, utils, API contracts

### Creating a New Feature Slice

```
front/src/features/{feature-name}/
├── api/                    # API calls (Axios)
│   └── {feature}.api.ts
├── model/                  # Pinia store + types
│   ├── {feature}.store.ts
│   └── {feature}.types.ts
├── ui/                     # Vue components
│   ├── {FeatureName}.vue
│   └── {FeatureName}Card.vue
├── lib/                    # Utils, composables
│   └── use-{feature}.ts
└── index.ts                # Public API (ONLY export from here)
```

### Public API (index.ts)

```typescript
// features/cosmic-weather-v3/index.ts
export { useCosmicWeatherStore } from './model/cosmic-weather.store';
export { default as CosmicWeatherDashboard } from './ui/CosmicWeatherDashboard.vue';
export { default as ForgeAlertCard } from './ui/ForgeAlertCard.vue';
export type { CosmicWeatherState, ForgeAlert } from './model/cosmic-weather.types';
```

**Rules:**
- Import features ONLY through `index.ts`
- NEVER import feature-to-feature directly
- Shared code goes to `shared/` layer

### Pinia Store Pattern

```typescript
// model/cosmic-weather.store.ts
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { cosmicWeatherApi } from '../api/cosmic-weather.api';
import type { CosmicWeatherState, ForgeAlert } from './cosmic-weather.types';

export const useCosmicWeatherStore = defineStore('cosmic-weather-v3', () => {
  // State
  const weather = ref<CosmicWeatherState | null>(null);
  const loading = ref(false);
  const error = ref<string | null>(null);

  // Getters
  const activeAlerts = computed(() =>
    weather.value?.forgeAlerts?.filter(a => a.isActive) ?? []
  );
  const hasAlerts = computed(() => activeAlerts.value.length > 0);

  // Actions
  async function fetchWeather(userId: string) {
    loading.value = true;
    error.value = null;
    try {
      weather.value = await cosmicWeatherApi.getDaily(userId);
    } catch (e) {
      error.value = (e as Error).message;
    } finally {
      loading.value = false;
    }
  }

  function $reset() {
    weather.value = null;
    loading.value = false;
    error.value = null;
  }

  return { weather, loading, error, activeAlerts, hasAlerts, fetchWeather, $reset };
});
```

### Vue Component Pattern

```vue
<!-- ui/ForgeAlertCard.vue -->
<template>
  <q-card class="forge-alert-card glass-card">
    <q-card-section>
      <div class="text-h6">{{ alert.title }}</div>
      <div class="text-caption text-grey-5">
        {{ $t('cosmicWeather.severity', { level: alert.severity }) }}
      </div>
    </q-card-section>
    <q-card-section>
      <p>{{ alert.description }}</p>
    </q-card-section>
    <q-card-actions align="right">
      <q-btn flat :label="$t('common.details')" @click="emit('details', alert.id)" />
    </q-card-actions>
  </q-card>
</template>

<script setup lang="ts">
import type { ForgeAlert } from '../model/cosmic-weather.types';

interface Props {
  alert: ForgeAlert;
}

defineProps<Props>();
const emit = defineEmits<{
  details: [alertId: string];
}>();
</script>

<style scoped lang="scss">
.forge-alert-card {
  border-radius: var(--glass-border-radius);
  backdrop-filter: blur(var(--glass-blur));
}
</style>
```

### API Layer Pattern

```typescript
// api/cosmic-weather.api.ts
import { apiClient } from '@shared/api/client';
import type { CosmicWeatherState } from '../model/cosmic-weather.types';

export const cosmicWeatherApi = {
  getDaily: (userId: string) =>
    apiClient.get<CosmicWeatherState>(`/v3/cosmic-weather/daily/${userId}`).then(r => r.data),

  getForgeAlerts: (userId: string) =>
    apiClient.get<ForgeAlert[]>(`/v3/cosmic-weather/forge-alerts/${userId}`).then(r => r.data),
};
```

## Shared Layer

```
front/src/shared/
├── api/              # Axios client, interceptors
├── ui/               # Reusable UI components (glass cards, modals, etc.)
├── lib/              # Composables, utils
├── config/           # App constants
├── tokens/           # Design system tokens
└── i18n/             # Shared translations
```

## Cosmic Glass Design System

Use glass design tokens from `shared/tokens/`:
- `--glass-blur` — backdrop blur value
- `--glass-border-radius` — corner radius
- `--glass-bg` — semi-transparent background
- SCSS mixins: `@include glass-card`, `@include glass-surface`

For detailed design system patterns, use the `vue-quasar-glass` skill.

## i18n Rules

- ALL user-facing strings must use `$t()` or `t()`
- Keys organized by feature: `cosmicWeather.title`, `relationships.compatibility`
- Locale files in `front/src/shared/i18n/locales/`

## Capacitor (Mobile)

- Config: `front/capacitor.config.ts`
- Native plugins: Camera, Haptics, PushNotifications, StatusBar
- Platform checks: `import { Capacitor } from '@capacitor/core'; Capacitor.isNativePlatform()`
- Safe area handling for iOS notch

## Key Rules

1. **FSD is mandatory** for all new code
2. **Composition API only** — no Options API
3. **`<script setup>`** — always
4. **TypeScript strict** — no `any`
5. **Scoped styles** — always `<style scoped lang="scss">`
6. Components display state from store — logic lives in stores/composables

## Related Skills in Other Plugins

- **zodiac-feature-forge** `orchestrate-feature/references/frontend-protocol.md` — step-by-step implementation sequence for new features (Scaffold → Types → API → Store → Components → i18n → Tests)
- **zodiac-design-review** `comprehensive-review` — full design review (visual, UX, a11y, tokens)
- **zodiac-quality-gate** `architecture-audit` — verifies FSD compliance
- **vue-quasar-glass** skill — Cosmic Glass design system details
