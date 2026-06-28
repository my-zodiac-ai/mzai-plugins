---
name: competitor-analysis
description: >
  Analyze competitors implementing a specific feature in astrology and wellness apps.
  Use when the user asks "анализ конкурентов", "competitor analysis", "кто это уже делает",
  "как у конкурентов", "what do competitors do", or wants to understand the competitive
  landscape for a specific feature.
x-scope: domain:astrology
x-stack: any
---

# Competitor Analysis

> **Domain plugin (astrology research).** If your environment provides a general `competitor-analysis` / `competitive-brief` skill, use it for the generic method; this skill adds the astrology-app specifics (domain competitors, domain UX, monetization angles).

Perform a thorough competitive analysis for the requested feature in the context of
astrology, horoscope, and wellness apps.

## Process

### 1. Identify Competitors

Use WebSearch to find:

**Direct competitors** (astrology/horoscope apps):
- Co-Star, The Pattern, TimePassages, Astro Future, Sanctuary
- Horos, Daily Horoscope, AstroSage, Yodha
- Search for: `"[feature name]" astrology app` and `"[feature name]" horoscope app`

**Indirect competitors** (wellness/spiritual apps with this feature):
- Headspace, Calm, Insight Timer (if feature is meditation-adjacent)
- Numerology apps, tarot apps, moon phase apps
- Search for: `best [feature name] app 2025 2026`

**Non-obvious inspiration** (apps outside the category with excellent implementation):
- Search for: `best [feature name] UX mobile app`

### 2. Analyze Each Competitor

For each competitor found, document:

| Field | Details |
|-------|---------|
| App Name | Full name |
| Platforms | iOS / Android / Web |
| Feature Implementation | How exactly they do it — screens, depth, data sources |
| Entry Point | Where in the app UX the feature is accessible |
| Monetization | Free / Freemium / Premium-only / Subscription tier |
| Price | Specific pricing if premium |
| User Reviews | Search App Store / Play Store reviews mentioning this feature |
| Rating | Overall app rating |
| Strengths | What they do well |
| Weaknesses | Gaps, complaints, missing aspects |

### 3. Synthesize Findings

Produce:
- **Comparison table** — side-by-side of top 5-7 competitors
- **Market gaps** — what nobody does well yet
- **Best practices** — consensus patterns across competitors
- **Differentiation opportunities** — where My Zodiac AI can stand out
- **Monetization benchmarks** — pricing patterns in the market

## Rules

- Search the web — do NOT rely on training data for competitor info
- Include specific URLs and sources
- Focus on mobile implementations (My Zodiac AI is mobile-first via Capacitor)
- Note the date of information (apps change frequently)
- If a competitor doesn't have the feature, note that too — it's a market gap
