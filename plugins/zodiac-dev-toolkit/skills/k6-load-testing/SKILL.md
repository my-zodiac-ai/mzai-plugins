---
name: k6-load-testing
description: >
  Use for ANY k6, load testing, stress testing, or performance testing task in My Zodiac AI.
  Trigger whenever the user wants to: create a k6 scenario, run or configure a
  load/stress/spike/soak/baseline/breakpoint test, compare test runs or detect regressions,
  interpret k6 output (VU, RPS, p95, error rates, 503s), diagnose bottlenecks under concurrency,
  or hunt memory leaks via long-running tests. Also trigger for post-deploy performance validation,
  capacity planning, and correlating load results with Grafana or NewRelic. Triggers on:
  "нагрузочный тест", "под нагрузкой", "прогнать baseline", "сравни прогоны", "stress test",
  "soak тест", "benchmark endpoint", "smoke перед деплоем", "сколько RPS выдержит",
  "compare k6 runs", "создай сценарий нагрузки", "payments flow load test",
  "performance regression", or mentions of k6/results/ — even without saying "k6".
---

# K6 Load Testing — My Zodiac AI

You are managing a mature K6 load testing infrastructure for the My Zodiac AI monorepo.
The project already has 12 scenarios, shared helpers, a Makefile, Grafana+InfluxDB monitoring,
and a results comparison script. Your job is to work *with* this infrastructure, not reinvent it.

## Project layout

```
k6/
├── config/
│   ├── env.js            # ENV vars: BASE_URL, credentials, AI_MOCK, INFLUXDB_URL
│   └── thresholds.js     # SLO thresholds per group + buildThresholds() helper
├── helpers/
│   ├── auth.js           # login(), refreshAccessToken(), authHeaders()
│   ├── checks.js         # checkOk(), check200(), check201(), checkHasKey(), checkLatency()
│   ├── data.js           # randomSign(), randomBirthData(), natalChartPayload(), etc.
│   └── csv-users.js      # pickUserByIndex() for multi-user CSV pools
├── scenarios/            # 12 scenario files (see below)
├── scripts/
│   └── compare-runs.js   # Regression diff: node k6/scripts/compare-runs.js <before> <after>
├── results/              # JSON summaries: {type}-{timestamp}.json
├── grafana/              # Auto-provisioned dashboards + datasources
├── docker-compose.monitoring.yml
├── Makefile              # 13 targets (smoke, baseline, spike, stress, soak, + -with-metrics)
└── data/users.csv        # Multi-tier user pool for payments/tier-limits tests
```

## Existing scenarios

| Scenario | File | Purpose | VU profile | Duration |
|---|---|---|---|---|
| smoke | smoke.js | CI gate — quick sanity check | 5 VU constant | 60s |
| baseline | baseline.js | Pre-release: realistic traffic mix at 100 RPS | 0→50→100→0 | ~9 min |
| spike | spike.js | Morning horoscope push simulation | 10→500→10→0 | ~7 min |
| stress | stress.js | Find breaking point (staging only) | 100→200→...→900→0 | ~21 min |
| soak | soak.js | Memory leak detection | 50 VU constant | 4 hours |
| breakpoint | breakpoint.js | Max sustainable RPS via arrival-rate | 10→500 RPS, steps of 50 | ~20 min |
| payments-flow | payments-flow.js | Full subscription lifecycle | 0→5→10→0 | ~5 min |
| payments-debug | payments-debug.js | Isolated payment endpoint debugging | varies | short |
| ephemeris-cpu | ephemeris-cpu.js | Swiss Ephemeris CPU profiling (western vs vedic) | ramping | ~10 min |
| cache-warmup | cache-warmup.js | Redis cache warm-up validation | low | short |
| notifications-broadcast | notifications-broadcast.js | Push notification broadcast under load | varies | ~5 min |
| tier-limits | tier-limits.js | Rate limiting per subscription tier | multi-user CSV | ~5 min |

## How to create a new K6 scenario

When the user describes an endpoint or flow they want to load test, follow these steps:

### 1. Understand the target

Ask (or infer from context) these details:
- Which endpoint(s)? Method + path (e.g., `GET /api/v1/astrology/transits/daily`)
- Auth required? (most endpoints need Bearer token — use `login()` + `authHeaders()`)
- Request body? (for POST/PUT — build a payload generator in data.js or inline)
- What load profile? (smoke for CI, baseline for pre-release, spike/stress/soak for deep testing)
- SLO expectations? (default: p95 < 1000ms, error rate < 1% — override per group from thresholds.js)

### 2. Write the scenario file

Place it in `k6/scenarios/{name}.js`. Follow the established pattern from existing scenarios:

```javascript
// Required structure for every scenario:
import http from 'k6/http';
import { group, sleep } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';  // as needed

import { BASE_URL, ENV } from '../config/env.js';
import { buildThresholds } from '../config/thresholds.js';
import { login, authHeaders } from '../helpers/auth.js';
import { checkOk, checkHasKey } from '../helpers/checks.js';

// 1. Custom metrics (Trend for latency, Rate for success, Counter for errors)
// 2. export const options = { scenarios: { ... }, thresholds: buildThresholds(...), tags: { scenario: 'name' } }
// 3. export function setup() — login once, return shared state
// 4. export default function(data) — main VU logic with group() blocks
// 5. export function handleSummary(data) — write JSON to k6/results/{name}-{timestamp}.json
```

Key conventions to follow:
- Use `group('name', () => { ... })` to segment requests — thresholds reference these group names
- Tag every request: `{ headers, tags: { group: 'groupname' } }`
- Use `sleep(Math.random() * 2 + 1)` for realistic think time
- Use `checkOk()` / `check200()` / `checkHasKey()` from helpers — don't write raw `check()` calls
- handleSummary must output: `k6/results/{scenario}-{timestamp}.json` with structure:
  ```json
  { "testType": "name", "timestamp": "ISO", "result": "PASS|FAIL", "metrics": { ... } }
  ```

