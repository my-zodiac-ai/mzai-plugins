---
name: load-testing
description: >
  Use for ANY k6, load testing, stress testing, or performance testing task. Trigger whenever
  the user wants to: create a k6 scenario, run or configure a load/stress/spike/soak/baseline/
  breakpoint test, compare test runs or detect regressions, interpret k6 output (VU, RPS, p95,
  error rates, 503s), diagnose bottlenecks under concurrency, or hunt memory leaks via long-running
  tests. Also for post-deploy performance validation, capacity planning, and correlating load
  results with an APM. Triggers: "нагрузочный тест", "под нагрузкой", "прогнать baseline",
  "сравни прогоны", "stress test", "soak тест", "benchmark endpoint", "smoke перед деплоем",
  "сколько RPS выдержит", "compare k6 runs", "создай сценарий нагрузки", "performance regression",
  or mentions of k6/results/ — even without saying "k6".
x-scope: core
x-stack: any
---

# k6 Load Testing

Stack-agnostic k6 method. Discover the project's existing k6 setup first
(`find . -path '*k6*' -name '*.js'`, a `Makefile`/`package.json` with k6 targets, a
`k6/results/` dir) and work *with* it rather than reinventing. If there's no setup, scaffold the
minimal structure (`config/`, `helpers/`, `scenarios/`, `results/`).

## Test types

| Type | Goal | Typical VU/RPS profile |
|------|------|------------------------|
| smoke | CI sanity gate | few VUs, ~60s, abort on fail |
| baseline | realistic pre-release traffic | ramp to target RPS, hold, ramp down |
| spike | burst resilience | low → very high → low quickly |
| stress | find the breaking point (staging only) | step VUs up until failure |
| soak | memory leaks / latency creep | moderate VUs held for hours |
| breakpoint | max sustainable RPS | arrival-rate ramp in steps |

## Create a scenario

1. **Understand the target:** endpoint(s) + method/path, auth (Bearer? pre-login in `setup()`),
   request body (build a randomized generator to avoid cache effects), load profile, and SLOs
   (default p95 < 1000ms, error rate < 1%).
2. **Write `scenarios/{name}.js`** with this structure:

```javascript
import http from 'k6/http';
import { group, sleep } from 'k6';
import { Trend, Rate, Counter } from 'k6/metrics';     // as needed
import { BASE_URL } from '../config/env.js';
import { buildThresholds } from '../config/thresholds.js';
import { login, authHeaders } from '../helpers/auth.js';
import { checkOk } from '../helpers/checks.js';

export const options = {
  scenarios: { /* executor config */ },
  thresholds: buildThresholds('mygroup'),
  tags: { scenario: 'name' },
};
export function setup() { /* login once, return shared tokens/state */ }
export default function (data) {
  group('mygroup', () => {
    const res = http.get(`${BASE_URL}/path`, { headers: authHeaders(data), tags: { group: 'mygroup' } });
    checkOk(res);
    sleep(Math.random() * 2 + 1);   // realistic think time
  });
}
export function handleSummary(data) {
  // write results/{name}-{timestamp}.json -> { testType, timestamp, result: 'PASS|FAIL', metrics }
}
```

Conventions: segment requests with `group()` (thresholds reference group names); tag every request;
use shared `check*` helpers, not raw `check()`; pre-login in `setup()` to dodge auth rate limits;
emit a stable `handleSummary` JSON so a comparison script can diff runs.

3. **Thresholds:** add per-group SLOs in `config/thresholds.js`:
```javascript
mygroup: {
  'http_req_duration{group:mygroup}': ['p(95)<500', 'p(99)<1000'],
  'http_req_failed{group:mygroup}':   ['rate<0.005'],
}
```

## Run

Prefer the repo's Makefile/scripts (read them); otherwise `k6 run`:
```bash
k6 run k6/scenarios/smoke.js
k6 run --env BASE_URL=https://staging.example.com k6/scenarios/baseline.js
k6 run --out influxdb=$INFLUXDB_URL k6/scenarios/baseline.js   # with dashboards
```
Common env: `BASE_URL`, `TEST_EMAIL`/`TEST_PASSWORD`, `INFLUXDB_URL`.

## Compare runs & report

Results live in `k6/results/*.json`. To detect regressions, diff the latest two summaries of the
same type (a `compare-runs.js`-style script): compare p95/p99/median, error rate, RPS, and any
scenario-specific metrics. Suggested exit codes: 0 = no regression, 1 = WARN (p95 +10–20%),
2 = FAIL (>20% or error rate up).

```bash
ls -t k6/results/baseline-*.json | head -2     # newest two of a type
```

Report (when asked): Summary (PASS/FAIL, type, timestamp, target) → Key metrics vs SLO →
Comparison delta vs previous → Bottleneck analysis (slowest groups, closest to SLO) →
Recommendations. Save to `k6/results/reports/report-{type}-{date}.md`.

## APM correlation

If an APM/MCP is available, correlate k6 results with production: compare k6 p95 with the APM's
response-time percentiles for the same window; check whether a k6 error spike matches the APM's
error rate; look for CPU saturation, memory pressure, slow DB queries. Read account/app IDs from
config placeholders (e.g. `${APM_ACCOUNT_ID}`, `${APP_NAME}`), never hardcode them.

## Pitfalls

- **Never run stress/breakpoint against production** — they exist to find the breaking point.
- **Mock expensive 3rd-party calls** (e.g. an `AI_MOCK=true` flag) — real calls are costly/rate-limited.
- **Auth rate limits** — pre-login in `setup()` and share tokens across VUs.
- **Soak needs monitoring** — bring up the metrics stack first or you can't see memory trends.
- **Stable `handleSummary` shape** — the comparison script depends on it.

---

## Example: My Zodiac AI k6 infrastructure

Illustrative only — a mature setup this skill was extracted from. Detect the real layout per the
discovery step above.

Layout: `k6/{config,helpers,scenarios,scripts,results,grafana}` + `Makefile` +
`docker-compose.monitoring.yml` + `data/users.csv`. Helpers include domain payload generators
(`randomSign()`, `randomBirthData()`, `natalChartPayload()`) and a `compare-runs.js` script.

Scenarios (12): smoke, baseline, spike ("morning horoscope push"), stress, soak, breakpoint,
payments-flow, payments-debug, `ephemeris-cpu` (Swiss Ephemeris CPU profiling, western vs vedic),
cache-warmup, notifications-broadcast, tier-limits (per-subscription rate limits via CSV pool).

Make targets: `make smoke`, `make baseline BASE_URL=https://staging.myzodiacai.com`,
`make monitoring-up && make baseline-with-metrics`.

APM correlation NRQL (NewRelic):
```sql
SELECT average(duration), percentile(duration, 95, 99)
FROM Transaction WHERE appName = '${APP_NAME}' SINCE 30 minutes ago FACET name
```
