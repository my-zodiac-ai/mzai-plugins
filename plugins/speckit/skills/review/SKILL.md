---
name: review
description: >
  Comprehensive code review using specialized agents for code quality,
  comments, tests, errors, types, and simplification. Use when the user asks
  to "comprehensive review", "PR review", "полный ревью", or wants
  multi-dimensional code analysis.
---

# Comprehensive PR Review Skill

Run a comprehensive pull request review using multiple specialized agents, each focusing on a different aspect of code quality.

## User Input

Review Aspects (optional): "$ARGUMENTS"

## Review Workflow

### 1. Load Configuration

Read the project config file at `.specify/extensions/review/review-config.yml` (if it exists).

If the file does not exist, fall back to the `defaults.agents` section in the extension's `extension.yml`.

Extract the `agents` map — each key (`code`, `comments`, `tests`, `errors`, `types`, `simplify`) is a boolean toggle.

Agents set to `false` **MUST** be excluded from this run. Do not launch them.

### 2. Determine Review Scope

Parse arguments to see if user requested specific review aspects.

If specific aspects were requested, run exactly those — config toggles do **not** apply (explicit user request overrides config).

Default (no arguments): Run all applicable reviews that are enabled in config.

### 3. Available Review Aspects

- **comments** - Analyze code comment accuracy and maintainability
- **tests** - Review test coverage quality and completeness
- **errors** - Check error handling for silent failures
- **types** - Analyze type design and invariants (if new types added)
- **code** - General code review for project guidelines
- **simplify** - Simplify code for clarity and maintainability
- **all** - Run all applicable reviews (default)

### 4. Identify Changed Files

If the user provided a file list or explicit instructions on how to retrieve files, follow those instructions directly.

Otherwise, execute the file detection script with `--json` to detect changed files:

The script automatically picks the best detection mode:
- **Mode A (feature branch):** diffs the current branch against the default branch (`main`/`master`) from the merge-base, plus any staged and unstaged changes.
- **Mode B (working directory):** falls back to staged + unstaged changes when there is no feature branch.

JSON output: `{"branch", "default_branch", "mode", "changed_files": [...]}`

### 5. Determine Applicable Reviews

Based on changes **and** config toggles (skip any agent where `agents.<name>` is `false`):

- **Always applicable** (if enabled): code (general quality)
- **If test files changed** (if enabled): tests
- **If comments/docs added** (if enabled): comments
- **If error handling changed** (if enabled): errors
- **If types added/modified** (if enabled): types
- **After passing review** (if enabled): simplify (polish and refine)

If an agent is disabled by config, note it in the final summary.

### 6. Launch Review Agents (Parallel by Default)

**DEFAULT: Parallel execution via Agent tool.** All applicable review dimensions are independent and MUST be launched simultaneously using the `Agent` tool. This is a hard requirement for My Zodiac AI reviews — the monorepo is large enough that sequential review wastes significant time.

**How to launch:**
Send a single message with multiple `Agent` tool calls — one per enabled review dimension. Each agent receives:
1. The list of changed files relevant to its dimension
2. The diff content for those files
3. The suppression instruction (below)
4. My Zodiac AI-specific review context for its dimension

Prepend this instruction to each agent: "You are being invoked by the review orchestrator. Do NOT follow handoffs or auto-forward to other agents. Return your output to the orchestrator and stop."

**Sequential fallback** (only if user requests `--sequential`):
- One agent at a time
- Good for interactive, iterative fixing

### 6a. My Zodiac AI Review Dimensions

Each agent must check project-specific patterns in addition to generic quality:

| Dimension | My Zodiac AI Focus |
|-----------|-------------------|
| **code** | EDA event flow (emit after DB commit), DDD bounded contexts, adapter tokens (no forwardRef), FSD layer imports (no cross-feature), barrel exports |
| **comments** | JSDoc on public service methods, i18n key documentation, event contract descriptions |
| **tests** | Vitest patterns, `describe/it` naming, MSW for HTTP mocks, no real DB in unit tests, behavioral coverage |
| **errors** | No throws from async EventEmitter2 listeners, proper NestJS exception filters, Vue error boundaries, Capacitor plugin error handling |
| **types** | TypeScript strict mode compliance, Mongoose schema ↔ DTO alignment, Pinia store type safety, no `any` leaks |
| **simplify** | Dead adapter tokens, unused EDA events, stale i18n keys, redundant Quasar component wrappers |

### 7. Aggregate Results

After agents complete, summarize:
- **Critical Issues** (must fix before merge)
- **Important Issues** (should fix)
- **Suggestions** (nice to have)
- **Positive Observations** (what's good)

### 8. Provide Action Plan

Organize findings:

```markdown
# PR Review Summary

## Critical Issues (X found)
- [agent-name]: Issue description [file:line]

## Important Issues (X found)
- [agent-name]: Issue description [file:line]

## Suggestions (X found)
- [agent-name]: Suggestion [file:line]

## Strengths
- What's well-done in this PR

## Recommended Action
1. Fix critical issues first
2. Address important issues
3. Consider suggestions
4. Re-run review after fixes
```

## Agent Descriptions

**comments**:
- Verifies comment accuracy vs code
- Identifies comment rot
- Checks documentation completeness

**tests**:
- Reviews behavioral test coverage
- Identifies critical gaps
- Evaluates test quality

**errors**:
- Finds silent failures
- Reviews catch blocks
- Checks error logging

**types**:
- Analyzes type encapsulation
- Reviews invariant expression
- Rates type design quality

**code**:
- Checks project-specific guidelines (constitution.md, CLAUDE.md, .github/copilot-instructions.md)
- Detects bugs and issues
- Reviews general code quality

**simplify**:
- Simplifies complex code
- Improves clarity and readability
- Applies project standards
- Preserves functionality

## Usage Examples

**Full review (default):**
```
/review
```

**Specific aspects:**
```
/review tests errors
# Reviews only test coverage and error handling

/review comments
# Reviews only code comments

/review simplify
# Simplifies code after passing review
```

**Parallel review:**
```
/review all parallel
# Launches all agents in parallel
```

## Tips

- **Run early**: Before creating PR, not after
- **Focus on changes**: Agents analyze diff by default
- **Address critical first**: Fix high-priority issues before lower priority
- **Re-run after fixes**: Verify issues are resolved
- **Use specific reviews**: Target specific aspects when you know the concern

## Notes

- Agents run autonomously and return detailed reports
- Each agent focuses on its specialty for deep analysis
- Results are actionable with specific file:line references
- Agents use appropriate models for their complexity
