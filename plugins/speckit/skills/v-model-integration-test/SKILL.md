---
name: v-model-integration-test
description: >
  Generate integration test specifications (ITP-NNN) for architecture
  boundaries. Use when the user asks to "V-model integration tests",
  "integration test specs", or needs interface testing.
---

# V-Model Integration Test Plan Skill

Generate an ISO 29119-compliant Integration Test Plan where **every architecture module** (`ARCH-NNN`) from `architecture-design.md` has at least one test case (`ITP-NNN-X`) and every test case has at least one executable integration scenario (`ITS-NNN-X#`). Integration tests verify the **seams and handshakes between modules** — they target architecture module boundaries.

## Critical Distinction

Integration tests do NOT test internal module logic (that's unit testing) and do NOT test user journeys (that's acceptance testing). They test the INTERFACES BETWEEN modules.

## User Input

```text
$ARGUMENTS
```

## Execution Steps

### 1. Setup

Run setup script with `--require-reqs --require-architecture-design` flags.

Parse JSON for:
- `VMODEL_DIR`: Path to `specs/{feature}/v-model/` directory
- `ARCH_DESIGN`: Path to `architecture-design.md`

### 2. Load Context

1. **Load the template**: Read `templates/integration-test-template.md`
2. **Load architecture design**: Extract ALL `ARCH-NNN` identifiers
3. **Load v-model-config.yml** (if exists): For safety-critical test sections
4. **Load existing integration tests** (if exists):
   - Preserve existing ITP/ITS IDs
   - Identify highest ITP number

### 3. Generate Integration Test Cases

For each `ARCH-NNN` module in the Logical View, generate one or more test cases using ISO 29119 techniques.

#### Technique Selection (Based on Architecture Views)

- **Interface Contract Testing**: From Interface View
- **Data Flow Testing**: From Data Flow View
- **Concurrency & Race Condition Testing**: From Process View
- **Fault Injection Testing**: Simulate failures between modules

#### 3.1 Test Case Structure

For each integration test case:
1. **Assign ID**: `ITP-{NNN}-{X}` where NNN matches ARCH number
2. **Name the test**: Describe what interface is being tested
3. **List dependencies**: Which other ARCH modules are involved
4. **Document test setup**: How to initialize modules and stubs
5. **Document test execution**: How modules interact
6. **Document assertions**: What interface contract is verified

### 4. Generate Integration Test Scenarios

For each test case, generate one or more **executable integration scenarios**.

Scenarios should focus on:
- Module-to-module communication
- Data passing through interfaces
- Error handling at boundaries
- Concurrency scenarios

Format: `ITS-{NNN}-{X}{#}`

### 5. Quality Criteria

Every test case MUST satisfy quality criteria:

- **Interface-Focused**: Tests a specific boundary between modules
- **Independent**: Can execute standalone with appropriate stubs
- **Deterministic**: Produces consistent results
- **Repeatable**: Can be run multiple times

### 6. Output and Validation

Write complete integration test plan to `{VMODEL_DIR}/integration-test.md`.

Validate:
- Every ARCH has at least one ITP
- Every ITP has at least one ITS
- All interface contracts are tested

Report:
- Total test cases generated
- Module boundary coverage
- Recommended techniques per interface

## Notes

- Integration tests are Level 4.5 of the V-Model (right side)
- Form Matrix C: ARCH → ITP → ITS
- Focus on module seams, not internal logic
- Test actual or simulated module interactions