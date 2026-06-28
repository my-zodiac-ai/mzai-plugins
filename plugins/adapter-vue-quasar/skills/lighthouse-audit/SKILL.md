---
name: lighthouse-audit
description: >
  Run Lighthouse CI audits on the My Zodiac AI frontend, parse results, compare scores against
  budgets from .lighthouserc.js, and generate a prioritized action-items report broken down by
  category (Performance, Accessibility, Best Practices, SEO). Use this skill whenever the user
  mentions "lighthouse", "lighthouse audit", "web performance audit", "page speed", "core web vitals",
  "CWV check", "performance budget", "accessibility score", "SEO score", "pre-release performance check",
  "проверь производительность фронта", "lighthouse отчёт", "аудит скорости", or wants to verify
  frontend quality metrics before a release. Also trigger when the user asks to "run test:lighthouse",
  "check lighthouse scores", or references lighthouserc / LHCI in any way.
x-scope: adapter:vue-quasar
x-stack: vue-quasar
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Lighthouse Audit Skill

Run Lighthouse CI against the My Zodiac AI frontend, parse JSON results, compare every metric
against the budgets defined in `.lighthouserc.js`, and produce a Markdown report with
prioritized, actionable fix suggestions.

## Why this skill exists

The project already has `pnpm --dir front test:lighthouse` (which calls `lhci autorun`) and a
rich `.lighthouserc.js` with per-category score thresholds, Core Web Vitals budgets, and
resource-size limits. But raw LHCI terminal output is noisy and hard to act on. This skill
bridges that gap: it runs the audit, digests the results, and hands the developer a clean
report with concrete next steps — sorted by severity so the most impactful fixes come first.

## Workflow

### 1. Run LHCI

```bash
cd front && pnpm test:lighthouse 2>&1 | tail -80
```

LHCI writes JSON reports to `front/.lighthouseci/`. Each run produces files like
`lhr-<hash>.json` — full Lighthouse Result objects.

If the command fails (missing Chrome, server not starting, etc.), diagnose the error:
- **Chrome not found** → suggest `CHROME_PATH` or `--chromeFlags`
- **Server timeout** → check if `npm run serve:test` works, increase `startServerReadyTimeout`
- **Port conflict** → check what's using port 9000

If LHCI is not installed globally, try `npx @lhci/cli autorun` as a fallback.

### 2. Locate and parse results

```bash
ls -t front/.lighthouseci/lhr-*.json | head -10
```

Read the most recent batch of `lhr-*.json` files (there will be `numberOfRuns × urls` files).
Each file is a standard Lighthouse Result JSON with this structure:

```
{
  "requestedUrl": "http://localhost:9000/horoscope/daily",
  "categories": {
    "performance":      { "score": 0.92 },
    "accessibility":    { "score": 0.97 },
    "best-practices":   { "score": 0.88 },
    "seo":              { "score": 0.91 }
  },
  "audits": {
    "first-contentful-paint":    { "numericValue": 1200, "score": 0.95 },
    "largest-contentful-paint":  { "numericValue": 2100, "score": 0.80 },
    "cumulative-layout-shift":   { "numericValue": 0.05, "score": 0.98 },
    "total-blocking-time":       { "numericValue": 180,  "score": 0.90 },
    "speed-index":               { "numericValue": 2800, "score": 0.85 },
    "interactive":               { "numericValue": 3500, "score": 0.82 },
    "resource-summary":          { "details": { "items": [...] } },
    ...other audits
  }
}
```

### 3. Compare against budgets

The budgets live in `front/.lighthouserc.js`. Load them using:

```bash
node -e "const c = require('./front/.lighthouserc.js'); console.log(JSON.stringify(c.ci.assert.assertions, null, 2))"
```

Key thresholds to compare (default / CI profile):

| Metric | Level | Budget |
|--------|-------|--------|
| Performance score | warn | ≥ 0.8 |
| Accessibility score | error | ≥ 0.9 |
| Best Practices score | warn | ≥ 0.8 |
| SEO score | warn | ≥ 0.8 |
| FCP | warn | ≤ 2000ms |
| LCP | warn | ≤ 2500ms |
| CLS | warn | ≤ 0.1 |
| TBT | warn | ≤ 300ms |
| Speed Index | warn | ≤ 3400ms |
| TTI | warn | ≤ 5000ms |
| JS bundle size | warn | ≤ 250KB |
| Total page size | warn | ≤ 1MB |
| Image size | warn | ≤ 500KB |