### 3. Add a Makefile target

Add both plain and `-with-metrics` variants:

```makefile
{name}: results-dir
	$(K6) run --env BASE_URL=$(BASE_URL) $(OUT_FLAGS) k6/scenarios/{name}.js

{name}-with-metrics: results-dir
	$(K6) run --env BASE_URL=$(BASE_URL) --out influxdb=$(INFLUXDB_URL) k6/scenarios/{name}.js
```

Add the target names to the `.PHONY` list at the top.

### 4. Add thresholds (if needed)

If the endpoint has unique SLO requirements, add a new group to `k6/config/thresholds.js`:

```javascript
mygroup: {
  'http_req_duration{group:mygroup}': ['p(95)<500', 'p(99)<1000'],
  'http_req_failed{group:mygroup}':   ['rate<0.005'],
},
```

### 5. Add test data helpers (if needed)

If the endpoint needs specific payloads, add generator functions to `k6/helpers/data.js`.
Keep them randomized to avoid cache effects unless you specifically want cache testing.

## Running tests

The user may ask to run a specific test or choose a profile. Here's how to guide them:

| Goal | Command |
|---|---|
| Quick CI check | `make smoke` or `k6 run k6/scenarios/smoke.js` |
| Pre-release validation | `make baseline BASE_URL=https://staging.myzodiacai.com` |
| Test spike resilience | `make spike BASE_URL=https://staging.myzodiacai.com` |
| Find breaking point | `make stress BASE_URL=https://staging.myzodiacai.com` (staging only!) |
| Memory leak hunt | `make soak BASE_URL=https://staging.myzodiacai.com` (needs monitoring stack) |
| With Grafana dashboards | `make monitoring-up && make baseline-with-metrics` |

Environment variables: `BASE_URL`, `TEST_EMAIL`, `TEST_PASSWORD`, `AI_MOCK` (default true),
`INFLUXDB_URL`. Pass via `--env` or Makefile args.

## Parsing and comparing results

### Reading a single result

Results are in `k6/results/` as JSON files. The structure is:
```json
{
  "testType": "baseline",
  "timestamp": "2026-03-14T22:07:36.300Z",
  "result": "PASS",
  "metrics": {
    "errorRate": "0.12%",
    "p95Latency": "287ms",
    "p99Latency": "512ms",
    "avgRPS": "15.2",
    "totalRequests": 8234,
    "cacheHitRate": "92.3%"
  }
}
```

### Comparing two runs

Use the built-in comparison script:
```bash
node k6/scripts/compare-runs.js k6/results/baseline-before.json k6/results/baseline-after.json
```

Exit codes: 0 = no regression, 1 = WARN (p95 +10–20%), 2 = FAIL (>20% or error rate up).
The script compares: p95, p99, avg, median latency, error rate, RPS, cache hit rate,
and scenario-specific metrics (chart p95, breakpoint error, ephemeris latency).

### Finding the latest runs

To compare the most recent two runs of the same type:
```bash
ls -t k6/results/baseline-*.json | head -2
```

### Generating a report

When the user asks for a report after a test run, produce a structured markdown report:

1. **Summary**: PASS/FAIL, test type, timestamp, target URL
2. **Key metrics**: error rate vs SLO, p95/p99 vs thresholds, RPS, cache hit rate
3. **Comparison** (if previous run exists): delta table from compare-runs.js
4. **Bottleneck analysis**: identify which group(s) are slowest, which are closest to SLO limits
5. **Recommendations**: specific actionable items (add caching, increase pool size, optimize query, etc.)

Save reports to `k6/results/reports/` with naming: `report-{type}-{date}.md`.

## NewRelic correlation

When the `newrelic-health-check` skill is available or `mcp__newrelic-eu__run_nrql_query` tool exists,
correlate K6 results with production metrics:

- Compare K6 p95 latency with NewRelic `Apdex` and `HttpDispatcher` response times
- Check if error rate spike in K6 matches NewRelic error rate for the same time window
- Look for infrastructure signals: CPU saturation, memory pressure, MongoDB slow queries

Example NRQL for correlation:
```sql
SELECT average(duration), percentile(duration, 95, 99)
FROM Transaction
WHERE appName = 'my-zodiac-ai-backend'
SINCE 30 minutes ago
FACET name
```

## Load profile selection guide

Help users choose the right profile based on their goal:

| User says | Recommended profile | Why |
|---|---|---|
| "quick check before deploy" | smoke | 60s, CI-friendly, abortOnFail |
| "validate the release" | baseline | Realistic traffic mix, 9 min |
| "morning push simulation" | spike | Tests BullMQ + Redis under burst |
| "how much can it handle" | stress or breakpoint | stress = VU-based, breakpoint = RPS-based |
| "overnight stability" | soak | 4h, finds memory leaks + latency creep |
| "test the new endpoint" | Create a new scenario | Tailored to the specific endpoint |
| "payment flow under load" | payments-flow | Full subscription lifecycle |
| "chart calculation perf" | ephemeris-cpu | CPU-bound profiling, western vs vedic |

## Common pitfalls to warn about

- **Never run stress/breakpoint on production** — these are designed to find the breaking point
- **AI_MOCK=true by default** — real AI calls are expensive and rate-limited; disable explicitly
- **Login rate limiting** — 5/min per user; use setup() to pre-login and share tokens across VUs
- **Soak tests need monitoring stack** — `make monitoring-up` first, otherwise you can't see memory trends
- **handleSummary JSON format** — always include testType, timestamp, result, metrics; compare-runs.js depends on this
