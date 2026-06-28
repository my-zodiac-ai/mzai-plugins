---
name: newrelic-dashboard-builder
description: >
  Build NewRelic dashboards, write NRQL queries, create alert policies, and define SLI/SLO
  monitors for My Zodiac AI. Use this skill whenever the user wants to CREATE or GENERATE any
  NewRelic monitoring artifact — dashboards, widgets, dashboard JSON, NRQL queries, alert
  conditions, or SLO targets with error budgets. Triggers on: building or generating dashboards,
  writing or composing NRQL, setting up SLO/SLI monitoring, defining alert thresholds, creating
  NerdGraph-compatible JSON, tracking metrics over time in dashboard form, visualizing funnels
  or trends as dashboard widgets, or generating deployment correlation reports. Also triggers for
  explicit Russian equivalents: создать дашборд, написать NRQL запрос, настроить SLO, создать
  алерт, какой NRQL запрос. This skill BUILDS persistent monitoring artifacts — dashboards,
  alerts, SLOs you can save and reuse. It does NOT do one-time health checks or post-deploy
  metric checks — use newrelic-health-check for those.
x-scope: adapter:observability
x-stack: any
---

# NewRelic Dashboard Builder

Build dashboards, NRQL queries, alerts, and SLO monitors for the My Zodiac AI production stack.

**Language:** Always respond in English for dashboard names, widget titles, and NRQL. Explanatory text follows the user's language.

---

## Available tools

| Tool | Purpose |
|------|---------|
| `mcp__newrelic-eu__list_applications` | List APM apps to get names and IDs |
| `mcp__newrelic-eu__get_metrics` | Quick summary metrics for an app |
| `mcp__newrelic-eu__run_nrql_query` | Execute arbitrary NRQL — use to validate queries before exporting |

These are your primary interface to NewRelic. The project uses the **EU region** (`api.eu.newrelic.com`), account ID **${NEW_RELIC_ACCOUNT_ID}**.

---

## Project context

My Zodiac AI has three monitored app entities:

| App name | Type | Notes |
|----------|------|-------|
| `My_Zodiac_AI_prod` | APM (NestJS backend) | Transaction, TransactionError, Metric, Log, LlmChatCompletionSummary |
| `MyZodiacFront` | Browser (Vue 3 SPA) | PageView, JavaScriptError, AjaxRequest |
| `MZAI_iOS-ios` | Mobile (Capacitor iOS) | MobileSession, Mobile, MobileCrash |

Key custom events emitted by the backend: `user_registered`, `subscription_created`, `horoscope_generated`, `ai_chat_completed`.

Refer to `references/nrql-patterns.md` for a library of proven NRQL queries organized by domain.

---

## Workflow modes

This skill supports five distinct workflows. Identify which one the user needs and follow the corresponding steps.

### Mode 1: NRQL Query Builder

When the user describes a metric in plain language, translate it to valid NRQL.

**Steps:**
1. Identify the target event type (Transaction, PageView, Metric, custom event, etc.)
2. Identify the aggregation (count, average, percentile, uniqueCount, rate, etc.)
3. Identify filters (appName, time window, WHERE clauses)
4. Identify grouping (FACET) and ordering if needed
5. Determine visualization hint (timeseries, facet, scalar)
6. Write the NRQL query
7. **Validate** — run the query via `run_nrql_query` to confirm it returns data
8. If validation fails, diagnose (wrong event type? missing attribute?) and fix

**Output format:**
```
### NRQL Query: {description}

\`\`\`sql
{the NRQL query}
\`\`\`

**Event type:** {Transaction | PageView | ...}
**Visualization:** {billboard | line | area | bar | pie | table}
**Validated:** {Yes — returned N rows | No — {reason}}
```

**Common pitfalls to avoid:**
- `LlmChatCompletionSummary` uses backtick-quoted attributes like `` `response.usage.total_tokens` ``
- Mobile events use `appName = 'MZAI_iOS-ios'` not the backend name
- Custom events (user_registered, etc.) are lowercase with underscores
- Always include `WHERE appName = '...'` to scope queries to the right app
- Use `TIMESERIES {bucket}` for line/area charts, omit it for billboards and tables
- `SINCE` accepts relative times like `7 days ago`, `1 hour ago`, `today`
- **`httpResponseCode` is NOT populated** in this setup — use `error IS true/false` instead of `httpResponseCode >= 500` for availability/error queries
- MongoDB driver metrics (`mongodb.driver.commands.duration`, `mongodb.connections.*`) may return null if the agent isn't reporting — note this gracefully in output