Also check the production profile — it uses stricter thresholds (0.9 / 0.95) which matter
for release readiness.

### 4. Generate the report

Write a `scripts/parse-lighthouse.sh` helper script that extracts scores from the JSON files
and outputs structured data. Then build the Markdown report.

Save to `front/lighthouse-report.md`.

#### Report template

```markdown
# Lighthouse Audit Report
**Date:** YYYY-MM-DD HH:MM
**URLs audited:** N | **Runs per URL:** 3
**Profile:** CI (default) | **Status:** X passed, Y warnings, Z errors

---

## Score Summary

| URL | Perf | A11y | BP | SEO |
|-----|------|------|----|-----|
| /horoscope/daily | 🟢 92 | 🟢 97 | 🟡 78 | 🟢 91 |
| ... | ... | ... | ... | ... |

**Legend:** 🟢 passes budget · 🟡 within 5% of budget · 🔴 fails budget

---

## Core Web Vitals

| Metric | Median | Budget | Status |
|--------|--------|--------|--------|
| FCP | 1.2s | ≤2.0s | 🟢 |
| LCP | 2.6s | ≤2.5s | 🔴 |
| CLS | 0.05 | ≤0.1 | 🟢 |
| TBT | 180ms | ≤300ms | 🟢 |

---

## Resource Budgets

| Resource | Actual | Budget | Status |
|----------|--------|--------|--------|
| JS bundle | 220KB | ≤250KB | 🟡 |
| Total page | 850KB | ≤1MB | 🟢 |
| Images | 320KB | ≤500KB | 🟢 |

---

## Action Items

### 🔴 Critical (budget exceeded)

1. **LCP too high on /horoscope/daily (2.6s vs 2.5s budget)**
   - [specific fix referencing actual audit details and codebase files]
   - [another specific fix]

### 🟡 Warnings (approaching budget)

1. **Best Practices score 78 on /horoscope/daily (budget: 80)**
   - [specific audit failures from the report]

### 🟢 Passing — quick wins

- [optional: low-effort improvements found in audit details even for passing categories]

---

## Production Readiness

Compare against the stricter `production` profile thresholds:
| Category | Current | Prod Budget | Gap |
|----------|---------|-------------|-----|
| Performance | 0.92 | 0.90 | ✅ |
| Accessibility | 0.87 | 0.95 | ❌ -8pts |
```

### 5. Drill into specifics for failing categories

For any category or metric that fails its budget, read the relevant audit details from the
LHR JSON and cross-reference with the codebase to give actionable fixes:

**Performance failures** — check:
- `audits.render-blocking-resources` → identify blocking CSS/JS files
- `audits.unused-javascript` → find unused JS chunks, suggest code-splitting
- `audits.unused-css-rules` → identify unused CSS
- `audits.offscreen-images` → suggest lazy loading for below-fold images
- `audits.uses-optimized-images` → suggest WebP/AVIF conversion
- `audits.mainthread-work-breakdown` → identify expensive scripts
- Cross-reference with `front/src/` to name specific components/files

**Accessibility failures** — check:
- `audits.color-contrast` → list failing elements
- `audits.image-alt` → list images missing alt text
- `audits.heading-order` → list heading hierarchy issues
- `audits.aria-*` → list ARIA violations

**Best Practices failures** — check:
- `audits.is-on-https`, `audits.uses-http2`
- `audits.no-vulnerable-libraries`
- `audits.errors-in-console`
- `audits.deprecations`

**SEO failures** — check:
- `audits.meta-description`, `audits.document-title`
- `audits.link-text`, `audits.robots-txt`
- `audits.canonical`, `audits.hreflang`

For passing categories, skip detailed analysis — just report the score.

### 6. Summarize and link

After saving the report file, print a short summary in chat:
- Total pass/warn/fail counts
- The single most impactful action item
- Link to the full report file

## Important notes

- LHCI needs a running dev server. The `.lighthouserc.js` config has `startServerCommand`
  that handles this, but if it fails, you may need to start the server manually first.
- The audit runs 3 times per URL by default. Use median values for comparison, not individual runs.
- If the `.lighthouseci/` directory has old results mixed in, filter by file modification time
  to pick only the latest batch.
- The `lighthouserc.json` (root-level) is a simpler config with fewer URLs — it's the "dev"
  variant. The `.lighthouserc.js` is the full CI config. Prefer `.lighthouserc.js`.
