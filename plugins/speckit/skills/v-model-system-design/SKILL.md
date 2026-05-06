---
name: v-model-system-design
description: >
  Decompose requirements into system components (SYS-NNN) with design views.
  Use when the user asks to "V-model system design", "system decomposition",
  or needs IEEE 1016-compliant design.
---

# V-Model System Design Skill

Decompose a V-Model Requirements Specification (`requirements.md`) into an IEEE 1016-compliant Software Design Description where **every requirement maps to at least one system component** (`SYS-NNN`). The output organizes components into four mandatory design views (Decomposition, Dependency, Interface, Data Design) and supports many-to-many REQ↔SYS relationships.

## User Input

```text
$ARGUMENTS
```

## Execution Steps

### 1. Setup

Run the setup script and parse JSON for:
- `VMODEL_DIR`: Path to `specs/{feature}/v-model/` directory
- `REQUIREMENTS`: Path to `requirements.md` (MUST exist)
- `AVAILABLE_DOCS`: Array of existing documents

### 2. Load Context

1. **Load the template**: Read `templates/system-design-template.md`
2. **Load requirements**: Extract all `REQ-NNN` identifiers from `requirements.md`
3. **Load spec.md** (if exists): For supplementary domain context
4. **Load v-model-config.yml** (if exists):
   - If `domain` is set to `iso_26262`, `do_178c`, or `iec_62304`: Enable safety-critical sections
5. **Load existing system design** (if exists):
   - Preserve existing SYS IDs and content
   - Identify highest SYS number to continue sequence
   - New components append — **never renumber**

### 3. Decompose Requirements into System Components

You are decomposing requirements into architectural components. You must NOT invent capabilities not in `requirements.md`.

For each system component identified during decomposition:

1. **Assign a unique ID**: `SYS-NNN` (e.g., SYS-001, SYS-002)
2. **Name the component**: Short, descriptive name
3. **Describe the component**: What it does, responsibility boundary, specific enough to generate tests
4. **Map parent requirements**: List ALL `REQ-NNN` identifiers that this component satisfies. Many-to-many mapping is expected
5. **Classify type**: Subsystem | Module | Service | Library | Utility

#### Decomposition Guidelines

- **Functional requirements** (`REQ-NNN`): Each maps to one or more dedicated components
- **Non-functional requirements** (`REQ-NF-NNN`): Map to cross-cutting components or as additional parents
- **Interface requirements** (`REQ-IF-NNN`): Map to components that own the interface contract
- **Constraint requirements** (`REQ-CN-NNN`): Typically map to the same components as their related functional requirements

### 4. Populate IEEE 1016 Design Views

#### 4.1 Decomposition View (Primary)

Fill the Decomposition View table with all SYS components:

| SYS ID | Name | Description | Parent Requirements | Type |

#### 4.2 Dependency View

Document dependencies:
- Which SYS components depend on which other SYS components
- Identify potential circular dependencies
- Mark external dependencies

#### 4.3 Interface View

Document component interfaces:
- Public API contract for each SYS
- Input/output parameters
- Exceptions and error conditions

#### 4.4 Data Design View

Document data structures:
- Primary data entities used by each component
- Data transformations
- Persistence requirements

### 5. Output and Validation

Write complete system design to `{VMODEL_DIR}/system-design.md`.

Validate:
- Every REQ has at least one SYS parent
- Every SYS has at least one REQ parent (or is marked [CROSS-CUTTING])
- No circular dependencies in Dependency View
- All interface contracts are complete

Report:
- Total components generated
- Requirement coverage
- Any orphaned or uncovered items

## Notes

- System Design is Level 2 of the V-Model
- Later paired with system test cases to form Matrix B
- Many-to-many SYS↔REQ relationships are expected
- [CROSS-CUTTING] components (logging, caching) are legitimate architecture components