### Mode 2: Dashboard Generator

When the user wants a complete dashboard, generate NerdGraph-compatible JSON.

**Steps:**
1. Clarify the dashboard's purpose and audience (ops, business, dev)
2. Plan the page layout — dashboards can have multiple pages, each page is a 12-column grid
3. For each widget, determine: title, visualization type, NRQL query, grid position (column, row, width, height)
4. Validate each NRQL query via `run_nrql_query`
5. Assemble the dashboard JSON
6. Save to a file the user can import

**Grid layout rules:**
- 12 columns wide, rows are auto-extended
- Default widget sizes: billboard 3x3, line/area 6x3, table 12x4, bar 6x3, pie 4x3
- Row 1 = key billboards (KPIs at a glance)
- Row 2+ = timeseries showing trends
- Bottom rows = detail tables
- Group related widgets visually

**Dashboard JSON structure:**
```json
{
  "name": "Dashboard Name",
  "permissions": "PUBLIC_READ_WRITE",
  "pages": [
    {
      "name": "Page Name",
      "widgets": [
        {
          "title": "Widget Title",
          "layout": { "column": 1, "row": 1, "width": 3, "height": 3 },
          "visualization": { "id": "viz.billboard" },
          "rawConfiguration": {
            "nrqlQueries": [
              { "accountId": ${NEW_RELIC_ACCOUNT_ID}, "query": "SELECT ..." }
            ],
            "thresholds": [
              { "alertSeverity": "WARNING", "value": 5 },
              { "alertSeverity": "CRITICAL", "value": 10 }
            ]
          }
        }
      ]
    }
  ]
}
```

**Visualization IDs:** `viz.billboard`, `viz.line`, `viz.area`, `viz.bar`, `viz.pie`, `viz.table`, `viz.markdown`, `viz.heatmap`, `viz.histogram`, `viz.json`, `viz.stacked-bar`

**Thresholds** are optional and apply to billboard widgets — they color the value green/yellow/red.

After generating, save the JSON file and provide the NerdGraph mutation the user can run to create it:

```graphql
mutation CreateDashboard($accountId: Int!, $dashboard: DashboardInput!) {
  dashboardCreate(accountId: $accountId, dashboard: $dashboard) {
    entityResult { guid name }
    errors { description type }
  }
}
```

### Mode 3: Alert Policy Builder

When the user wants to set up alerts for specific conditions.

**Steps:**
1. Understand what condition to alert on (error rate spike, slow response, queue depth, etc.)
2. Determine threshold type: static, baseline (anomaly), or outlier
3. Define the NRQL condition query
4. Set warning and critical thresholds
5. Define evaluation window (how long the condition must be true)
6. Validate the NRQL via `run_nrql_query`
7. Output the alert condition configuration

**Alert condition JSON structure:**
```json
{
  "policy_name": "My Zodiac AI — Production Alerts",
  "conditions": [
    {
      "name": "High Error Rate",
      "type": "static",
      "nrql": "SELECT percentage(count(*), WHERE error IS true) FROM Transaction WHERE appName = 'My_Zodiac_AI_prod'",
      "critical": { "threshold": 7, "duration_minutes": 5, "operator": "above" },
      "warning": { "threshold": 3, "duration_minutes": 5, "operator": "above" },
      "fill_option": "last_value",
      "aggregation_window": 60,
      "slide_by": 30
    }
  ]
}
```

**Standard alert conditions for My Zodiac AI** (reference these when the user asks for "standard" or "production" alerts):

| Condition | NRQL | Warning | Critical |
|-----------|------|---------|----------|
| High Error Rate | `SELECT percentage(count(*), WHERE error IS true) FROM Transaction WHERE appName = 'My_Zodiac_AI_prod'` | >3% for 5min | >7% for 5min |
| Slow Response Time | `SELECT average(duration) FROM Transaction WHERE appName = 'My_Zodiac_AI_prod'` | >2s for 5min | >5s for 3min |
| 5xx Errors Spike | `SELECT count(*) FROM Transaction WHERE appName = 'My_Zodiac_AI_prod' AND error IS true` | >10 in 5min | >30 in 5min |
| Slow DB Queries | `SELECT average(mongodb.driver.commands.duration) * 1000 FROM Metric WHERE appName = 'My_Zodiac_AI_prod'` | >50ms | >100ms |
| High Queue Depth | `SELECT latest(queue.depth) FROM Metric WHERE appName = 'My_Zodiac_AI_prod'` | >500 | >1000 |
| LLM Latency | `SELECT average(duration) FROM LlmChatCompletionSummary WHERE appName = 'My_Zodiac_AI_prod'` | >5s | >15s |

