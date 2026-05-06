---
name: implement
description: >
  Execute the implementation plan by processing all tasks defined in tasks.md.
  Use when the user asks to "implement feature", "start implementation",
  "реализуй фичу", or wants to execute the task plan.
---

## User Input

```text
the user's input
```

You **MUST** consider the user input before proceeding (if not empty).

## Pre-Execution Checks

**Check for extension hooks (before implementation)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_implement` key
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

1. Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute.

2. **Check checklists status** (if FEATURE_DIR/checklists/ exists):
   - Scan all checklist files in the checklists/ directory
   - For each checklist, count total, completed, incomplete items
   - **If any checklist is incomplete**: STOP and ask user to proceed or wait
   - **If all complete**: Automatically proceed

3. Load and analyze the implementation context:
   - **REQUIRED**: Read tasks.md for the complete task list and execution plan
   - **REQUIRED**: Read plan.md for tech stack, architecture, and file structure
   - **IF EXISTS**: Read data-model.md for Mongoose schemas and relationships
   - **IF EXISTS**: Read contracts/ for REST API specifications and domain event contracts
   - **IF EXISTS**: Read research.md for technical decisions and constraints
   - **IF EXISTS**: Read quickstart.md for integration scenarios

4. **Project Setup Verification (My Zodiac AI)**:

   **Required checks for this monorepo**:
   - Verify `.gitignore` contains: `node_modules/`, `dist/`, `build/`, `*.log`, `.env*`, `coverage/`
   - Verify `back/` workspace has valid `tsconfig.json` with `"strict": true`
   - Verify `front/` workspace has valid `tsconfig.json` with `"strict": true`
   - Check that `pnpm-workspace.yaml` includes both workspaces
   - Verify `.eslintrc*` or `eslint.config.*` exists for both workspaces
   - Verify `.prettierrc*` exists

   **Do NOT create/modify**:
   - Package.json files (managed by pnpm)
   - Docker files (unless explicitly in tasks)
   - CI/CD configs (unless explicitly in tasks)

5. Parse tasks.md structure and extract:
   - **Task phases**: Setup, Foundational, User Stories, Polish
   - **Task dependencies**: Sequential vs parallel execution rules
   - **Task details**: ID, description, file paths, parallel markers [P], story labels [USn]
   - **Execution flow**: Order and dependency requirements

6. Execute implementation following the task plan:
   - **Phase-by-phase execution**: Complete each phase before moving to the next
   - **Respect dependencies**: Run sequential tasks in order, parallel tasks [P] can run together
   - **Follow TDD approach**: Execute test tasks before their corresponding implementation tasks
   - **File-based coordination**: Tasks affecting the same files must run sequentially
   - **Validation checkpoints**: Verify each phase completion before proceeding

7. Implementation execution rules (My Zodiac AI specific):
   - **Setup first**: Create Mongoose schemas, DTOs, FSD slice structure
   - **Foundational next**: Register NestJS modules, create domain events, adapter tokens, Pinia stores, i18n keys
   - **Backend patterns**:
     - Services use dependency injection (never manual instantiation)
     - Events emitted ONLY after successful DB persistence
     - Event listeners MUST be idempotent and MUST NOT throw
     - Cross-module communication via adapter interfaces + injection tokens (no forwardRef)
     - BullMQ for heavy/deferred work
   - **Frontend patterns**:
     - Vue 3 Composition API with `<script setup lang="ts">` only
     - FSD layer hierarchy: app → pages → widgets → features → entities → shared
     - All imports through barrel `index.ts` files
     - Business logic in `features/*/model/` composables, not in pages
     - All strings through `vue-i18n` (no hardcoded display strings)
     - Every component supports `body.body--dark`
     - Loading states (AppLoading/AppSkeleton), error states (EmptyState with retry), success feedback ($q.notify)

8. Progress tracking and error handling:
   - Report progress after each completed task
   - Halt execution if any non-parallel task fails
   - For parallel tasks [P], continue with successful tasks, report failed ones
   - Provide clear error messages with context for debugging
   - Suggest next steps if implementation cannot proceed
   - **IMPORTANT** For completed tasks, make sure to mark the task off as [X] in the tasks file.

9. Completion validation:
   - Verify all required tasks are completed
   - Check that implemented features match the original specification
   - Validate that tests pass (`pnpm --dir back test` and `pnpm --dir front test`)
   - Verify lint passes (`pnpm --dir back lint` and `pnpm --dir front lint`)
   - Confirm the implementation follows the technical plan and constitution
   - Report final status with summary of completed work

Note: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running the tasks skill first.

10. **Check for extension hooks**: After completion validation, check if `.specify/extensions.yml` exists in the project root.
    - If it exists, read it and look for entries under the `hooks.after_implement` key
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
