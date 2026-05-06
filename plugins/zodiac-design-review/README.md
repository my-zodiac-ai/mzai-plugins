# Zodiac Design Review Plugin

Comprehensive design review system for **My Zodiac AI** — launches 5 specialized agents in parallel to analyze visual design, UX/UI quality, accessibility, design system tokens, and feature enhancement opportunities.

## Overview

This plugin is tailored for the My Zodiac AI codebase (Vue 3 + Quasar + Cosmic Glass design system + Capacitor). It analyzes real frontend code, not mockups.

## Components

### Skills (6)

| Skill | Purpose |
|-------|---------|
| `comprehensive-review` | **Main entry point** — orchestrates all 5 agents in parallel |
| `design-critique` | Visual hierarchy, glass system compliance, color/typography, composition |
| `ux-ui-review` | User flows, state completeness, microcopy, mobile, performance UX |
| `accessibility-audit` | WCAG 2.1 AA compliance with glass-specific checks |
| `design-system-tokens` | Token coverage, naming conventions, mixin usage, component variants |
| `feature-enhancement` | Improvement suggestions based on UX patterns and competitive analysis |

### Agents (5)

| Agent | Color | Focus |
|-------|-------|-------|
| `design-critic` | 🟣 Magenta | Visual design quality |
| `ux-ui-reviewer` | 🔵 Cyan | Usability and interaction |
| `a11y-auditor` | 🟡 Yellow | Accessibility compliance |
| `token-auditor` | 🟢 Green | Design system health |
| `feature-enhancer` | 🔷 Blue | Feature improvements |

## Usage

### Full Comprehensive Review
```
"Full design review of the horoscope page"
"Комплексная проверка дизайна natal chart"
"Review everything in the compatibility feature"
```

### Individual Dimensions
```
"Critique the visual design of AppCard"
"Check accessibility of the onboarding flow"
"Audit design system tokens"
"Suggest improvements for the daily horoscope"
"Review UX of the settings page"
```

## Output

All reports are generated in **Markdown** format with:
- Severity-coded findings (🔴 Critical, 🟡 Major, 🟢 Minor)
- File:line references for each issue
- Specific fix recommendations
- Scores per dimension and overall
- Prioritized action plan

## Architecture

The plugin follows the My Zodiac AI conventions:
- Analyzes FSD structure (`front/src/shared/ui/`, `front/src/features/`, `front/src/pages/`)
- Understands Cosmic Glass design system (`_mixins-redesign.scss`, CSS custom properties)
- Checks Quasar component integration patterns
- Considers Capacitor mobile context (touch targets, haptics, performance)
