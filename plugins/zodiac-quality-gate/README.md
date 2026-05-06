# Zodiac Quality Gate Plugin

Comprehensive code quality orchestrators for My Zodiac AI. Runs multi-dimensional quality audits via **specialized subagents** in parallel and produces actionable consolidated reports.

## Architecture

```
┌─────────────────────────────────────┐
│        full-quality-gate (skill)     │  ← Mega-orchestrator
│  Determines scope, launches agents,  │
│  consolidates reports, scores, gates │
└──────────┬───────────────────────────┘
           │ launches 7 agents in parallel
     ┌─────┼─────┬──────┬──────┬──────┬──────┬──────┐
     ▼     ▼     ▼      ▼      ▼      ▼      ▼      ▼
   code  secur  arch  perf   deps  refact  test
   qual  ity    itect  orm   end   or      ing
   ity   audit  ure    ance  ency  audit   audit
   audit  or    audit  audit audit  or      or
    or          or     or     or
```

## Skills (knowledge + when to trigger)

| Skill | Trigger | What it checks |
|---|---|---|
| **full-quality-gate** | "full audit", "quality gate", "проверь всё" | All 7 dimensions in parallel → consolidated report |
| **code-quality-audit** | "check code quality", "SOLID check" | SOLID, DRY, YAGNI, KISS, clean code, deduplication |
| **security-audit** | "security check", "найди уязвимости" | OWASP Top 10, secrets, CVEs, auth, input validation |
| **architecture-audit** | "check architecture", "EDA compliance" | EDA, DDD, FSD, boundaries, ADR conformance |
| **performance-audit** | "check performance", "find bottlenecks" | N+1 queries, memory leaks, caching, bundle size |
| **dependency-audit** | "check dependencies", "npm audit" | Outdated packages, CVEs, license compliance, alternatives |
| **refactor-audit** | "suggest refactoring", "find dead code" | Dead code, simplification, consolidation, patterns |
| **testing-audit** | "audit tests", "test coverage review" | Coverage gaps, test quality, flaky tests, strategy |

## Agents (execution — subagents that do the actual work)

| Agent | Color | Model | Tools | Role |
|---|---|---|---|---|
| `code-quality-auditor` | blue | sonnet | Read, Grep, Glob | Executes SOLID/DRY/YAGNI/KISS checks |
| `security-auditor` | red | sonnet | Read, Grep, Glob, Bash | Runs OWASP, secrets, CVE scans |
| `architecture-auditor` | cyan | sonnet | Read, Grep, Glob | Verifies EDA/DDD/FSD compliance |
| `performance-auditor` | yellow | sonnet | Read, Grep, Glob | Finds N+1, memory leaks, bottlenecks |
| `dependency-auditor` | green | sonnet | Read, Grep, Glob, Bash | Audits packages, licenses, CVEs |
| `refactor-auditor` | magenta | sonnet | Read, Grep, Glob | Identifies dead code, simplification targets |
| `testing-auditor` | green | sonnet | Read, Grep, Glob, Bash | Evaluates coverage, quality, flakiness |

## How It Works

1. **Skills** define *what to check* and *when to trigger* — they contain the audit methodology
2. **Agents** are *who executes* — specialized subagents with dedicated system prompts
3. The **mega-orchestrator** (`full-quality-gate` skill) coordinates everything:
   - Detects scope (PR diff / module / full project)
   - Launches all 7 agents in parallel
   - Deduplicates and cross-references findings
   - Calculates score (0-100) and gate decision (PASS / NEEDS WORK / FAIL)
   - Produces prioritized Action Plan

## Usage

```
"Run a full quality gate on the payments module"  → all 7 agents in parallel
"Check architecture compliance"                    → architecture-auditor only
"Security audit before release"                    → security-auditor only
"Проверь качество кода в AI модуле"                → code-quality-auditor only
```

## Project-Specific Rules

When running inside My Zodiac AI, agents load `references/zodiac-rules.md` with EDA/DDD/FSD patterns, bounded context boundaries, anti-patterns, and naming conventions.

For other projects, universal best practices apply (SOLID, OWASP, clean code, etc.).

## Author

Valentyn Yakovliev — My Zodiac AI
