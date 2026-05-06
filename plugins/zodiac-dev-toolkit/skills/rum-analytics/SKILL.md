---
name: rum-analytics
description: >
  Analyze Real User Monitoring data for My Zodiac AI — pull Core Web Vitals from NewRelic
  Browser (PageViewTiming, appId=538822289), segment by OS/browser (userAgentOS/userAgentName)
  and geography (countryCode), compare real-user p75 metrics against Lighthouse baselines, and
  generate an interactive HTML report with code-level fix suggestions. PostHog has no web vitals
  events. Use when user mentions: "RUM data", "real user metrics", "CWV analysis", "Core Web
  Vitals", "LCP regression", "CLS issues", "INP problems", "FCP slow", "synthetic vs real",
  "lighthouse comparison", "performance by device", "mobile vs desktop", "geo performance",
  "why is the app slow on Android/Firefox", "performance regression after deploy",
  "реальные метрики", "CWV отчёт", "RUM отчёт", "производительность на устройствах",
  "анализ производительности", "которые страны медленные", "are our vitals passing in the
  field". Complements lighthouse-audit (synthetic) and newrelic-health-check (backend APM).
---

# RUM Analytics

Analyze Core Web Vitals from real user sessions across PostHog and NewRelic Browser, segment
performance by device characteristics, compare against Lighthouse synthetic baselines, and
produce an actionable HTML report with code-level fix suggestions.

## Why this skill exists

Lighthouse scores (synthetic, lab environment) often paint a rosier picture than what real users
experience on budget Android phones or spotty mobile networks. This skill bridges that gap: it
pulls actual field data from two complementary sources (PostHog custom CWV events + NewRelic
Browser's `PageViewTiming`), segments it by the dimensions that matter (device class, OS,
browser, connection type, page), and compares p75 values against both Google's "good" thresholds
and your latest Lighthouse run. The output is an interactive HTML report with specific code
changes to fix the worst offenders.

## Available MCP tools

| Tool | Source | Purpose |
|------|--------|---------|
| `mcp__3dc9ae8a-...__query-trends` | PostHog | Trend queries for CWV custom events |
| `mcp__3dc9ae8a-...__query-run` | PostHog | Raw HogQL queries for flexible analysis |
| `mcp__3dc9ae8a-...__insight-query` | PostHog | Run insight queries with breakdowns |
| `mcp__newrelic-eu__run_nrql_query` | NewRelic | NRQL queries against Browser data |

## Workflow

**Language:** Respond in the same language the user uses. Russian prompt = Russian report.

### Step 1: Determine analysis scope

Ask the user (or infer from context) what they need:

| Parameter | Default | Notes |
|-----------|---------|-------|
| Time window | `7 days` | Enough data for p75 to be meaningful |
| Pages | All | Or specific routes like `/horoscope/daily` |
| Comparison | Latest Lighthouse run | Always included per user preference |
| Focus | All CWV | Or specific metric (LCP, CLS, INP, etc.) |

If the user says something like "why is the app slow on Samsung" — scope to Android, all pages, 7 days.

### Step 2: PostHog — data gap note

> **⚠️ Known gap:** My Zodiac AI's PostHog integration (`front/src/boot/posthog.ts`) is
> initialized with `capturePageview: false` (manual SPA tracking) and **does not emit
> `$web_vitals` events**. The `analyticsService` dual-sends custom business events to
> Firebase + PostHog, but CWV measurement is not among them.
>
> **All CWV field data comes from NewRelic Browser (Step 3).** PostHog data is `null` and
> the report will note this gap.
>
> If someone asks to *add* web vitals tracking to PostHog in the future, the integration
> point is `front/src/shared/api/analytics.ts` — add a `reportWebVitals` call that pipes
> to `analyticsService.track('web_vitals', { metric, value, page })`.

Skip to Step 3.

### Step 3: Collect RUM data from NewRelic Browser

Run NRQL queries via `mcp__newrelic-eu__run_nrql_query`. NewRelic Browser agent automatically
captures CWV through the `PageViewTiming` event type.

**Core Web Vitals p75 overall:**
```sql
SELECT
  percentile(largestContentfulPaint, 75) as 'LCP_p75',
  percentile(cumulativeLayoutShift, 75) as 'CLS_p75',
  percentile(interactionToNextPaint, 75) as 'INP_p75',
  percentile(firstContentfulPaint, 75) as 'FCP_p75',
  percentile(firstByte, 75) as 'TTFB_p75',
  count(*) as samples
FROM PageViewTiming
SINCE 7 days ago
```

