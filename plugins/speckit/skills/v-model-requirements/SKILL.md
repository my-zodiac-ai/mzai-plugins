---
name: v-model-requirements
description: >
  Generate a V-Model Requirements Specification with traceable REQ-NNN IDs from a feature
  description or existing spec.md. Use when the user asks to "generate V-model requirements",
  "create traceable requirements", "REQ-NNN IDs", "V-model spec", or needs IEEE 29148-compliant
  requirements with formal traceability.
---

# V-Model Requirements Specification Skill

Transform a feature description or existing `spec.md` into a structured V-Model Requirements Specification where **every requirement has a unique, traceable ID** (`REQ-NNN`). This document becomes the foundation of the V-Model — every requirement defined here will later be paired with acceptance test cases and executable scenarios.

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Execution Steps

### 1. Setup

Run the setup script from the repository root and parse the JSON output.

The script returns:
- `VMODEL_DIR`: Path to `specs/{feature}/v-model/` directory
- `FEATURE_DIR`: Path to `specs/{feature}/` directory
- `BRANCH`: Current branch name
- `SPEC`: Path to `spec.md` (file may not exist yet)
- `REQUIREMENTS`: Path to `requirements.md` (file may not exist yet)
- `AVAILABLE_DOCS`: Array of documents that currently exist

### 2. Load Context

1. **Load the template**: Read `templates/requirements-template.md` from the extension directory.

2. **Load the source** (in priority order):
   - If `AVAILABLE_DOCS` contains `"spec.md"`: Read `spec.md`. This is the primary source of truth.
   - If `$ARGUMENTS` is not empty: Use the user's feature description as the source.
   - If both exist: Use `spec.md` as primary source, with `$ARGUMENTS` as supplementary context.
   - If neither exists: ERROR — "No feature description or spec.md found."

3. **Load existing requirements** (if `AVAILABLE_DOCS` contains `"requirements.md"`):
   - Read the existing `requirements.md` to preserve existing IDs and content.
   - Identify the highest existing REQ number to continue the sequence.
   - New requirements append after existing ones — **never renumber**.

### 3. Generate Requirements

You are extracting and formalizing requirements. You must NOT invent, infer, or add features not present in the source material.

For each requirement identified in the source material:

1. **Assign a unique ID** using the naming convention:
   - **Functional**: `REQ-NNN` (e.g., REQ-001, REQ-002)
   - **Non-Functional**: `REQ-NF-NNN` (e.g., REQ-NF-001)
   - **Interface**: `REQ-IF-NNN` (e.g., REQ-IF-001)
   - **Constraint**: `REQ-CN-NNN` (e.g., REQ-CN-001)

2. **Write a requirement description** that satisfies ALL 8 quality criteria

3. **Assign priority**: P1 (Critical), P2 (Important), P3 (Nice-to-have)

4. **Document rationale**: Why does this requirement exist? Link to the source section

5. **Specify verification method**: Test, Inspection, Analysis, or Demonstration

### 4. Validate Requirements Quality (IEEE 29148)

Every requirement MUST satisfy **all 8 criteria** before inclusion:

1. **Unambiguous (Clear)**: Exactly one possible interpretation. Avoid subjective words (fast, user-friendly, robust, seamless, intuitive, efficient, reasonable, significant, adequate, minimal).

2. **Testable/Verifiable**: You MUST be able to design a definitive Pass/Fail test. This is the direct trigger for test generation.

3. **Atomic (Singular)**: Describes exactly one function or constraint. Must NOT contain conjunctions ("and", "or", "but", "unless") that hide a second requirement.

4. **Complete**: Contains all information needed by developer and tester. No "TBDs", missing conditions, missing thresholds, or undefined states.

5. **Consistent**: Does NOT contradict any other requirement in the specification.

6. **Traceable**: Has a unique, persistent identifier (`REQ-NNN`) and backward trace to business need.

7. **Feasible**: Technically, legally, and financially possible to build within realistic constraints.

8. **Necessary (Essential)**: Traces back to a real business, user, or safety need. If you remove it, the system would fail to meet its core objective.

### 5. Write Output

Write the complete requirements document to `{VMODEL_DIR}/requirements.md` using the template structure with:

1. **Header section**: Feature name, branch, date, source reference
2. **Overview**: Brief description of the feature's business context
3. **Requirements tables**: All four categories (Functional, Non-Functional, Interface, Constraint) — omit empty categories
4. **Assumptions**: Any reasonable defaults assumed during extraction
5. **Dependencies**: External systems or conditions
6. **Glossary**: Domain-specific terms used in requirements
7. **Summary metrics**: Total count, by priority, by verification method

### 6. Report Completion

Display a summary:
- Total requirements generated (broken down by category)
- Source used (spec.md, user input, or both)
- Any assumptions made
- Any `[NEEDS CLARIFICATION]` or `[CONFLICT]` flags that need user attention
- Path to the generated file
- Next step: Recommend running acceptance test generation

## Operating Constraints

### Strict Translation Rules

When deriving from `spec.md`:
- **DO NOT** invent new features or capabilities not in the source
- **DO NOT** add requirements based on "common sense" or "best practices" unless explicitly stated
- **DO** atomize compound statements into separate requirements
- **DO** flag genuinely ambiguous items with `[NEEDS CLARIFICATION: specific question]` (maximum 3)
- **DO** document assumptions for reasonable defaults in the Assumptions section

### ID Rules

- IDs are **permanent** — once assigned, they are never renumbered or reassigned
- Sequential numbering within each category (REQ-001, REQ-002, ...)
- When updating existing requirements, preserve all existing IDs and append new ones
- Gaps in numbering are acceptable

### Banned Words (Criterion 1: Unambiguous)

Replace these with measurable, testable language:
- fast → specific time threshold
- user-friendly → specific usability criteria
- robust → specific failure-handling behavior
- seamless → specific integration behavior
- intuitive → specific learnability criteria
- efficient → specific resource or time metrics
- reasonable → specific threshold or range
- significant → specific percentage or quantity
- adequate → specific minimum criteria
- minimal → specific maximum value
- approximately → specific range or tolerance
- scalable → specific load targets
- secure → specific security measures
- reliable → specific availability or MTBF targets
- flexible → specific extensibility or configuration points