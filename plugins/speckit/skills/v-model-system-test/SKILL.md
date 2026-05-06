---
name: v-model-system-test
description: >
  Generate system test specifications (STP-NNN) for system components. Use
  when the user asks to "V-model system tests", "system test specs", or needs
  end-to-end test cases.
---

# V-Model System Test Plan Skill

Generate an ISO 29119-compliant System Test Plan where **every system component** (`SYS-NNN`) from `system-design.md` has at least one test case (`STP-NNN-X`) and every test case has at least one executable system scenario (`STS-NNN-X#`). System tests verify that the **architecture works as designed** — they target IEEE 1016 design views.

## User Input

```text
$ARGUMENTS
```

## Execution Steps

### 1. Setup

Run setup script with `--require-reqs --require-system-design` flags.

Parse JSON for:
- `VMODEL_DIR`: Path to `specs/{feature}/v-model/` directory
- `SYSTEM_DESIGN`: Path to `system-design.md`

### 2. Load Context

1. **Load the template**: Read `templates/system-test-template.md`
2. **Load system design**: Extract all `SYS-NNN` identifiers from Decomposition View
3. **Load requirements**: For context on what each requirement demands
4. **Load v-model-config.yml** (if exists): For safety-critical test sections
5. **Load existing system tests** (if exists):
   - Preserve existing STP/STS IDs
   - Identify highest STP number

### 3. Generate System Test Cases

For each `SYS-NNN` component in the Decomposition View, generate one or more test cases using ISO 29119 techniques.

#### Technique Selection (Based on Design Views)

- **Decomposition View**: Component structure testing
- **Dependency View**: Fault injection between components
- **Interface View**: Interface contract testing
- **Data Design View**: Boundary value analysis on component data

#### 3.1 Test Case Structure

For each system test case:
1. **Assign ID**: `STP-{NNN}-{X}` where NNN matches SYS number
2. **Name the test**: Describe what component behavior is tested
3. **Document what is tested**: Which design view(s) are verified
4. **Document test setup**: How to initialize the system and component
5. **Document test execution**: How the component is exercised
6. **Document assertions**: What component contract is verified

### 4. Generate System Test Scenarios

For each test case, generate one or more **executable system scenarios**.

Scenarios should focus on:
- Component functionality
- Component contract compliance
- Data transformation correctness
- Error handling

Format: `STS-{NNN}-{X}{#}`

### 5. Quality Criteria

Every test case MUST satisfy quality criteria:

- **Design-Focused**: Tests a specific design view of the component
- **Comprehensive**: Covers happy path and error cases
- **Deterministic**: Produces consistent results
- **Executable**: Can be automated in test framework

### 6. Output and Validation

Write complete system test plan to `{VMODEL_DIR}/system-test.md`.

Validate:
- Every SYS has at least one STP
- Every STP has at least one STS
- All design views are covered

Report:
- Total test cases generated
- Component coverage
- Design view coverage
- Recommended techniques

## Notes

- System tests are Level 2.5 of the V-Model (right side)
- Form Matrix B: SYS → STP → STS
- Test system component design, not internal logic
- Verify that system architecture works as designed