---
name: retrospective
description: >
  Post-implementation retrospective measuring spec adherence, deviations,
  and lessons learned. Use when the user asks to "retrospective", "lessons
  learned", "ретроспектива", or wants to analyze a completed feature.
---

# Post-Implementation Retrospective Skill

Analyze completed implementation against `spec.md`, `plan.md`, and `tasks.md` to measure spec adherence and drift. Generate actionable insights for future SDD cycles.

## User Input

```text
$ARGUMENTS
```

Consider user input before proceeding (if not empty).

## Goal

Generate a comprehensive retrospective report that measures spec adherence, identifies drift, captures innovations, and provides lessons learned for future cycles.

## Constraints

- Output: Generates and saves `retrospective.md` report to FEATURE_DIR
- Post-Implementation: Run after implementation complete; warn if <80% tasks done, confirm before proceeding if <50%
- Human Gate for spec changes: before any action that modifies `spec.md`, explicitly ask for user confirmation and stop if not approved
- Confirmation policy: default is NO. Only explicit approvals (`y`, `yes`, `si`, `s`, `sí`) count as consent

## Execution Steps

### 1. Initialize Context

Run the prerequisite check script from repo root. Parse JSON for FEATURE_DIR and AVAILABLE_DOCS.

Derive paths: SPEC, PLAN, TASKS = FEATURE_DIR/{spec,plan,tasks}.md. Abort if missing.

### 2. Validate Completeness

Calculate completion rate from tasks.md:
- >=80%: Proceed with full retrospective
- 50-79%: Warn about incomplete implementation, continue with partial analysis
- <50%: STOP and confirm before continuing

### 3. Load Artifacts

Load:
- `spec.md`: FR-XXX, NFR-XXX, SC-XXX, user stories, assumptions, edge cases
- `plan.md`: Architecture, data model, phases, constraints, dependencies
- `tasks.md`: All tasks with status, file paths, blockers
- constitution (if exists): MUST/SHOULD principles, quality gates

### 4. Discover Implementation

- Extract file paths from completed tasks plus recent git history
- Inventory: Models, APIs, Services, Tests, Config changes
- Audit: Libraries, frameworks, integrations actually used

### 5. Spec Drift Analysis

Perform:
1. Requirement coverage (implemented, partial, not implemented, modified, unspecified)
2. Success criteria validation
3. Architecture drift against plan
4. Task fidelity (completed/modified/added/dropped)
5. Timeline and blockers (if available)

Calculate:
```
Spec Adherence % = ((IMPLEMENTED + MODIFIED + (PARTIAL * 0.5)) / (Total Requirements - UNSPECIFIED)) * 100
```

### 6. Severity Classification

Classify findings as:
- CRITICAL (core functionality or constitution violations)
- SIGNIFICANT (deviations that affect UX/performance/operations)
- MINOR (small or cosmetic variations)
- POSITIVE (improvements over spec)

### 7. Innovation Opportunities

For positive deviations, document:
- What improved
- Why it is better
- Reusability potential
- Whether it is a constitution candidate

### 8. Root Cause Analysis

For key deviations capture:
- Discovery point (planning/implementation/testing/review)
- Cause (spec gap, tech constraint, scope evolution, misunderstanding, improvement, process skip)
- Prevention recommendation

### 9. Constitution Compliance

Check each constitution article against implementation. Treat violations as CRITICAL.

### 10. Generate Report

Create `retrospective.md` with:

```markdown
# Implementation Retrospective

Feature: [feature name]
Branch: [branch name]
Date: [date]
Completion Rate: X%
Spec Adherence: X%

## Executive Summary

[2-3 paragraph summary of the implementation]

## Proposed Spec Changes

[Explicit list of intended spec.md edits, grouped by FR/NFR/SC and rationale]

## Requirement Coverage Matrix

| Requirement | Status | Notes | Evidence |
|------------|--------|-------|----------|

## Success Criteria Assessment

[Assessment of how well success criteria were met]

## Architecture Drift

[Comparison of actual vs planned architecture]

## Significant Deviations

[Major divergences from spec, classified by severity]

## Innovations and Best Practices

[Positive deviations and improvements discovered during implementation]

## Constitution Compliance

[Assessment of constitution article adherence]

## Unspecified Implementations

[Features implemented that weren't in the spec]

## Task Execution Analysis

[Analysis of how tasks were completed, blockers, deviations]

## Lessons Learned and Recommendations

[Actionable insights for future cycles]

## File Traceability Appendix

[List of files created/modified with mapping to requirements]
```

### 11. Self-Assessment Checklist

Before finalizing output, run this checklist:

- Evidence completeness: Every major deviation includes concrete evidence
- Coverage integrity: FR/NFR/SC coverage is complete with no missing requirement IDs
- Metrics sanity: completion_rate and spec_adherence formulas are applied correctly
- Severity consistency: CRITICAL/SIGNIFICANT/MINOR/POSITIVE labels match stated impact
- Constitution review: Constitution violations are explicitly listed
- Human Gate readiness: If spec changes proposed, ready for user confirmation
- Actionability: Recommendations are specific, prioritized, tied to findings

Blocking rule: If any critical assessment fails, do not finalize. Fix gaps first.

### 12. Save Report

1. Write to `FEATURE_DIR/retrospective.md`
2. Optionally commit with:
   - `feat(retrospective): add spec adherence report (adherence X%, completion X%)`
3. Confirm:
   - `Retrospective saved | Adherence: X% | Critical findings: X`

### 13. Human Gate Before Spec Changes

If retrospective findings recommend updating the spec:

1. Present a short summary of the proposed `spec.md` changes
2. Ask explicitly: `Do you want me to modify spec.md now? (y/N)`
3. Treat any response other than explicit yes as NO
4. Require separate confirmation for each spec-modifying action
5. If declined, do not modify spec and continue with report-only recommendations

### 14. Follow-up Actions

Prioritize:
1. CRITICAL: constitution violations, breaking changes, security issues
2. HIGH: significant drift and process improvements
3. MEDIUM: best practices and constitution candidates
4. LOW: minor optimizations

## Guidelines

### Count as Drift

Features differing from spec, dropped requirements, scope creep, or changes in technical approach.

### Not Drift

Implementation details, bounded optimizations, bug fixes, refactoring, and test improvements.

### Principles

- Facts over judgments
- Process over blame
- Positive deviations are learning opportunities
- Keep report concise and actionable