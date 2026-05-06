---
name: cleanup
description: >
  Post-implementation quality gate that reviews changes, fixes small issues,
  and creates tasks for larger ones. Use when the user asks to "cleanup",
  "quality gate", "почисти код", or wants a scout-rule pass after
  implementation.
---

# Post-Implementation Quality Gate Skill

Perform a final quality gate after implementation. Review all changes made during implementation, identify technical debt, and handle issues according to severity:

- **Small issues**: Fix immediately (Scout Rule) - with user confirmation
- **Medium issues**: Create follow-up tasks in tasks.md
- **Large issues**: Generate detailed analysis with options in tech-debt-report.md

## User Input

```text
$ARGUMENTS
```

Consider the user input before proceeding (if not empty).

## Goal

Identify technical debt and quality issues in the implementation, classify them by severity, and handle each category appropriately. Small issues are fixed with user confirmation, medium issues become tasks, and large issues get analysis.

## Constitution Authority

The project constitution is **non-negotiable**. Any cleanup action that would violate constitution principles is forbidden. If a fix would conflict with a MUST principle, escalate to large issue instead of fixing.

## Execution Steps

### 1. Initialize Cleanup Context

Run the prerequisite check script and parse the JSON output for FEATURE_DIR and AVAILABLE_DOCS.

Derive absolute paths:
- SPEC = FEATURE_DIR/spec.md
- PLAN = FEATURE_DIR/plan.md
- TASKS = FEATURE_DIR/tasks.md
- CONSTITUTION = .specify/memory/constitution.md
- TECH_DEBT_REPORT = FEATURE_DIR/tech-debt-report.md

Abort if TASKS does not exist or has no completed tasks.

### 2. Load Implementation Context

Load minimal necessary context from each artifact:

**From tasks.md:**
- All completed tasks (marked `[X]` or `[x]`)
- File paths mentioned in completed tasks
- Implementation phases that were executed

**From plan.md:**
- Tech stack and language
- Project structure and directories
- Configured linters and tools