**Segmentation by OS/browser** (use `userAgentOS` + `userAgentName` — NOT `deviceType`/`operatingSystem`):
```sql
SELECT
  percentile(largestContentfulPaint, 75) as 'LCP_p75',
  percentile(cumulativeLayoutShift, 75) as 'CLS_p75',
  percentile(interactionToNextPaint, 75) as 'INP_p75',
  count(*) as samples
FROM PageViewTiming
WHERE appId = 538822289
SINCE 7 days ago
FACET userAgentOS, userAgentName
ORDER BY samples DESC
LIMIT 15
```

> **Note:** `deviceType` and `operatingSystem` fields exist on `PageViewTiming` but return
> empty results in practice. The correct segmentation fields are `userAgentOS` (e.g. "Android",
> "iPhone", "Windows", "Mac") and `userAgentName` (e.g. "Chrome", "Safari", "Firefox").

**Geographic segmentation** (reveals CDN/network issues):
```sql
SELECT
  percentile(largestContentfulPaint, 75) as 'LCP_p75',
  percentile(cumulativeLayoutShift, 75) as 'CLS_p75',
  percentile(interactionToNextPaint, 75) as 'INP_p75',
  count(*) as samples
FROM PageViewTiming
WHERE appId = 538822289
SINCE 7 days ago
FACET countryCode
ORDER BY LCP_p75 DESC
LIMIT 15
```

**By page URL:**
```sql
SELECT
  percentile(largestContentfulPaint, 75) as 'LCP_p75',
  percentile(cumulativeLayoutShift, 75) as 'CLS_p75',
  percentile(interactionToNextPaint, 75) as 'INP_p75',
  count(*) as samples
FROM PageViewTiming
SINCE 7 days ago
FACET pageUrl
ORDER BY samples DESC
LIMIT 20
```

**Time series for trend detection:**
```sql
SELECT
  percentile(largestContentfulPaint, 75) as 'LCP_p75',
  percentile(cumulativeLayoutShift, 75) as 'CLS_p75'
FROM PageViewTiming
SINCE 7 days ago
TIMESERIES 1 day
```

**JavaScript errors correlated with slow pages:**
```sql
SELECT count(*), average(duration)
FROM JavaScriptError
SINCE 7 days ago
FACET errorMessage, pageUrl
ORDER BY count(*) DESC
LIMIT 10
```

### Step 4: Load Lighthouse synthetic baseline

Read the latest Lighthouse results from `front/.lighthouseci/`:

```bash
ls -t front/.lighthouseci/lhr-*.json 2>/dev/null | head -3
```

Parse each LHR JSON to extract synthetic CWV values:
- `audits.largest-contentful-paint.numericValue` → LCP (ms)
- `audits.cumulative-layout-shift.numericValue` → CLS
- `audits.total-blocking-time.numericValue` → TBT (proxy for INP)
- `audits.first-contentful-paint.numericValue` → FCP (ms)
- `audits.speed-index.numericValue` → SI (ms)

If no LHR files exist, run `pnpm --dir front test:lighthouse 2>&1 | tail -40` and then read the output.

### Step 5: Analyze and classify

For each CWV metric, apply Google's thresholds:

| Metric | Good | Needs Improvement | Poor |
|--------|------|-------------------|------|
| LCP | <= 2500ms | <= 4000ms | > 4000ms |
| CLS | <= 0.1 | <= 0.25 | > 0.25 |
| INP | <= 200ms | <= 500ms | > 500ms |
| FCP | <= 1800ms | <= 3000ms | > 3000ms |
| TTFB | <= 800ms | <= 1800ms | > 1800ms |

Then compute the **synthetic-to-real gap**: `(RUM_p75 - Lighthouse_value) / Lighthouse_value * 100%`.
A gap above 50% is a red flag that lab testing underestimates real-world pain.

Identify the **worst segments**: which device+OS+page combinations have the highest p75 values.

### Step 6: Generate code-level fix suggestions

Based on which metrics fail and which pages are affected, look at the actual codebase for
specific fixes. These are the most common patterns in My Zodiac AI:

**LCP fixes** — check these in order:
1. `front/src/pages/` — is the LCP element loaded lazily when it shouldn't be?
2. Hero images — do they have `fetchpriority="high"` and `loading="eager"`?
3. Font loading — is `font-display: swap` set in CSS?
4. Route chunks — check `front/vite.config.ts` manualChunks for bloated page bundles

**CLS fixes:**
1. Images/videos without explicit `width`/`height` in templates
2. Dynamic content injection above the fold (skeleton loaders missing?)
3. Web font swap causing reflow — check `@font-face` declarations
4. Quasar component layout shifts (QSkeleton usage)

