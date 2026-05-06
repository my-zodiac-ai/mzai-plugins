---
name: plan
description: >
  Generate a technical implementation plan from a feature specification. Use when
  the user asks to "create plan", "technical plan", "план реализации", or needs
  architecture decisions, data models, and contracts.
---

## User Input

```text
the user's input
```

You **MUST** consider the user input before proceeding (if not empty).

## Pre-Execution Checks

**Check for extension hooks (before planning)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_plan` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Pre-Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Mandatory hook** (`optional: false`):
    ```
    ## Extension Hooks

    **Automatic Pre-Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}

    Wait for the result of the hook command before proceeding to the Outline.
    ```
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently

## Outline

1. **Setup**: Run `.specify/scripts/bash/setup-plan.sh --json` from repo root and parse JSON for FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load context**: Read FEATURE_SPEC and `.specify/memory/constitution.md`. Load IMPL_PLAN template (already copied).

3. **Execute plan workflow**: Follow the structure in IMPL_PLAN template to:
   - Fill Technical Context (most fields are pre-filled for My Zodiac AI — only mark feature-specific unknowns as "NEEDS CLARIFICATION")
   - Fill Constitution Check section from constitution
   - Evaluate gates (ERROR if violations unjustified)
   - Phase 0: Generate research.md (resolve all NEEDS CLARIFICATION)
   - Phase 1: Generate data-model.md, contracts/, quickstart.md
   - Phase 1: Update agent context by running the agent script
   - Re-evaluate Constitution Check post-design

4. **Stop and report**: Command ends after Phase 2 planning. Report branch, IMPL_PLAN path, and generated artifacts.

5. **Check for extension hooks**: After reporting, check if `.specify/extensions.yml` exists in the project root.
   - If it exists, read it and look for entries under the `hooks.after_plan` key
   - If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
   - Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
   - For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
     - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
     - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
   - For each executable hook, output the following based on its `optional` flag:
     - **Optional hook** (`optional: true`):
       ```
       ## Extension Hooks

       **Optional Hook**: {extension}
       Command: `/{command}`
       Description: {description}

       Prompt: {prompt}
       To execute: `/{command}`
       ```
     - **Mandatory hook** (`optional: false`):
       ```
       ## Extension Hooks

       **Automatic Hook**: {extension}
       Executing: `/{command}`
       EXECUTE_COMMAND: {command}
       ```
   - If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently

## Phases

### Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:
   - For My Zodiac AI, the core stack is known (NestJS 11, Vue 3, MongoDB, Redis, BullMQ)
   - Focus research on feature-specific unknowns: new libraries, astrology algorithms, AI prompt patterns
   - For each NEEDS CLARIFICATION → research task
   - For each new dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:

   ```text
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context} in My Zodiac AI"
   For each new technology/library:
     Task: "Find best practices for {tech} with NestJS/Vue 3 monorepo"
   For astrology-specific features:
     Task: "Research {astrology concept} implementation with Swiss Ephemeris"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

### Phase 1: Design & Contracts

**Prerequisites:** `research.md` complete

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable
   - **My Zodiac AI format**: Use Mongoose schema conventions (SchemaFactory, @Prop decorators)
   - Include MongoDB indexes for query filter/sort fields
   - Define cache key patterns following `{module}:{entity}:{id}` convention

2. **Define interface contracts** → `/contracts/`:
   - **Backend REST API**: NestJS controller endpoints with DTOs
     - Request DTOs with class-validator decorators
     - Response DTOs with class-transformer
     - Swagger/OpenAPI annotations
   - **Domain Events**: Event payload interfaces for cross-module communication
   - **Frontend API**: TypeScript interfaces for API responses + Pinia store shape
   - **i18n contracts**: Translation key structure for all 10 languages

3. **Architecture decisions** specific to My Zodiac AI:
   - Which bounded context module owns this feature?
   - What domain events need to be emitted/consumed?
   - Are cross-module adapter tokens needed?
   - What BullMQ jobs are needed for deferred work?
   - What caching strategy applies (L1/L2/L3)?
   - Which FSD layer does the frontend code belong to?

4. **Agent context update**:
   - Run `.specify/scripts/bash/update-agent-context.sh claude`
   - Update the appropriate agent-specific context file
   - Add only new technology from current plan
   - Preserve manual additions between markers

**Output**: data-model.md, /contracts/*, quickstart.md, agent-specific file

## Key rules

- Use absolute paths
- ERROR on gate failures or unresolved clarifications
- Backend code MUST follow EDA/DDD patterns (events after DB persist, adapter tokens)
- Frontend code MUST follow FSD (one-way imports, barrel exports, no cross-feature deps)
- All user-facing strings through vue-i18n
- All new components MUST support dark mode
