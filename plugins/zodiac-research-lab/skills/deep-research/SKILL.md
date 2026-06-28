---
name: deep-research
description: >
  Orchestrate a comprehensive deep feature research for My Zodiac AI. Use when the user asks to
  "research a feature", "deep research", "исследуй фичу", "проанализируй фичу",
  "нужно добавить [feature]", "мега-анализ", "полный ресерч", or describes a new feature idea
  that needs thorough analysis before implementation. This is the main entry point that
  coordinates all research dimensions.
x-scope: domain:astrology
x-stack: any
---

# Deep Feature Research — Orchestrator

This is the main orchestrator skill. When triggered, run a comprehensive multi-dimensional
analysis of the requested feature for the My Zodiac AI project.

## Workflow

### Step 1: Clarify the Feature

Ask the user using AskUserQuestion:
- What feature to research (if not already clear from the prompt)
- Priority dimensions (or run all by default):
  - Competitor analysis
  - UI/UX patterns
  - Tech stack & libraries
  - Codebase integration points
  - Metrics & impact assessment
  - User stories & risk assessment

### Step 2: Launch Parallel Research Agents

Launch these agents **in parallel** using the Agent tool to maximize speed:

1. **market-researcher** agent — competitor analysis + metrics/monetization research
2. **ux-researcher** agent — UI/UX patterns, best implementations, flow analysis
3. **tech-researcher** agent — libraries, APIs, packages, codebase integration analysis

Provide each agent with:
- The feature description from the user
- The project context: My Zodiac AI is an astrology app (NestJS + Vue 3 + Quasar + Capacitor mobile)
- Instruction to use WebSearch for external research
- Instruction to use PostHog MCP tools for real metrics (if available)
- Instruction to use MongoDB MCP tools for user data insights (if available)
- Instruction to analyze the codebase at `the project working directory (repo root)`

### Step 3: Compile the Report

After all agents complete, synthesize their findings into a single Markdown report with this structure:

```markdown
# Deep Research: [Feature Name]

> Generated: [date] | Project: My Zodiac AI

## Executive Summary
2-3 paragraph overview of findings and top recommendation.

## 1. Competitor Analysis
### 1.1 Direct Competitors
Table: App | Feature Implementation | Strengths | Weaknesses | Monetization
### 1.2 Indirect Competitors / Inspiration
Apps outside astrology that implement this feature well.
### 1.3 Market Gaps & Opportunities

## 2. UI/UX Analysis
### 2.1 Best Patterns Found
Screenshots descriptions, flow breakdowns, interaction patterns.
### 2.2 Recommended Approach for My Zodiac AI
Specific UI/UX recommendation with rationale.
### 2.3 User Flow Diagram
Mermaid or text-based flow diagram.

## 3. Technical Analysis
### 3.1 Top Libraries & Tools
Table: Library | Stars/Downloads | License | Pros | Cons | Fits Our Stack?
### 3.2 API & Data Sources
Available APIs, data providers, accuracy considerations.
### 3.3 Recommended Tech Stack
Specific recommendation with integration notes.

## 4. Codebase Integration
### 4.1 Current Architecture Overview
Relevant existing modules, services, patterns.
### 4.2 Integration Points
Where exactly to add this feature (backend modules, frontend pages/components).
### 4.3 Dependencies & Conflicts
What existing code needs modification, potential breaking changes.
### 4.4 Effort Estimate
T-shirt sizing with breakdown.

## 5. Metrics & Impact
### 5.1 Current Baseline Metrics
Real data from PostHog if available (DAU, retention, engagement).
### 5.2 Expected Impact
Projected impact on retention, engagement, monetization.
### 5.3 Monetization Potential
Free vs premium, pricing benchmarks from competitors.

## 6. User Stories & Risks
### 6.1 User Stories
As a [persona], I want [feature] so that [benefit].
### 6.2 Risk Assessment
Table: Risk | Probability | Impact | Mitigation
### 6.3 Open Questions

## 7. Recommendation
Final go/no-go recommendation with priority and suggested timeline.
```

### Step 4: Save and Present

Save the report to the user's workspace folder as `research-[feature-name]-[date].md`.
Present a brief summary in the chat with a link to the full report.

## Important Rules

- ALWAYS use WebSearch for competitor and library research — don't rely on training data alone
- ALWAYS scan the actual codebase for integration analysis — read real files
- Use PostHog MCP tools if available to pull real metrics
- Use MongoDB MCP tools if available to understand user data/behavior
- Write the report in the language the user used (Russian or English)
- Include specific, actionable recommendations — not generic advice
- Cite sources with URLs where possible
