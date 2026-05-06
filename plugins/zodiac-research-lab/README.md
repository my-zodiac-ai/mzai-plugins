# Zodiac Research Lab

Deep feature research plugin for My Zodiac AI. Performs comprehensive multi-dimensional analysis of new feature ideas — from competitor landscape to codebase integration.

## What It Does

Give it a feature idea like "добавить нумерологию" and it produces a complete research report covering:

- **Competitor Analysis** — who already does it, how, strengths/weaknesses, monetization
- **UI/UX Patterns** — best implementations, recommended design approach, user flows
- **Tech Stack** — top libraries, APIs, packages evaluated for the project's stack
- **Codebase Integration** — where to add it, dependencies, effort estimation
- **Metrics & Impact** — real data from PostHog/MongoDB, industry benchmarks, ROI
- **User Stories & Risks** — who needs it, what can go wrong, mitigations

## Components

### Skills

| Skill | Trigger | Description |
|-------|---------|-------------|
| `deep-research` | "исследуй фичу", "deep research" | Main orchestrator — runs all dimensions in parallel |
| `competitor-analysis` | "анализ конкурентов" | Competitor landscape research |
| `ux-research` | "лучший UI для", "UX паттерны" | UI/UX pattern analysis |
| `tech-stack-research` | "какие библиотеки для" | Library and API evaluation |
| `codebase-analysis` | "где в коде", "точка интеграции" | Integration point analysis |
| `metrics-analysis` | "метрики фичи", "impact analysis" | Metrics and business impact |

### Agents

| Agent | Role | Launched By |
|-------|------|------------|
| `market-researcher` | Competitors + metrics | `deep-research` skill |
| `ux-researcher` | UI/UX patterns + design | `deep-research` skill |
| `tech-researcher` | Libraries + codebase analysis | `deep-research` skill |

## Usage

**Full research (recommended):**
> "Нужно добавить нумерологию — сделай deep research"

**Individual dimensions:**
> "Проанализируй конкурентов для совместимости знаков"
> "Какие библиотеки есть для лунного календаря?"
> "Где в коде лучше интегрировать таро?"

## MCP Integration

The plugin leverages connected MCP services when available:

- **PostHog** — real user metrics, retention curves, feature usage
- **MongoDB** — user data patterns, existing content analysis
- **Web Search** — competitor info, library stats, market data

No MCP servers are bundled — the plugin uses whatever is already connected.

## Output

Research reports are saved as Markdown files: `research-[feature]-[date].md`
