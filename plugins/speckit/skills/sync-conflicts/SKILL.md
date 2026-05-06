---
name: sync-conflicts
description: >
  Detect and resolve conflicts between specs and design documents. Use when
  the user asks to "sync conflicts", "detect conflicts", or needs to find
  contradictions between artifacts.
---

# Spec Sync: Detect Conflicts Skill

Find contradictions between specs, or between specs and design documents. Surface them for human resolution.

## User Input

```text
$ARGUMENTS
```

## Workflow

### 1. Extract Requirements from All Sources

For each spec, extract:
- All FR-* requirements with full text
- All SC-* success criteria
- Key constraints and assumptions
- Out of scope items

For design docs, extract:
- Design decisions
- Constraints
- Behavioral specifications
- Any "MUST", "SHALL", "SHOULD" statements

### 2. Build Requirement Index

Create semantic index of all requirements, keyed by:
- Feature area (extraction, routing, register, etc.)
- Entity type (document, transaction, row, etc.)
- Behavior type (create, update, validate, etc.)

### 3. Detect Direct Conflicts

Look for contradictions:

**Type 1: Same Feature, Different Behavior**
- Spec A says "one row per document"
- Spec B says "split transactions produce multiple rows"

**Type 2: Obsolete Constraints**
- Spec A says "5 extraction fields"
- Design doc says "type-aware fields, 4-8 per type"

**Type 3: Scope Overlap**
- Spec A includes feature X
- Spec B also includes feature X

**Type 4: Implicit Conflicts**
- Spec A assumes auth is always valid
- Spec B adds offline mode

### 4. Determine Resolution Path

For each conflict:

**SUPERSEDE**: Newer document replaces older
- Check dates, version numbers
- Design docs often supersede original specs
- Later specs refine earlier specs

**MERGE**: Combine into single authoritative source
- When both have valid parts
- Create unified spec

**DEPRECATE**: Mark older as obsolete
- When requirement is no longer relevant
- Document why it was removed

**HUMAN_REQUIRED**: Can't determine automatically
- Architectural decisions
- Trade-offs involved
- Missing context

### 5. Generate Conflict Report

Create report with:

```markdown
# Spec Conflict Report

Generated: [timestamp]

## Summary

| Conflict Type | Count |
|---------------|-------|
| Same Feature, Different Behavior | X |
| Obsolete Constraints | X |
| Scope Overlap | X |
| Implicit Conflicts | X |

## Conflicts

### Conflict 1: [Title]

**Sources**:
- [source1]
- [source2]

**Description**:
[Detailed explanation of conflict]

**Evidence**:
[Quotes from both sources]

**Suggested Resolution**: [SUPERSEDE|MERGE|DEPRECATE|HUMAN_REQUIRED]

**Action Required**:
- [ ] Mark as superseded
- [ ] Update spec
- [ ] Or create new spec

## Resolution Tracking

| Conflict | Resolution | Decided By | Date |
|----------|------------|------------|------|
| Conflict 1 | pending | - | - |

## Recommendations

1. Schedule a review session to resolve conflicts
2. Consider consolidating related specs
3. Add explicit "supersedes" metadata to specs
```

### 6. Save Reports

Write to:
- `.specify/sync/conflicts.md`
- `.specify/sync/conflicts.json`

## Resolution Commands

After reviewing conflicts, mark resolutions:

```
/sync-conflicts resolve 1 --supersede docs/plans/2026-02-19-type-aware-extraction-design.md

/sync-conflicts resolve 2 --merge spec-011
```

## Options

- `--include-design-docs`: Include design docs in conflict detection
- `--spec <id>`: Analyze only a specific spec