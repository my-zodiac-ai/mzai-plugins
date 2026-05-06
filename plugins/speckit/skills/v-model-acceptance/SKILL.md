---
name: v-model-acceptance
description: >
  Generate acceptance test plans with ATP-NNN IDs and BDD scenarios. Use
  when the user asks to "generate acceptance tests", "V-model acceptance",
  or needs traceable test cases.
---

# V-Model Acceptance Test Plan Skill

Generate a **three-tier Acceptance Test Plan** that pairs every requirement (`REQ-NNN`) with:
1. **Test Cases** (`ATP-NNN-X`) — the logical validation conditions
2. **User Scenarios** (`SCN-NNN-X#`) — BDD-style (Given/When/Then) executable test paths

This enforces the V-Model's core principle: **every development requirement has a simultaneously generated, paired testing artifact**. The output achieves **100% coverage** — every requirement has at least one test case, and every test case has at least one executable scenario.

## User Input

```text
$ARGUMENTS
```

## Execution Steps

### 1. Setup

Run the setup script from repo root with `--require-reqs` flag to ensure `requirements.md` exists.

Parse JSON output for:
- `VMODEL_DIR`: Path to `specs/{feature}/v-model/` directory
- `REQUIREMENTS`: Path to `requirements.md`
- `AVAILABLE_DOCS`: Array of existing documents

### 2. Load Context

1. **Load the template**: Read `templates/acceptance-plan-template.md`
2. **Read requirements**: Parse `requirements.md` to extract all `REQ-NNN` items (all categories)
3. **Load existing acceptance plan** (if exists):
   - Preserve existing ATPs and SCNs
   - Identify which REQs already have test cases
   - Identify existing ATP/SCN IDs to avoid duplicates

### 3. Detect Incremental Changes (If Updating)

If an existing `acceptance-plan.md` is found, run the diff script:

```bash
{SCRIPTS_DIR}/diff-requirements.sh {VMODEL_DIR}
```

Parse JSON output for:
- `added`: New REQ IDs that need ATPs/SCNs
- `modified`: Changed REQs whose ATPs/SCNs must be regenerated
- `removed`: Deleted REQs whose ATPs/SCNs should be flagged

**Rules for incremental updates:**
- **Added REQs**: Generate new ATPs and SCNs, appending to existing file
- **Modified REQs**: Regenerate ATPs/SCNs for these REQs only, replace in-place
- **Removed REQs**: Add `[DEPRECATED]` tag, do NOT delete
- **Unchanged REQs**: Do NOT touch their ATPs or SCNs
- **Never renumber** existing IDs

### 4. Generate Test Cases and Scenarios (Batched)

Process requirements in **batches of 5** to prevent output degradation.

For **each requirement**:

#### 4a. Generate Test Cases (`ATP-NNN-X`)

Create one or more test cases that fully validate the requirement. Every test case MUST satisfy **all 4 quality criteria**.

- **ID format**: `ATP-{NNN}-{X}` where `NNN` matches REQ number and `X` is a letter (A, B, C)
- At minimum, generate:
  - **Happy path** (`-A`): The expected, successful behavior
  - **Error/edge case** (`-B`, `-C`, ...): Boundary conditions, invalid inputs, failure modes
- Each test case includes: ID, linked REQ, description, validation condition, and expected result

#### 4b. Generate User Scenarios (`SCN-NNN-X#`)

For each test case, generate one or more **BDD-style executable scenarios**. Every scenario MUST satisfy **all 4 quality criteria**.

- **ID format**: `SCN-{NNN}-{X}{#}` where `NNN-X` matches parent ATP and `#` is a number (1, 2, 3)
- Use strict **Given/When/Then** format
- Scenarios must be **concrete, declarative, and executable**

#### 4c. Output Structure Per Requirement

```markdown
### Requirement Validation: REQ-{NNN} ({Short Description})

#### Test Case: ATP-{NNN}-A ({Test Name})
**Linked Requirement:** REQ-{NNN}
**Description:** {What is being validated}
**Validation Condition:** {Specific pass/fail condition}
**Expected Result:** {The definitive observable outcome}

* **User Scenario: SCN-{NNN}-A1**
  * **Given** {precondition — explicit state, not assumptions}
  * **When** {single user action — declarative, not imperative}
  * **Then** {observable, verifiable outcome}
```

### 5. Quality Criteria (Mandatory)

#### Test Case Quality Criteria (ATP Tier)

Every test case MUST satisfy ALL 4 criteria:

1. **Traceable** — Directly linked to exactly one REQ
2. **Specific** — Validation condition is concrete and measurable
3. **Completeness** — All setup, action, and result states are defined
4. **Independence** — Test can execute standalone without dependencies on other tests

#### Scenario Quality Criteria (SCN Tier)

Every scenario MUST satisfy ALL 4 criteria:

1. **Structured** — Strict Given/When/Then format
2. **Concrete** — No ambiguous pronouns or implied states
3. **Executable** — An automated test framework could implement this directly
4. **Single Path** — Represents exactly one execution path through the requirement

### 6. Output and Validation

Write complete acceptance test plan to `{VMODEL_DIR}/acceptance-plan.md`.

Run validation script to confirm 100% coverage:
- Every REQ has at least one ATP
- Every ATP has at least one SCN
- No orphaned ATPs or SCNs without parent REQs

Report:
- Total test cases generated
- Total scenarios generated
- Coverage percentage
- Any orphaned or uncovered items

## Notes

- Test cases and scenarios are paired — every REQ → ATP → SCN flow
- This is white-box testing from a requirements perspective
- Scenarios are written for human understanding but are executability-ready
- Coverage is deterministic and validated at generation time