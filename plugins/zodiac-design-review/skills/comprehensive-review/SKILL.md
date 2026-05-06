---
name: comprehensive-review
description: >
  Launch a full comprehensive design review of a My Zodiac AI screen or component,
  running all 5 review agents in parallel. Use when the user asks to "full design review",
  "comprehensive review", "комплексная проверка дизайна", "полный ревью дизайна",
  "design audit", "проверь всё", "review everything",
  or wants a complete analysis covering visual design, UX/UI, accessibility,
  design system compliance, and feature enhancement suggestions.
---

# Comprehensive Design Review — My Zodiac AI

Orchestrate a full design review by launching all 5 specialized agents in parallel, then synthesize results into a unified report.

## Activation

This is the PRIMARY entry point for design reviews. Trigger when the user wants a complete review, or when no specific review dimension is specified.

## Orchestration Process

### 1. Identify Target

Ask the user (if not specified) what to review:
- A specific component: `front/src/shared/ui/AppCard/`
- A page/screen: `front/src/pages/horoscope/`
- A feature area: `front/src/features/natal-chart/`
- An entire layer: `front/src/widgets/`

### 2. Launch Parallel Agents

Spawn 5 agents in parallel, each focused on its dimension:

**Agent 1: Design Critique**
- Read the `design-critique` skill
- Focus: visual hierarchy, glass system compliance, color/typography, composition, animation
- Output: Design Critique section of the report

**Agent 2: UX/UI Review**
- Read the `ux-ui-review` skill
- Focus: user flows, state completeness, microcopy, mobile, performance UX
- Output: UX/UI Review section of the report

**Agent 3: Accessibility Audit**
- Read the `accessibility-audit` skill
- Focus: WCAG 2.1 AA compliance, keyboard nav, ARIA, contrast, reduced motion
- Output: Accessibility Audit section of the report

**Agent 4: Design System Tokens**
- Read the `design-system-tokens` skill
- Focus: token coverage, naming conventions, component variants, mixin usage
- Output: Design System section of the report

**Agent 5: Feature Enhancement**
- Read the `feature-enhancement` skill
- Focus: functionality improvements, engagement, competitive patterns
- Output: Enhancement Suggestions section of the report

### 3. Synthesize Results

After all agents complete, merge findings into a unified markdown report.

**Deduplication:** If multiple agents flag the same issue (e.g., both accessibility and design-critique flag contrast), keep it in the most specific section and add a cross-reference.

**Scoring:** Calculate an overall score:
```
Overall = (Design × 0.20) + (UX/UI × 0.25) + (A11y × 0.25) + (Tokens × 0.15) + (Enhancement × 0.15)
```

### 4. Generate Report

Create the final markdown report in the following structure:

```markdown
# Comprehensive Design Review: [Target Name]
**Date:** [Date] | **Reviewer:** Zodiac Design Review Plugin v0.1.0

---

## Executive Summary

**Overall Score: [X]/100**

| Dimension | Score | Critical | Major | Minor |
|-----------|-------|----------|-------|-------|
| 🎨 Design Critique | [X]/100 | [X] | [X] | [X] |
| 🧩 UX/UI Review | [X]/100 | [X] | [X] | [X] |
| ♿ Accessibility | [X]/100 | [X] | [X] | [X] |
| 🎯 Design System | [X]/100 | [X] | [X] | [X] |
| 💡 Enhancements | — | — | — | [X] suggestions |

### Top 5 Priority Fixes
1. 🔴 **[Critical issue]** — [Section] — [Fix]
2. 🔴 **[Critical issue]** — [Section] — [Fix]
3. 🟡 **[Major issue]** — [Section] — [Fix]
4. 🟡 **[Major issue]** — [Section] — [Fix]
5. 🟡 **[Major issue]** — [Section] — [Fix]

---

## 🎨 Design Critique
[Full output from design-critique agent]

---

## 🧩 UX/UI Review
[Full output from ux-ui-review agent]

---

## ♿ Accessibility Audit
[Full output from accessibility-audit agent]

---

## 🎯 Design System Tokens
[Full output from design-system-tokens agent]

---

## 💡 Feature Enhancement Suggestions
[Full output from feature-enhancement agent]

---

## Cross-Cutting Issues
[Issues that span multiple dimensions, with references to each section]

---

## Action Plan

### Immediate (This Sprint)
| # | Issue | Dimension | Severity | Est. Effort |
|---|-------|-----------|----------|-------------|
| 1 | ... | A11y | 🔴 | 1h |

### Next Sprint
| # | Issue | Dimension | Severity | Est. Effort |
|---|-------|-----------|----------|-------------|
| 1 | ... | UX/UI | 🟡 | 4h |

### Backlog
| # | Enhancement | Impact | Effort |
|---|------------|--------|--------|
| 1 | ... | High | Medium |
```

### 5. Save Report

Save the generated report as a markdown file to the workspace.

## Agent Dispatch Pattern

When orchestrating, use this pattern to launch agents:

```
For each agent:
1. Read the relevant SKILL.md from this plugin
2. Read the target component files
3. Read the design system source files (mixins, tokens)
4. Apply the analysis framework from the skill
5. Generate the dimension-specific report section
```

All 5 agents should run in parallel where possible to minimize review time.
