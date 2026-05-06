---
name: v-model-module-design
description: >
  Decompose architecture into low-level module designs (MOD-NNN). Use when
  the user asks to "V-model module design", "module decomposition", or needs
  detailed algorithmic design.
---

# V-Model Module Design Skill

Decompose a V-Model Architecture Design (`architecture-design.md`) into a DO-178C/ISO 26262-compliant Module Design where **every architecture module** (`ARCH-NNN`) maps to at least one low-level module specification (`MOD-NNN`). Each module is documented with four mandatory views detailed enough that writing actual source code is merely a translation exercise.

## Critical Distinction

Module Design is NOT architecture. It does NOT describe module boundaries, interfaces, or data flows — those are in `architecture-design.md`. Module Design describes the **internal logic, state, data structures, and error handling** of each individual module.

## User Input

```text
$ARGUMENTS
```

## Execution Steps

### 1. Setup

Run setup script with `--require-reqs --require-architecture-design` flags.

Parse JSON for:
- `VMODEL_DIR`: Path to `specs/{feature}/v-model/` directory
- `REQUIREMENTS`: Path to `requirements.md`
- `ARCH_DESIGN`: Path to `architecture-design.md`

### 2. Load Context

1. **Load the template**: Read `templates/module-design-template.md`
2. **Load architecture design**: Extract ALL `ARCH-NNN` identifiers from Logical View
3. **Load requirements**: For supplementary domain context
4. **Load v-model-config.yml** (if exists): For safety-critical sections
5. **Load existing module design** (if exists):
   - Preserve existing MOD IDs
   - Identify highest MOD number
   - New modules append — **never renumber**

### 3. Decompose Architecture Modules into Module Designs

For each `ARCH-NNN` module in the Logical View, create one or more `MOD-NNN` module specifications.

Each `MOD-NNN` represents a single function, class, script, or tightly coupled file group that will become actual source code.

1. **Assign a unique ID**: `MOD-NNN`
2. **Name the module**: Matches implementation file or class name
3. **Describe the module**: What it does, responsibilities
4. **Map parent architecture module**: The ARCH-NNN this MOD implements
5. **Classify type**: Function | Class | Service | Library | Utility

### 4. Populate Four Mandatory Views

#### 4.1 Algorithmic/Logic View

- Algorithm description
- Control flow (decision trees, loops)
- State machines (if applicable)
- Entry/exit points

#### 4.2 State Machine View (if applicable)

- States and transitions
- State variables
- Transition conditions

#### 4.3 Internal Data Structures View

- Local variables
- Data structures (arrays, maps, trees)
- Type definitions
- Initialization/cleanup

#### 4.4 Error Handling & Return Codes View

- Exceptions or error codes
- Error recovery strategies
- Resource cleanup on failure
- Logging and diagnostics

### 5. Output and Validation

Write complete module design to `{VMODEL_DIR}/module-design.md`.

Validate:
- Every ARCH has at least one MOD parent
- Every MOD has at least one ARCH parent
- All four views are populated
- Algorithmic complexity is documented

Report:
- Total modules generated
- Architecture coverage
- Any orphaned or uncovered items

## Notes

- Module Design is Level 4 of the V-Model
- Later paired with unit test cases to form Matrix D
- The level of detail should enable a developer to write code without further design decisions
- Internal logic is documented in sufficient detail for unit test generation