### Mode 4: Deployment Correlation

When the user wants to see how a deployment affected metrics.

**Steps:**
1. Identify the deployment time or marker
2. Build comparison queries: `SINCE {deploy_time}` vs `UNTIL {deploy_time} SINCE {window_before}`
3. Run both windows via `run_nrql_query`
4. Calculate deltas (response time change, error rate change, throughput change)
5. Present a before/after comparison table
6. If degradation detected, flag the affected metrics

**Output format:**
```
## Deployment Impact: {deploy description}
**Deployed at:** {timestamp}
**Compared:** {window_after} after vs {window_before} before

| Metric | Before | After | Delta | Verdict |
|--------|--------|-------|-------|---------|
| Response Time | 320ms | 450ms | +41% | WARN |
| Error Rate | 1.2% | 1.5% | +0.3pp | PASS |
| Throughput | 52 rpm | 48 rpm | -8% | PASS |
```

### Mode 5: SLI/SLO Monitor

When the user wants to define Service Level Indicators and Objectives.

**Steps:**
1. Identify the service boundary (which app or endpoint)
2. Define the SLI — typically a ratio of good events to total events
3. Set the SLO target (e.g., 99.9% over 30 days)
4. Calculate the error budget
5. Build the NRQL queries for tracking
6. Generate a dashboard page for SLO monitoring

**Common SLI patterns for My Zodiac AI:**

| SLI | Good Events | Total Events | Typical SLO |
|-----|------------|--------------|-------------|
| Availability | `WHERE error IS false` | All transactions | 99.9% / 30d |
| Latency | `WHERE duration < 1` | All transactions | 99% / 30d |
| LLM Success | `WHERE error IS false` | LlmChatCompletionSummary | 99.5% / 30d |
| Mobile Crash-Free | Sessions without crash | All sessions | 99.5% / 7d |

> **Note:** `httpResponseCode` is not populated in this NR setup. Always use `error IS true/false` for availability SLIs.

**SLI NRQL template:**
```sql
SELECT
  percentage(count(*), WHERE {good_condition}) AS 'SLI %',
  count(*) AS 'Total Events',
  filter(count(*), WHERE NOT ({good_condition})) AS 'Bad Events'
FROM {event_type}
WHERE appName = '{app_name}'
SINCE 30 days ago
```

**Error budget NRQL:**
```sql
SELECT
  (1 - {slo_target}) * count(*) AS 'Error Budget (events)',
  filter(count(*), WHERE NOT ({good_condition})) AS 'Budget Consumed',
  ((1 - {slo_target}) * count(*) - filter(count(*), WHERE NOT ({good_condition}))) AS 'Budget Remaining'
FROM {event_type}
WHERE appName = '{app_name}'
SINCE 30 days ago
```

**SLO dashboard page** should include:
- Billboard: Current SLI % (with threshold at SLO target)
- Billboard: Error Budget Remaining %
- Line: SLI % over time (TIMESERIES 1 day)
- Line: Error Budget burn rate (TIMESERIES 1 day)
- Table: Worst endpoints contributing to SLI violations

---

## Output file conventions

Save generated files to the project with clear naming:

| Output | Path |
|--------|------|
| Dashboard JSON | `scripts/nr-dashboards/{dashboard-slug}.json` |
| Alert config | `scripts/nr-alerts/{policy-slug}.json` |
| SLO definition | `scripts/nr-slo/{sli-slug}.json` |
| NRQL collection | `scripts/nr-queries/{collection-slug}.nrql` |

Always create the directory if it doesn't exist.

---

## Quality checklist

Before presenting any output, verify:

- [ ] Every NRQL query was validated via `run_nrql_query` (or explain why not)
- [ ] Dashboard widgets don't overlap (grid positions are correct)
- [ ] Billboard widgets have meaningful thresholds where applicable
- [ ] Timeseries queries include `TIMESERIES {bucket}` clause
- [ ] All queries scope to the correct `appName`
- [ ] Alert conditions have both warning and critical thresholds
- [ ] SLO targets are expressed as decimals in calculations (99.9% = 0.999)

---

## Relationship with other skills

- **newrelic-health-check**: Focuses on point-in-time health assessment (PASS/WARN/FAIL). Use *this* skill instead when the user wants to *build* persistent dashboards, alerts, or SLOs — not just run a quick check.
- **deploy-checklist / release-workflow**: After building alerts and dashboards with this skill, reference them in deploy checklists for post-deploy verification.
