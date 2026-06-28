---
name: metrics-analysis
description: >
  Analyze metrics, user data, and business impact for a feature decision.
  Use when the user asks "метрики фичи", "impact analysis", "какой будет эффект",
  "стоит ли делать", "ROI of feature", "monetization potential",
  or needs data-driven insights to decide on a feature.
x-scope: domain:astrology
x-stack: any
---

# Metrics & Impact Analysis

> **Domain plugin (astrology research).** If your environment provides a general `metrics-analysis` / `metrics-review` skill, use it for the generic method; this skill adds the astrology-app specifics (domain competitors, domain UX, monetization angles).

Analyze available metrics and estimate business impact of implementing a feature
in My Zodiac AI.

## Process

### 1. Gather Current Metrics

**From PostHog (if MCP available):**
Use PostHog MCP tools to query:
- DAU, WAU, MAU trends (last 30/90 days)
- Key user flows and conversion funnels
- Feature usage patterns (which existing features are most used)
- Retention curves (D1, D7, D30)
- Session duration and frequency
- User segments and cohorts
- Events related to the feature area (if any similar feature exists)

Useful PostHog queries:
- insight/trend queries for trends and funnels
- cohort listing for user segments
- event-definition listing for available events
- property listing for user properties

**From MongoDB (if MCP available):**
Use MongoDB MCP tools to understand:
- User collection schema and counts
- Relevant data that could power the feature
- User preferences and settings patterns
- Content/data that already exists and could be reused

**If MCP not available:**
- Note the data gap explicitly
- Use industry benchmarks from web research
- Search for: `astrology app metrics benchmarks 2025`

### 2. Market & Industry Benchmarks

Use WebSearch to find:
- `astrology app retention rates`
- `[feature] impact on app engagement`
- `[feature] monetization mobile app`
- `spiritual wellness app ARPU`
- Industry reports on feature adoption rates

### 3. Impact Estimation

**Engagement Impact:**
- Expected change in DAU/MAU ratio
- Expected change in session duration
- Expected change in sessions per week
- New user acquisition potential (ASO, word-of-mouth)

**Retention Impact:**
- Expected improvement in D7/D30 retention
- Sticky factor potential (daily habit formation)
- Churn reduction potential

**Monetization Impact:**
- Pricing model recommendation (free/freemium/premium)
- Competitor pricing benchmarks
- Expected conversion rate impact
- ARPU change estimation
- Revenue projection (conservative/moderate/optimistic)

### 4. Risk-Adjusted Assessment

| Factor | Score (1-10) | Weight | Notes |
|--------|-------------|--------|-------|
| User demand signal | | 30% | Reviews, requests, competitor adoption |
| Revenue potential | | 25% | Monetization opportunity |
| Retention impact | | 20% | Keeps users coming back? |
| Development cost | | 15% | Effort vs team capacity |
| Strategic alignment | | 10% | Fits product vision? |
| **Weighted Total** | | 100% | |

### 5. Recommendation

Provide a clear verdict:
- **BUILD** — strong signals, clear ROI
- **EXPERIMENT** — promising but uncertain, suggest MVP/A-B test
- **DEFER** — interesting but not now, specify conditions to revisit
- **SKIP** — weak signals, better alternatives exist

Include suggested success metrics and how to measure them post-launch.

## Rules

- Use REAL data from PostHog/MongoDB when available — don't make up numbers
- Clearly distinguish actual metrics from estimates/benchmarks
- Be honest about data gaps
- Include confidence levels on projections (low/medium/high)
- Consider cannibalization — could this feature hurt existing features?
- Think about maintenance cost, not just build cost
