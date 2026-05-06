---
name: v-model-architecture-design
description: >
  Decompose system components into architecture modules (ARCH-NNN). Use when
  the user asks to "V-model architecture", "architecture design", or needs
  Kruchten 4+1 views.
---

# V-Model Architecture Design Skill

Decompose a V-Model System Design (`system-design.md`) into an IEEE 42010/Kruchten 4+1-compliant Architecture Description where **every system component maps to at least one architecture module** (`ARCH-NNN`). The output organizes modules into four mandatory views (Logical, Process, Interface, Data Flow) and supports many-to-many SYS↔ARCH relationships.

## User Input

```text
$ARGUMENTS
```

## Execution Steps

### 1. Setup

Run setup script with `--require-reqs --require-system-design` flags.

Parse JSON for:
- `VMODEL_DIR`: Path to `specs/{feature}/v-model/` directory
- `REQUIREMENTS`: Path to `requirements.md`
- `SYSTEM_DESIGN`: Path to `system-design.md`

### 2. Load Context

1. **Load the template**: Read `templates/architecture-design-template.md`
2. **Load system design**: Extract all `SYS-NNN` identifiers and design views
3. **Load requirements**: For supplementary domain context
4. **Load v-model-config.yml** (if exists): For safety-critical sections
5. **Load existing architecture design** (if exists):
   - Preserve existing ARCH IDs and content
   - Identify highest ARCH number
   - New modules append — **never renumber**

### 3. Decompose System Components into Architecture Modules

You are decomposing system components into architecture modules. You must NOT invent capabilities not in `system-design.md`.

For each architecture module identified:

1. **Assign a unique ID**: `ARCH-NNN` (e.g., ARCH-001, ARCH-002)
2. **Name the module**: Short, descriptive name (e.g., "HTTP Router", "Event Dispatcher")
3. **Describe the module**: What it does, responsibility boundary, specific enough to define API contract
4. **Map parent system components**: List ALL `SYS-NNN` identifiers that this module implements
5. **Classify type**: Component | Service | Library | Utility | Adapter

#### Cross-Cutting Rules

- Infrastructure/utility modules (Logger, Thread Pool, Config Manager) use `[CROSS-CUTTING]` tag with rationale instead of SYS parent
- Every `[CROSS-CUTTING]` module MUST still have interface contracts in the Interface View
- Cross-cutting modules are NOT derived — they are legitimate architecture components

### 4. Populate IEEE 42010 Design Views

#### 4.1 Logical View (Primary)

Fill the Logical View table:

| ARCH ID | Name | Description | Parent SYS | Type | Tags |

#### 4.2 Process View

Document concurrency and process structure:
- Which ARCH modules run concurrently
- Process/thread allocation
- Mermaid sequence diagrams for key interactions

#### 4.3 Interface View

Document component interfaces:
- Public API contract for each ARCH
- Input/output parameters
- Exceptions and error conditions
- Protocol specifications

#### 4.4 Data Flow View

Document data transformations:
- How data flows between ARCH modules
- Data format specifications
- State changes

### 5. Output and Validation

Write complete architecture design to `{VMODEL_DIR}/architecture-design.md`.

Validate:
- Every SYS has at least one ARCH parent
- Every ARCH has at least one SYS parent (or is marked [CROSS-CUTTING])
- All interface contracts are complete
- Data Flow View is consistent with Process View

Report:
- Total architecture modules generated
- System coverage
- Any orphaned or uncovered items

## Notes

- Architecture Design is Level 3 of the V-Model
- Later paired with integration test cases to form Matrix C
- Many-to-many SYS↔ARCH relationships are expected
- [CROSS-CUTTING] modules support proper separation of concerns