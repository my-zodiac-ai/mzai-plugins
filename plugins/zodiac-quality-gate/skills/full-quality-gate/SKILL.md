---
name: full-quality-gate
description: >
  Run a comprehensive quality gate — launch all audit dimensions (code quality, security,
  architecture, performance, dependencies, refactoring, testing) in parallel and produce
  a consolidated report with prioritized action plan. Use when the user asks to
  "full quality check", "full audit", "quality gate", "полная проверка качества",
  "проверь всё", "comprehensive review", "pre-release check", "полный аудит кода",
  "запусти все проверки", "code health report", or before a major release or PR merge.
  This is the primary orchestrator — use it when you want the complete picture rather than
  a single dimension. Also trigger proactively before deploy-checklist or release workflow.
---

# Full Quality Gate — Mega-Orchestrator

Run all quality audit dimensions in parallel, collect results, and produce a single consolidated report with a prioritized action plan.

## Orchestration Strategy

### Step 1: Scope Detection

Determine the audit scope:
- **PR/diff mode**: `git diff --name-only [base]...HEAD` → audit only changed files
- **Module mode**: user specifies a module/feature → audit that subtree
- **Full project mode**: user wants a complete health check → audit everything (batch by module)

Ask the user if scope is ambiguous.

### Step 2: Launch Parallel Agents

Launch **7 specialized agents in parallel** using the Agent tool. Each agent has its own agent definition in the plugin's `agents/` directory with a dedicated system prompt, tools, and color coding.

**CRITICAL: Launch ALL agents in a single message** to run them simultaneously:

| # | Agent (`subagent_type`) | Color | Focus | Tools |
|---|---|---|---|---|
| 1 | `zodiac-quality-gate:code-quality-auditor` | blue | SOLID, DRY, YAGNI, KISS, clean code | Read, Grep, Glob |
| 2 | `zodiac-quality-gate:security-auditor` | red | OWASP, secrets, CVEs, auth/authz | Read, Grep, Glob, Bash |
| 3 | `zodiac-quality-gate:architecture-auditor` | cyan | EDA, DDD, FSD, boundaries, ADR | Read, Grep, Glob |
| 4 | `zodiac-quality-gate:performance-auditor` | yellow | N+1, memory leaks, caching, bundle | Read, Grep, Glob |
| 5 | `zodiac-quality-gate:dependency-auditor` | green | Outdated, CVEs, alternatives, licenses | Read, Grep, Glob, Bash |
| 6 | `zodiac-quality-gate:refactor-auditor` | magenta | Dead code, simplification, consolidation | Read, Grep, Glob |
| 7 | `zodiac-quality-gate:testing-auditor` | green | Coverage gaps, test quality, flaky tests | Read, Grep, Glob, Bash |

For each agent, provide in the prompt:
- The **scope** (files/modules to audit)
- Path to relevant project docs (`docs/AI_PATTERNS.md`, `docs/AI_ARCHITECTURE.md`, `docs/AI_TESTING.md`)
- Instruction to produce **structured markdown output** matching the agent's report format
- If project has `references/zodiac-rules.md` — point the agent to it for project-specific patterns

**Example agent invocation** (send all 7 like this in one message):

```
Agent(
  subagent_type: "zodiac-quality-gate:code-quality-auditor",
  description: "Code quality audit of payments module",
  prompt: "Audit code quality in back/src/modules/business/payments/.
    Read docs/AI_PATTERNS.md first for project patterns.
    Check SOLID, DRY, YAGNI, KISS, clean code, deduplication.
    Produce structured markdown report with scored findings."
)
```

### Step 3: Collect & Consolidate

Wait for all audits to complete, then:

1. **Deduplicate findings** — same issue found by multiple audits → keep the most detailed one
2. **Cross-reference** — security finding that also affects performance → link them
3. **Normalize severity** — align all findings to unified scale: Critical / High / Medium / Low / Info
4. **Calculate overall score** — weighted formula:

```
Score = 100 - (Critical × 15) - (High × 8) - (Medium × 3) - (Low × 1)
Minimum: 0, Maximum: 100
```

### Step 4: Produce Consolidated Report

```markdown
# Quality Gate Report

## Overall Score: X/100 — PASS / NEEDS WORK / FAIL

| Dimension | Score | Critical | High | Medium | Low |
|---|---|---|---|---|---|
| Code Quality | X/100 | N | N | N | N |
| Security | X/100 | N | N | N | N |
| Architecture | X/100 | N | N | N | N |
| Performance | X/100 | N | N | N | N |
| Dependencies | X/100 | N | N | N | N |
| Refactoring | X/100 | N | N | N | N |
| Testing | X/100 | N | N | N | N |

## Gate Decision
- **PASS** (Score ≥ 80, no Critical findings): Safe to merge/deploy
- **NEEDS WORK** (Score 50-79 or has Critical findings): Fix critical items first
- **FAIL** (Score < 50): Major issues require attention before proceeding

## Top Priority Findings (across all dimensions)

### Critical
1. [SEC-001] Hardcoded API key in ai-manager → **Fix immediately**
2. [ARCH-003] Direct cross-module dependency violates EDA → **Refactor before merge**

### High
3. [PERF-001] N+1 query in relationships endpoint → **Fix this sprint**
4. [CQ-002] God service UserService (600 lines) → **Plan refactoring**

### Medium
...

## Dimension Summaries

### Code Quality
[summary from code-quality-audit]

### Security
[summary from security-audit]

### Architecture
[summary from architecture-audit]

### Performance
[summary from performance-audit]

### Dependencies
[summary from dependency-audit]

### Refactoring Opportunities
[summary from refactor-audit]

### Testing
[summary from testing-audit]

## Action Plan

### Immediate (before merge/deploy)
| # | Finding | Dimension | Effort | Owner |
|---|---|---|---|---|
| 1 | Fix hardcoded secret | Security | 15 min | — |

### This Sprint
| # | Finding | Dimension | Effort | Owner |
|---|---|---|---|---|

### Next Sprint
...

### Backlog
...
```

### Step 5: Save Report

Save the consolidated report as a markdown file at the project root or in the user's preferred location.

## Configuration

### Selective Mode

If the user wants to skip certain dimensions, respect that:
- "Check everything except dependencies" → launch 6 of 7
- "Just security and architecture" → launch only those 2

### Thresholds

Default gate thresholds:
- **PASS**: Score ≥ 80, zero Critical findings
- **NEEDS WORK**: Score 50-79 OR any Critical findings
- **FAIL**: Score < 50

User can override: "Set pass threshold to 90".

## When to Suggest This Skill

Proactively suggest running full-quality-gate when:
- User is about to create a PR for a large feature
- User mentions "release", "deploy", "production"
- A significant amount of code was written without review
- User asks "is this ready?" or "can we ship this?"