**INP fixes:**
1. Heavy click handlers — look for synchronous work in `@click` handlers
2. Expensive watchers/computed in hot components
3. Large DOM trees on critical pages — `v-for` rendering too many items without virtualization

**FCP/TTFB fixes:**
1. Server response time — check backend endpoint latency via `newrelic-health-check` skill
2. Render-blocking resources in `front/index.html`
3. Unused CSS/JS in initial bundle — run `bundle-analyzer` skill

For each fix, reference the specific file path and line if possible:
```
front/src/pages/horoscope/DailyHoroscopePage.vue:
  Line 45: <img :src="heroImage"> → add fetchpriority="high" width="390" height="260"
```

### Step 7: Generate HTML report

Run the bundled report generator:

```bash
python3 <skill-path>/scripts/generate-rum-report.py \
  --output reports/rum/rum-report-$(date +%Y-%m-%d).html \
  --data /tmp/rum-analysis-data.json
```

Before running, write the collected data to `/tmp/rum-analysis-data.json` with this structure:

```json
{
  "generated_at": "2026-04-03T12:00:00Z",
  "time_window": "7 days",
  "segment_filter": "all devices",
  "posthog": null,
  "posthog_note": "No $web_vitals events in PostHog — all CWV data from NewRelic Browser.",
  "newrelic": {
    "overall": {
      "LCP_p75": 2560, "CLS_p75": 0.121, "INP_p75": 242,
      "FCP_p75": 711,  "TTFB_p75": 0,    "samples": 8218
    },
    "by_device_os": [
      { "deviceType": "userAgentOS value", "operatingSystem": "userAgentName value",
        "LCP_p75": 0, "CLS_p75": 0, "INP_p75": 0, "samples": 0 }
    ],
    "by_page": [
      { "pageUrl": "https://app.my-zodiac-ai.com/...",
        "LCP_p75": 0, "CLS_p75": 0, "INP_p75": 0, "samples": 0 }
    ],
    "by_country": [
      { "countryCode": "BE", "LCP_p75": 0, "CLS_p75": 0, "INP_p75": 0, "samples": 0 }
    ],
    "timeseries": [
      { "date": "Mar 28", "LCP_p75": 0, "CLS_p75": 0 }
    ]
  },
  "lighthouse": {
    "lcp_ms": 2100,
    "cls": 0.04,
    "fcp_ms": 1200,
    "score": 92,
    "source": "front/.lighthouseci/lhr-*.json or front/docs/PERFORMANCE.md fallback"
  },
  "analysis": {
    "worst_segments": [...],
    "worst_pages": [...],
    "fixes": [
      {
        "priority": "critical|high|medium",
        "metric": "LCP|CLS|INP|FCP|TTFB",
        "description": "...",
        "code_snippet": "// file/path.vue\ncode here",
        "expected_impact": "metric X → Y",
        "file_path": "front/src/..."
      }
    ]
  }
}
```

If the script is not available or fails, generate the HTML report inline using the template
structure from `scripts/generate-rum-report.py` as a reference. The report must include:

1. **Executive summary** — overall CWV pass/fail verdict with p75 values
2. **Synthetic vs Real comparison table** — side-by-side Lighthouse vs RUM p75
3. **Device segmentation charts** — bar charts by device type, OS, browser
4. **Page-level breakdown** — table sorted by worst p75 values
5. **Trend sparklines** — 7-day trend for LCP and CLS from NewRelic timeseries
6. **Fix recommendations** — prioritized list with file paths and code snippets
7. **Data quality notes** — sample sizes, data gaps, confidence caveats

Save the report to `reports/rum/rum-report-YYYY-MM-DD.html` (create the directory if needed).

### Step 8: Summarize findings

Present a brief summary to the user with:
- Overall CWV health verdict (all green / some yellow / critical red)
- Top 3 worst segments (e.g., "Android/Chrome on /natal-chart has 4.2s LCP")
- Biggest synthetic-to-real gaps
- Top priority fix with expected impact
- Link to the full HTML report

## Relationship with other skills

| Skill | Focus | When to combine |
|-------|-------|-----------------|
| `lighthouse-audit` | Synthetic lab metrics | RUM skill auto-loads LH data for comparison |
| `newrelic-health-check` | Backend APM metrics | If TTFB is high, suggest running health-check |
| `bundle-analyzer` | JS bundle sizes | If FCP/LCP point to large bundles |
| `performance-audit` | Code-level perf review | For deeper analysis after RUM identifies hot pages |
