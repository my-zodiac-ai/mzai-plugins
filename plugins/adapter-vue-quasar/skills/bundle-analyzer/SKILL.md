---
name: bundle-analyzer
description: >
  Analyze frontend bundle size for the My Zodiac AI mobile app — compare before/after changes,
  find heavy imports, suggest code-splitting strategies, and track chunk size trends.
  Use this skill whenever the user mentions bundle size, chunk analysis, heavy imports,
  code splitting, "what's making the build big", "бандл", "размер бандла", "тяжёлые импорты",
  "build:analyze", "check-bundle-size", or wants to understand the impact of their changes
  on the app's download size. Also trigger when reviewing a feature for mobile performance
  and the conversation touches on JS payload, lazy loading, or vendor chunk growth —
  even if the user doesn't explicitly say "bundle".
x-scope: adapter:vue-quasar
x-stack: vue-quasar
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Bundle Analyzer

Analyze, compare, and optimize frontend bundle sizes for My Zodiac AI — a Capacitor mobile app where every kilobyte matters for app store ratings, cold start time, and user retention on slow networks.

## When to use this skill

- **Before merging a feature:** compare bundle size before/after your changes
- **Hunting bloat:** find which chunks grew, which imports are heavy
- **Architecture reviews:** evaluate code-splitting strategy, suggest improvements
- **Trend tracking:** update the baseline and catch gradual drift over time

## Project context

The frontend lives in `front/` and uses:
- **Vite + Quasar** (Vue 3) with `rollup-plugin-visualizer`
- **Manual chunks** in `vite.config.ts` — vendor splits (vue, quasar, d3, date-fns, axios, lodash-es) and feature splits (cosmic-weather-v3, lunar-calendar, natal-chart, relationships, dashboard)
- **Route-level lazy loading** — every route uses `() => import(...)`
- **Lighthouse budgets** in `.lighthouserc.js` — 250KB JS per file, 1MB total
- **Feature-specific targets** — e.g. cosmic-weather-v3 < 150KB gzip

Key commands:
```bash
pnpm --dir front build                  # Production build
pnpm --dir front build:analyze          # Build + open dist/stats.html (visualizer)
```

## Workflow

### Step 1: Determine comparison mode

Ask the user (or infer from context) which analysis they need:

| Mode | When | What happens |
|------|------|-------------|
| **Before/after** | User has uncommitted changes | Git stash → build baseline → restore → build current → compare |
| **Current snapshot** | User just wants to see what's big | Single build → analyze chunks |
| **Against baseline** | Baseline file exists in repo | Build current → compare against `front/bundle-baseline.json` |

### Step 2: Build and extract sizes

Run the bundled extraction script from the project root:

```bash
bash <skill-path>/scripts/analyze-bundle.sh <mode>
```

Where `<mode>` is one of: `compare`, `snapshot`, `baseline`.

The script outputs JSON files to `front/.bundle-analysis/`:
- `after.json` — current build chunk sizes (raw + gzip)
- `before.json` — baseline build chunk sizes (only in `compare` mode)

Each JSON looks like:
```json
{
  "timestamp": "2026-04-03T12:00:00Z",
  "git_ref": "abc1234",
  "git_message": "feat: add lunar achievements",
  "total_raw": 2456789,
  "total_gzip": 678901,
  "chunks": [
    { "name": "vendor-vue", "raw": 234567, "gzip": 67890, "file": "js/vendor-vue-abc123.js" },
    ...
  ]
}
```

**If the build fails**, don't just report the failure — read the error output and help the user fix it before retrying.

### Step 3: Generate the comparison report

Run the comparison script:

```bash
node <skill-path>/scripts/compare-bundles.js \
  --after front/.bundle-analysis/after.json \
  --before front/.bundle-analysis/before.json \
  --budgets front/.lighthouserc.js \
  --output front/.bundle-analysis/bundle-report.md
```

For snapshot mode (no `--before`), it still generates a useful report showing absolute sizes, budget compliance, and the largest chunks.

### Step 4: Analyze and recommend

Read the generated report and enrich it with your analysis. The report has the numbers — your job is to explain the **why** and the **what to do about it**.

#### Finding heavy imports

If a chunk grew unexpectedly or is just large, investigate:

1. **Check the visualizer** — if `dist/stats.html` was generated (via `build:analyze`), note its existence for the user. It shows a treemap of what's inside each chunk.

2. **Trace the imports** — for a suspiciously large chunk, grep for what's pulling things in:
   ```bash
   # Find what a feature chunk imports from node_modules
   grep -r "from '" front/src/features/003-cosmic-weather-v3/ | grep node_modules
   # Or check direct imports of a heavy library
   grep -rn "import.*from.*d3" front/src/
   ```

3. **Check for barrel file bloat** — a common issue in Vue/FSD projects:
   ```bash
   # Look for index.ts files that re-export everything
   grep -l "export \*" front/src/features/*/index.ts
   ```

#### Code-splitting recommendations

Read `<skill-path>/references/code-splitting-strategies.md` for the full catalog of strategies. Pick the ones that apply to the current situation. Common wins:

- **Dynamic import for heavy components** — if a chart library is in the main bundle, wrap it in `defineAsyncComponent`
- **Route-level splitting** — if a page's component isn't lazy-loaded, that's low-hanging fruit
- **Vendor chunk granularity** — if `vendor-other` is huge, identify the biggest libraries inside and give them their own chunks in `vite.config.ts`
- **Feature flag gating** — if a feature is behind a flag, its chunk shouldn't load for users who don't have it enabled
- **Tree-shaking blockers** — `import * as X` or CommonJS `require()` prevents tree-shaking

#### Budget compliance

Compare chunk sizes against the Lighthouse budgets from `.lighthouserc.js`:
- JS per file: warn at 200KB, error at 250KB
- Total JS: warn at 1MB
- Feature-specific: cosmic-weather-v3 < 150KB gzip

Flag any violations and suggest concrete fixes.

### Step 5: Update baseline (optional)

If the user wants to save the current state as the new baseline:

```bash
cp front/.bundle-analysis/after.json front/bundle-baseline.json
```

Remind the user to commit this file so future comparisons have a reference point.

## Report template

The generated markdown report follows this structure (the script handles formatting — you add the analysis sections):

```markdown
# Bundle Analysis Report
> Generated: {date} | Git: {ref} ({message})

## Summary
| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| Total (raw) | ... | ... | +X% |
| Total (gzip) | ... | ... | +X% |
| Chunk count | ... | ... | ... |

## Chunk Details
| Chunk | Before (gzip) | After (gzip) | Delta | Status |
|-------|---------------|--------------|-------|--------|
| vendor-vue | 68KB | 68KB | 0 | ✅ |
| cosmic-weather-v3 | 120KB | 155KB | +29% | 🔴 Over budget |
...

## Budget Compliance
- ✅ vendor-vue: 68KB (budget: 250KB)
- 🔴 cosmic-weather-v3: 155KB gzip (budget: 150KB)
...

## Heavy Imports Analysis
{your analysis goes here — what's big, why, trace of imports}

## Recommendations
{your prioritized recommendations — most impactful first}

## Trend
{if baseline history exists, show how total size has changed over time}
```

## Important notes

- The build can take 1-3 minutes. Warn the user it'll take a moment.
- In `compare` mode, the script uses `git stash` — if there are no changes to stash, it falls back to comparing against HEAD~1.
- The gzip sizes are what matter for mobile — raw sizes are useful for understanding composition but gzip is what users download.
- Don't forget to check CSS bundles too — they're often overlooked but can be significant, especially with Quasar's component styles.