**From spec.md:**
- Original requirements (to verify fixes don't violate intent)
- User stories (to map issues to features)

**From constitution:**
- All MUST/SHOULD principles
- Quality gates and standards

### 3. Identify Implementation Changes

Determine which files to review using this priority order:

1. **Task-based detection**: Parse tasks.md for all file paths in completed tasks (most reliable)
2. **Git-based detection**: Run git diff to find recent changes (supplementary)
3. **Build the review scope**: Create list of REVIEW_FILES from tasks and git, REVIEW_DIRS from plan structure, and EXCLUDE patterns for dependencies

### 4. Detect Project Tooling

Before scanning, identify available tools:

**Linters**: Check for config files (.eslintrc, .prettierrc, pyproject.toml, ruff.toml, .rubocop.yml, go.mod)

**Test runners**: Jest/Vitest, Pytest, Go test files

Record available tools for use in validation steps.

### 5. Perform Issue Detection

Scan each file in REVIEW_FILES for issues using progressive disclosure.

#### A. Debugging Artifacts (SMALL - auto-fixable)

Detect and mark for removal:
- JS/TS: console.log, console.debug, console.info, console.warn (non-error), debugger
- Python: print() without logging, breakpoint(), pdb.set_trace(), import pdb
- Java: System.out.print, e.printStackTrace()
- Go: fmt.Print in non-main code
- Ruby: puts for debugging, binding.pry, byebug
- PHP: var_dump(), print_r(), dd(), dump()
- Rust: println! for debugging, dbg!

#### B. Dead Code (SMALL - auto-fixable with caution)

Detect and mark for removal:
- Unused imports: No references in file after import
- Commented-out code: Block comments with code syntax (>3 lines) with no explanatory context
- Unreachable code: Statements after unconditional return, throw, break, continue

**Caution**: Do NOT auto-remove if adjacent comment explains WHY, import is used in type annotations, code is conditionally compiled, or comment has TODO/ticket reference.

#### C. Development Remnants (SMALL/MEDIUM)

| Pattern | Severity | Action |
|---------|----------|--------|
| TODO without ticket reference | SMALL | Add ticket or remove |
| FIXME, HACK, XXX | MEDIUM | Create follow-up task |
| localhost, 127.0.0.1 in source code | SMALL | Replace with environment variable |
| Disabled tests without reason | MEDIUM | Create task to fix or remove |
| Hardcoded credentials/secrets | **CRITICAL** | STOP - alert user immediately |
| Logging user data or queries | MEDIUM | Create task to sanitize logs |
| Import from non-existent module | MEDIUM | Create task to fix or remove |

#### D. Code Quality (MEDIUM - create tasks)

These require judgment and should NOT be auto-fixed:
- Missing error handling on external calls
- Missing input validation on public functions
- Code duplication (same logic in 2-3 locations)
- Missing documentation on public API
- Long functions (>50 lines with high complexity)
- Deep nesting (>4 levels with complex logic)

#### E. Architecture Concerns (LARGE - generate analysis)

- Circular dependencies between modules
- Business logic in wrong layer
- Inconsistent patterns across similar components
- Missing abstraction causing tight coupling
- Performance anti-patterns (N+1 queries, missing pagination)

#### F. Security Concerns (LARGE/CRITICAL)

| Pattern | Severity |
|---------|----------|
| SQL string concatenation | LARGE |
| Unsanitized HTML output | LARGE |
| Hardcoded secrets | CRITICAL - halt |
| Disabled auth checks | CRITICAL - halt |
| Overly permissive CORS ('*') | MEDIUM |

### 6. Constitution Validation

For each potential fix or issue:

1. Check if fix would violate any MUST principle
2. Check if issue represents a constitution violation
3. Constitution violations are automatically LARGE severity

### 7. Classify and Confirm Issues

Build issue inventory with severity assignment and present to user before proceeding:

```markdown
## Cleanup Findings

### Critical Issues (BLOCKING)
[List any - must resolve before continuing]

### Small Issues (Propose to fix now)
| # | File | Issue | Proposed Fix |
|---|------|-------|--------------|

### Medium Issues (Will create tasks)
| # | File | Issue | Task Description |
|---|------|-------|------------------|

### Large Issues (Will generate analysis)
| # | Scope | Issue | Impact |
|---|-------|-------|--------|
```

Wait for user confirmation before applying fixes.

### 8. Execute Fixes (Small Issues)

For each confirmed small issue:

1. **Check for uncommitted changes** in target file - warn user if dirty
2. **Apply fix** - remove debugging artifacts, dead code, replace hardcoded values
3. **Validate fix** - run linter on modified file, ensure no syntax errors
4. **Track changes** for summary (do not commit yet)

### 9. Run Project Validation

After all small fixes applied:

1. **Run linter** (if detected)
2. **Run tests** (if test runner detected) - ROLLBACK fixes if tests fail
3. **Verify no regressions** - all previously passing tests still pass

### 10. Create Tasks for Medium Issues

If user confirmed, append to tasks.md:

```markdown
---

## Tech Debt Tasks (Generated by cleanup)

**Generated**: [ISO DATE]
**Source**: Post-implementation cleanup of [FEATURE NAME]
**Priority**: Address before next feature iteration

### Detected Issues

- [ ] TD001 [P] Add error handling to [function] in [file:line] - missing try/catch
- [ ] TD002 Extract duplicate validation logic from [file1], [file2] into shared utility
```

**ID Assignment**: Check existing TD### IDs and start from max + 1 to avoid conflicts.

### 11. Generate Analysis for Large Issues

Create tech-debt-report.md:

```markdown
# Tech Debt Report: [FEATURE NAME]

**Generated**: [ISO DATE]
**Feature**: [FEATURE_DIR]

## Executive Summary

| Severity | Count | Immediate Action Required |
|----------|-------|---------------------------|
| Critical | 0 | None (or cleanup was halted) |
| Large | X | Review and prioritize |
| Medium | X | Tasks created in tasks.md |
| Small | X | Fixed during cleanup |

## Large Issues Requiring Analysis

### [ISSUE-001] [Descriptive Title]

**Category**: [Architecture / Security / Performance / Design]
**Location**: [file:line or module scope]
**Related Spec**: [Which requirement/story this affects]

#### Problem Description

[Clear explanation of issue]

#### Impact if Not Addressed

[Concrete impacts and risk assessment]

#### Options

**Option 1: [Name] (Recommended)**
- **Approach**: [What to do]
- **Pros**: [Benefits]
- **Cons**: [Drawbacks]
- **Effort**: [T-shirt size: S/M/L/XL]
- **Risk**: [Low/Medium/High]

**Option 2: [Name]**
- Similar structure

**Option 3: Defer**
- Document and revisit later

#### Recommendation

[Which option and why, with specific next steps]
```

### 12. Commit Changes (with user approval)

If small fixes were applied and validation passed:

```markdown
Ready to commit cleanup fixes:
- X files modified
- Y debugging artifacts removed
- Z dead code lines removed

Commit message:
"chore(cleanup): remove debugging artifacts and dead code

- Remove console.log statements from api handlers
- Remove unused imports in utils module
- [list other changes]

Generated by cleanup"

**Commit these changes?** (yes/no/amend-message)
```

### 13. Generate Cleanup Summary

Output final report:

```markdown
## Cleanup Complete

### Summary
| Category | Found | Fixed | Tasks Created | In Report |
|----------|-------|-------|---------------|-----------|
| Critical | 0 | - | - | - |
| Small | X | X | - | - |
| Medium | X | - | X | - |
| Large | X | - | - | X |

### Files Modified
- src/api/handler.ts (removed 2 console.log)
- src/utils/parser.ts (removed unused import)

### Artifacts Updated
- [x] tasks.md - Added Tech Debt Tasks section (X tasks)
- [x] tech-debt-report.md - Created with X large issues

### Validation Status
- [x] Linter: No violations
- [x] Tests: All passing (X tests)
- [x] Constitution: No violations

### Recommended Next Steps
1. Review tech-debt-report.md for large issues
2. Run implement to address TD tasks when ready
3. Consider running analyze to verify overall consistency
```

## Scout Rule

"Always leave the code cleaner than you found it." Small issues are fixed immediately - but always with user visibility and confirmation.