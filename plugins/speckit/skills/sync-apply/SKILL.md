---
name: sync-apply
description: >
  Apply approved drift resolutions to specs and generate implementation tasks.
  Use when the user asks to "sync apply", "apply resolutions", or wants to
  execute proposed sync fixes.
---

# Spec Sync: Apply Resolutions Skill

Apply approved resolutions from the proposals file. Updates specs or generates implementation tasks based on approval status.

## User Input

```text
$ARGUMENTS
```

## Prerequisites

1. Run sync-analyze to generate drift report
2. Run sync-propose to generate proposals
3. Review and mark proposals as approved in `.specify/sync/proposals.json`

## Workflow

### 1. Load Approved Proposals

Read proposals and filter to those marked `approved: true`.

If no proposals are approved:
- In interactive mode: prompt to review proposals first
- In batch mode: exit with "No approved proposals to apply"

### 2. Apply Backfill Proposals

For each approved BACKFILL proposal:

1. Read the original spec file
2. Locate the requirement being updated
3. Replace with proposed text
4. Add any new acceptance scenarios
5. Update spec's "Status" or "Last Modified" metadata
6. Write the updated spec

### 3. Apply New Spec Proposals

For each approved NEW_SPEC proposal:

1. Create new spec directory: `specs/{spec-id}/`
2. Write `spec.md` with generated content
3. Create empty `tasks.md` placeholder
4. Add to git (if in a git repo)

### 4. Generate Implementation Tasks for Align Proposals

For ALIGN proposals (spec → code), don't modify code directly. Instead:

1. Generate a task file: `.specify/sync/align-tasks.md`
2. Each task describes the code change needed
3. Optionally create GitHub issues if `--create-issues` is passed

### 5. Handle Supersede Resolutions

For SUPERSEDE proposals:

1. Add `superseded_by` field to old spec metadata
2. Add cross-reference in new spec
3. Optionally mark old spec as deprecated

### 6. Generate Apply Report

Create report with:
- Specs updated and changes made
- New specs created
- Implementation tasks generated
- Proposals not applied

### 7. Save Report

Write to:
- `.specify/sync/apply-report.md`
- `.specify/sync/apply-report.json`

## Options

- `--dry-run`: Show what would be applied without making changes
- `--create-issues`: Create GitHub issues for ALIGN tasks
- `--auto-commit`: Commit spec changes automatically
- `--spec <id>`: Apply only proposals for a specific spec

## Safety

- Always creates backups before modifying specs
- Backups stored in `.specify/sync/backups/`
- Use `--dry-run` first to preview changes
- All changes are logged for audit