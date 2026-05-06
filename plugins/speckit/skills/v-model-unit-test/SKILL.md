---
name: v-model-unit-test
description: >
  Generate unit test specifications (UTP-NNN) for modules. Use when the user
  asks to "V-model unit tests", "generate unit test specs", or needs
  white-box test cases.
---

# V-Model Unit Test Plan Skill

Generate an ISO 29119-4-compliant Unit Test Plan where **every module** (`MOD-NNN`) from `module-design.md` has at least one test case (`UTP-NNN-X`) and every test case has at least one executable unit scenario (`UTS-NNN-X#`). Unit tests are **white-box** — they verify internal control flow, data transformations, state transitions, and variable boundaries inside each module.

## Critical Distinction

Unit tests do NOT test module boundaries or interfaces (that's integration testing), do NOT test user journeys (that's acceptance testing), and do NOT test system-level behavior (that's system testing). They test the **internal logic of individual modules**.

## User Input

```text
$ARGUMENTS
```

## Execution Steps

### 1. Setup

Run setup script with `--require-reqs --require-module-design` flags.

Parse JSON for:
- `VMODEL_DIR`: Path to `specs/{feature}/v-model/` directory
- `MODULE_DESIGN`: Path to `module-design.md`

### 2. Load Context

1. **Load the template**: Read `templates/unit-test-template.md`
2. **Load module design**: Extract ALL `MOD-NNN` identifiers and their four views
3. **Load v-model-config.yml** (if exists): For safety-critical techniques
4. **Load existing unit tests** (if exists):
   - Preserve existing UTP/UTS IDs
   - Identify highest UTP number
   - New test cases append — **never renumber**

### 3. Generate Unit Test Cases

For each `MOD-NNN` module, generate one or more test cases using ISO 29119-4 white-box techniques.

#### Technique Selection (Based on Module Views)

- **Statement & Branch Coverage**: From Algorithmic/Logic View
- **Boundary Value Analysis (BVA)**: From Internal Data Structures View
- **Equivalence Partitioning**: From Algorithmic/Logic View
- **State Transition Testing**: From State Machine View (if applicable)
- **Fault Injection**: From Error Handling View

#### 3.1 External Module Bypass

For `[EXTERNAL]` modules, generate edge cases and boundary conditions only. Skip algorithmic coverage.

#### 3.2 Cross-Cutting Module Isolation

For `[CROSS-CUTTING]` modules, generate interface contract tests with stubs/mocks for dependencies.

### 4. Generate Unit Test Scenarios

For each test case, generate one or more **executable unit scenarios** with:

- **ID format**: `UTS-{NNN}-{X}{#}` where `NNN-X` matches parent UTP
- **Setup**: Initialize variables, stubs, mocks
- **Execute**: Call the function/method under test
- **Assert**: Verify output, state, side effects

### 5. Quality Criteria

Every test case and scenario MUST satisfy quality criteria before inclusion:

- **Traceable**: Directly linked to a MOD
- **Independent**: Can execute standalone
- **Specific**: Validates one aspect of behavior
- **Repeatable**: Produces consistent results

### 6. Output and Validation

Write complete unit test plan to `{VMODEL_DIR}/unit-test.md`.

Validate:
- Every non-[EXTERNAL] MOD has at least one UTP
- Every UTP has at least one UTS
- Coverage metrics calculated

Report:
- Total test cases generated
- Module coverage
- Recommended techniques per module

## Notes

- Unit tests are Level 5 of the V-Model (right side)
- Form Matrix D: MOD → UTP → UTS
- White-box techniques enable high code coverage
- ISO 29119-4 defines five primary techniques