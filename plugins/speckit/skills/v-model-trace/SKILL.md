---
name: v-model-trace
description: >
  Build a bidirectional requirements traceability matrix (REQ -> ATP -> SCN).
  Use when the user asks to "traceability matrix", "V-model trace", or needs
  gap and orphan analysis.
---

# V-Model Traceability Matrix Skill

Build a **regulatory-grade Bidirectional Requirements Traceability Matrix (RTM)** that provides a complete, auditable trail between every requirement, its test cases, and executable scenarios. This is the single most scrutinized document during a compliance audit.

## User Input

```text
$ARGUMENTS
```

## Goal

Enforce the **4 Pillars of Regulatory-Grade Traceability** recognized by DO-178C, ISO 26262, IEC 62304, FDA 21 CFR Part 820, and IEC 61508:

### Pillar 1: Strict Bidirectionality

- **Forward Traceability (REQ → ATP → SCN):** Proves every requirement has been tested
- **Backward Traceability (SCN → ATP → REQ):** Proves every test maps back to a justified requirement

### Pillar 2: Orphan & Gap Analysis

- **Gaps:** A `REQ` with no `ATP`. The system is incomplete — untested functionality.
- **Orphans:** An `ATP` or `SCN` with no `REQ`. The system has undocumented behavior.

### Pillar 3: Versioning and Baselines

Artifact hashes or timestamps proving the matrix reflects CURRENT requirements and test plans.

### Pillar 4: Granular Execution State

- `⬜ Pending Execution` — Test case exists but has not been run
- `✅ Passed` — Test executed and passed
- `❌ Failed` — Test executed and failed
- `🚫 Blocked` — Test cannot be executed due to a dependency
- `⏸️ Deferred` — Test intentionally deferred with justification

## Execution Steps

### 1. Setup

Run the setup script with `--require-reqs --require-acceptance` flags.

Parse JSON output for:
- `VMODEL_DIR`: Path to `specs/{feature}/v-model/` directory
- `REQUIREMENTS`: Path to `requirements.md`
- `ACCEPTANCE`: Path to `acceptance-plan.md`

### 2. Build the Matrix (Deterministic Script)

Run the matrix builder script:

```bash
{SCRIPTS_DIR}/build-matrix.sh {VMODEL_DIR} --output {VMODEL_DIR}/traceability-matrix.md
```

The script:
1. Parses `requirements.md` for all REQ IDs and descriptions
2. Parses `acceptance-plan.md` for all ATP IDs, descriptions, and linked SCN IDs
3. Cross-references forward (REQ → ATP → SCN) and backward (SCN → ATP → REQ)
4. Identifies gaps (uncovered REQs) and orphans (unlinked ATPs/SCNs)
5. If `system-design.md` and `system-test.md` exist, generates Matrix B (Verification)
6. If `architecture-design.md` and `integration-test.md` exist, generates Matrix C (Integration Verification)
7. If `module-design.md` exists with `architecture-design.md`, generates Matrix D (Implementation Verification)
8. Generates the complete traceability matrix with coverage metrics

### 3. Analyze Results

The output provides **Quadruple-Matrix** structure:
- **Matrix A — Validation (User View):** REQ → ATP → SCN. Always present.
- **Matrix B — System Verification:** SYS → STP → STS (if system design exists)
- **Matrix C — Integration Verification:** ARCH → ITP → ITS (if architecture design exists)
- **Matrix D — Implementation Verification:** MOD → UTP → UTS (if module design exists)

### 4. Report Findings

Generate report with:

```markdown
# V-Model Traceability Matrix

Generated: [timestamp]
Feature: [feature name]
Baseline: [file hashes]

## Coverage Summary

| Dimension | Total | Covered | Gap Count | Gap % |
|-----------|-------|---------|-----------|-------|
| Requirements | X | X | X | X% |
| Test Cases | X | X | 0 | 0% |
| Scenarios | X | X | 0 | 0% |

## Bidirectional Traceability

### Forward (REQ → ATP → SCN)

[Matrix showing forward traceability with any gaps]

### Backward (SCN → ATP → REQ)

[Matrix showing backward traceability with any orphans]

## Gap Analysis

### Uncovered Requirements (Gaps)

[List any REQs without ATP]

### Orphaned Test Cases (Unlinked)

[List any ATPs/SCNs without REQ]

## Execution Status

[Status for each test case]

## Compliance Assessment

[Assessment against regulatory standards]
```

### 5. Save Output

Write to:
- `{VMODEL_DIR}/traceability-matrix.md`
- `{VMODEL_DIR}/traceability-matrix.json` (machine-readable)

## Notes

This is a **read-only analysis** command — it generates a report but does NOT modify `requirements.md` or `acceptance-plan.md`.

## Next Steps

- If gaps exist: Use acceptance test generation to create missing tests
- If orphans exist: Update requirements or remove unlinked tests
- Review bidirectional traceability for completeness
- Use for compliance audits and certification