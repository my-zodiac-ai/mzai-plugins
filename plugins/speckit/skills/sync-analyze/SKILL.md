---
name: sync-analyze
description: >
  Analyze drift between specs and implementation for the sync workflow.
  Use when the user asks to "sync analyze", "analyze sync drift", or wants
  to discover spec-code divergence.
---

# Spec Sync: Analyze Drift Skill

Analyze drift between specifications and implementation. This command compares spec requirements (FR-*, SC-*, acceptance scenarios) against actual codebase to identify where they've diverged.

## User Input

```text
$ARGUMENTS
```

## Workflow

### 1. Discover Specs

Find all spec files in the project. For each spec, extract:
- Spec ID (directory name)
- Title (first heading)
- Functional requirements (FR-001, FR-002, etc.)
- Success criteria (SC-001, SC-002, etc.)
- Key acceptance scenarios

### 2. Analyze Implementation

For each spec, determine:
- Which requirements have corresponding implementation
- Which requirements appear unimplemented
- Which code features exist without spec coverage

Use heuristics:
- CLI commands mentioned in spec → Check for Command classes
- Services mentioned in spec → Check for Service classes
- Entities/models mentioned → Check for entity files
- Test coverage → Check for test files

### 3. Detect Unspecced Code

Find code that doesn't match any spec:
- Commands not referenced in any spec
- Services not referenced in any spec
- Features that evolved beyond their spec

### 4. Generate Drift Report

Output structured report with:
- Summary statistics (analyzed, aligned, drifted, not implemented, unspecced)
- Detailed findings per spec (aligned, drifted with severity, not implemented)
- Unspecced code inventory
- Inter-spec conflicts
- Recommendations

### 5. Save Reports

Write to:
- `.specify/sync/drift-report.md` (human-readable)
- `.specify/sync/drift-report.json` (machine-readable)

## Notes

- This is a read-only analysis - no files are modified
- Large codebases may take time to analyze
- Use `--spec <id>` to analyze a single spec
- Use `--json` for machine-readable output only