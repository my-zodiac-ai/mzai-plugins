# Code-Splitting Strategies for Vue 3 + Vite + Capacitor

A catalog of bundle optimization techniques, ordered roughly from easiest/highest-impact to more involved. Read this when you need to recommend specific fixes for bundle bloat.

## Table of Contents

1. [Route-Level Lazy Loading](#1-route-level-lazy-loading)
2. [Component-Level Async Loading](#2-component-level-async-loading)
3. [Vendor Chunk Granularity](#3-vendor-chunk-granularity)
4. [Tree-Shaking Optimization](#4-tree-shaking-optimization)
5. [Dynamic Import for Heavy Libraries](#5-dynamic-import-for-heavy-libraries)
6. [Feature-Flag Gated Loading](#6-feature-flag-gated-loading)
7. [Barrel File Optimization](#7-barrel-file-optimization)
8. [CSS Optimization](#8-css-optimization)
9. [Image and Asset Optimization](#9-image-and-asset-optimization)
10. [Capacitor-Specific Strategies](#10-capacitor-specific-strategies)

---

## 1. Route-Level Lazy Loading

**Impact: HIGH | Effort: LOW**

Every route should use dynamic imports. This is the most basic form of code splitting and should already be in place for all routes.

```typescript
// ✅ Correct — lazy loaded
{
  path: '/horoscope',
  component: () => import('@pages/horoscope-v2').then(m => m.HoroscopePage),
}

// ❌ Wrong — eagerly loaded
import { HoroscopePage } from '@pages/horoscope-v2'
{
  path: '/horoscope',
  component: HoroscopePage,
}
```

**How to find violations:**
```bash
# Look for static imports of page components in route files
grep -n "^import.*Page" front/src/router/routes.ts
```

---

## 2. Component-Level Async Loading

**Impact: MEDIUM-HIGH | Effort: LOW**

Heavy components that aren't visible on initial render should use `defineAsyncComponent`. This is especially important for:
- Chart/visualization components (natal-chart, d3-based views)
- Modals and dialogs with rich content
- Below-the-fold content

```typescript
import { defineAsyncComponent } from 'vue'

// Heavy chart component — load only when needed
const NatalChartWheel = defineAsyncComponent(
  () => import('@/components/natal-chart/NatalChartWheel.vue')
)

// With loading/error states (better UX)
const NatalChartWheel = defineAsyncComponent({
  loader: () => import('@/components/natal-chart/NatalChartWheel.vue'),
  loadingComponent: ChartSkeleton,
  delay: 200,
  errorComponent: ChartError,
})
```

**When to use:**
- Component pulls in >50KB of dependencies
- Component is conditionally rendered (v-if, v-show)
- Component is below the fold or in a tab/accordion

---

## 3. Vendor Chunk Granularity

**Impact: HIGH | Effort: MEDIUM**

When `vendor-other` grows large, it means untracked libraries are being bundled together. Identify the biggest ones and give them explicit chunks in `vite.config.ts`.

```typescript
manualChunks: (id) => {
  // Give big libraries their own chunk
  if (id.includes('node_modules/swiper')) return 'vendor-swiper'
  if (id.includes('node_modules/firebase')) return 'vendor-firebase'
  if (id.includes('node_modules/sentry')) return 'vendor-sentry'

  // Existing chunks...
  if (id.includes('node_modules')) return 'vendor-other'
}
```

**How to find what's in vendor-other:**
```bash
# After a build, check the visualizer
pnpm --dir front build:analyze
# Then open dist/stats.html and look inside vendor-other
```

**Rule of thumb:** Any library >30KB gzip deserves its own chunk so it can be cached independently and isn't re-downloaded when unrelated deps change.

---

## 4. Tree-Shaking Optimization

**Impact: HIGH | Effort: LOW-MEDIUM**

Tree-shaking removes unused exports, but certain patterns break it:

```typescript
// ❌ Blocks tree-shaking — imports everything
import * as d3 from 'd3'
import _ from 'lodash'

// ✅ Enables tree-shaking — imports only what's used
import { select, scaleLinear } from 'd3'
import { debounce, cloneDeep } from 'lodash-es'  // Note: lodash-es, not lodash
```

**Common offenders in Vue projects:**
- `lodash` (use `lodash-es` instead)
- `date-fns` (already tree-shakeable if imported correctly)
- `quasar` (auto-imported by plugin, but manual imports should be specific)
- Any library using CommonJS (`require()`) — these can't be tree-shaken

**How to detect:**
```bash
# Find wildcard imports
grep -rn "import \* as" front/src/
# Find CommonJS require
grep -rn "require(" front/src/ --include="*.ts" --include="*.vue"
```

---

## 5. Dynamic Import for Heavy Libraries

**Impact: HIGH | Effort: MEDIUM**

Some libraries are only needed in specific contexts. Load them on demand:

```typescript
// ❌ Always loaded, even if user never visits natal chart
import * as d3 from 'd3'

// ✅ Loaded only when the chart is rendered
async function renderChart() {
  const d3 = await import('d3')
  // use d3...
}

// ✅ In a composable
export function useNatalChart() {
  const d3Ref = shallowRef(null)

  onMounted(async () => {
    d3Ref.value = await import('d3')
  })

  return { d3: d3Ref }
}
```

**Good candidates for dynamic import:**
- D3 (visualization, only needed in chart views)
- Sentry (can be lazy-loaded after initial render)
- Firebase messaging (only needed after user grants permission)
- Heavy formatting/parsing libraries (Markdown renderers, etc.)

---

## 6. Feature-Flag Gated Loading

**Impact: MEDIUM | Effort: LOW**

If a feature is behind a flag (like `VITE_FF_COSMIC_WEATHER_V3`), its chunk should never load for users who don't have the flag enabled. This is already partially implemented via route guards, but check that:

1. The route itself is conditionally registered (not just guarded)
2. Components used in the flagged feature aren't imported by unflagged code

```typescript
// ✅ Route only registered when flag is on
const routes = [
  ...(import.meta.env.VITE_FF_COSMIC_WEATHER_V3 === 'true'
    ? [{
        path: '/cosmic-weather',
        component: () => import('@features/003-cosmic-weather-v3'),
      }]
    : []),
]
```

---

## 7. Barrel File Optimization

**Impact: MEDIUM-HIGH | Effort: MEDIUM**

Barrel files (`index.ts` that re-export everything) are standard in FSD, but they can cause unwanted imports if not careful:

```typescript
// features/horoscope/index.ts
export { HoroscopeCard } from './ui/HoroscopeCard.vue'
export { useHoroscope } from './model/useHoroscope'
export { HoroscopeService } from './api/horoscope.service'
export { BigHeavyChart } from './ui/BigHeavyChart.vue'  // 🔴 This pulls in d3!
```

If another feature only needs `useHoroscope`, importing from the barrel still pulls in `BigHeavyChart` and its d3 dependency at build time (Vite can often tree-shake this, but not always, especially with side effects).

**Solutions:**
- Use `sideEffects: false` in package.json to help Vite tree-shake
- Split barrel into sub-paths: `@features/horoscope` vs `@features/horoscope/charts`
- Keep heavy components out of the main barrel

---

## 8. CSS Optimization

**Impact: MEDIUM | Effort: LOW**

CSS is often overlooked but can add up, especially with Quasar:

- **Unused Quasar components:** Only import components you actually use via `quasar.config.js`
- **Duplicated styles:** Sass mixins that generate a lot of CSS when included in multiple components
- **CSS code splitting:** Already enabled (`cssCodeSplit: true` in vite.config.ts) — make sure component-scoped styles stay scoped

```bash
# Check total CSS size
find front/dist -name "*.css" -exec du -sh {} \;
```

---

## 9. Image and Asset Optimization

**Impact: MEDIUM | Effort: LOW**

- Images <4KB are inlined as base64 (`assetsInlineLimit: 4096`)
- Larger images should use modern formats (WebP, AVIF) where supported
- SVGs should be component-ified (imported as Vue components) for tree-shaking
- Consider lazy-loading images below the fold with `loading="lazy"`

---

## 10. Capacitor-Specific Strategies

**Impact: HIGH for mobile | Effort: MEDIUM**

For Capacitor mobile apps, bundle size directly affects:
- **App Store size** (users see this before downloading)
- **Cold start time** (JS must parse before the app is interactive)
- **Memory usage** (parsed JS consumes RAM)

**Capacitor-specific optimizations:**
- **Preload critical chunks** — use `modulePreload` for the main route the user lands on
- **Background-load non-critical chunks** — after the initial render, prefetch routes the user is likely to visit
- **Avoid SSR-only code** — dead code from SSR utilities that gets bundled but never runs on mobile
- **Native plugin bridges** — for heavy operations (image processing, crypto), use Capacitor plugins that delegate to native code instead of JS libraries

```typescript
// Prefetch likely next route after initial render
router.afterEach((to) => {
  if (to.path === '/dashboard') {
    // User is on dashboard, likely to visit horoscope next
    import('@pages/horoscope-v2')
  }
})
```

---

## Quick Diagnostic Checklist

When a chunk is too large, check these in order:

1. **Is it pulling in an entire library?** → Switch to named imports
2. **Is it importing from a barrel that re-exports heavy things?** → Use direct imports or split the barrel
3. **Does it include a library only needed conditionally?** → Use dynamic `import()`
4. **Is it a vendor chunk that lumps many libs together?** → Split into named vendor chunks
5. **Is it duplicated across chunks?** → Check for shared dependencies that should be in a common chunk
6. **Is it CSS-heavy?** → Check for duplicated Sass mixin output
7. **Does it contain dead code from a feature flag?** → Gate the route registration, not just the navigation
