---
name: sync-backfill
description: >
  Generate specs from existing unspecified code features. Use when the user
  asks to "sync backfill", "backfill specs", or has code without matching
  specifications.
---

# Spec Sync: Backfill Spec Skill

Generate a complete spec from an existing, unspecced code feature. Extracts intent from implementation, tests, and documentation.

## User Input

```text
$ARGUMENTS
```

The argument should be one of:
- A feature name (e.g., "reconciliation", "hints")
- A file path (e.g., "src/Fina.Cli/Commands/Register/RegisterReconcileCommand.cs")
- An identifier from the drift report (e.g., "unspecced-3")

## Workflow

### 1. Discover Feature Scope

Find all files related to the feature:
- Commands with that name
- Services with that name
- Tests for that feature
- Any existing documentation

### 2. Analyze Implementation

Read discovered files and extract:

**From Commands:**
- Command name and description
- Options and arguments
- Validation rules
- Error handling

**From Services:**
- Public methods (become requirements)
- Business logic rules
- Dependencies on other services
- Edge case handling

**From Tests:**
- Test scenarios (become acceptance scenarios)
- Expected behaviors
- Edge cases tested

**From Existing Docs:**
- Any informal documentation
- README sections
- Comments explaining "why"

### 3. Infer User Stories

From command/service analysis, generate user stories:
```markdown
### User Story 1 - [Primary Use Case] (Priority: P1)

As a user, I want to [action from main command]
so that [benefit inferred from feature purpose].

**Acceptance Scenarios**:

1. **Given** [precondition from tests], **When** [action], **Then** [expected result].
```

### 4. Extract Requirements

Convert implementation behaviors to requirements:
- From method signatures → functional requirements
- From validation → requirements
- From business logic → requirements

### 5. Generate Spec Structure

Create spec.md with:
- Feature branch and status
- Backfill notice warning that this documents current behavior, not original intent
- User scenarios & testing
- Requirements (functional, CLI commands)
- Key entities
- Dependencies
- Success criteria
- Implementation notes

### 6. Determine Spec ID

Find next available spec number in specs/ directory. Suggest: `{next_number}-{feature-name}`

### 7. Generate Plan

Create plan.md documenting implementation architecture:
- Summary of what feature does
- Technical context (language, dependencies)
- Architecture (service layer, flow)
- Key design decisions
- Project structure
- Dependencies
- Testing
- Future considerations

### 8. Generate Quickstart

For user-facing features (CLI commands), create quickstart.md with:
- One-line description
- Prerequisites
- Basic usage
- Options table
- Examples
- Tips

Skip for internal-only features.

### 9. Output Options

**Preview Mode (default):**
Display generated spec, plan, quickstart, and tasks for review.

**Create Mode (`--create`):**
1. Create `specs/{id}/spec.md`
2. Create `specs/{id}/plan.md`
3. Create `specs/{id}/quickstart.md` (if user-facing)
4. Create `specs/{id}/tasks.md` (with review task)
5. Report location

### 10. Generate Review Task

Add a task to review the backfilled spec:

```markdown
# Tasks

## Review Backfilled Spec

- [ ] Review generated user stories for accuracy
- [ ] Verify requirements match intended behavior (not just current behavior)
- [ ] Remove implementation notes that don't belong in spec
- [ ] Add any missing requirements
- [ ] Mark spec status as "Draft" or "Approved"
```

## Notes

- Backfilled specs should always be reviewed by a human
- The spec documents current behavior, which may include bugs
- Use this as a starting point, not a final spec
- Consider whether the feature should be split into multiple specs
- plan.md documents architecture decisions; useful for onboarding
- quickstart.md is user documentation; skip for internal-only features