---

description: "Task list template for My Zodiac AI feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: The examples below include test tasks. Tests are OPTIONAL - only include them if explicitly requested in the feature specification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions (My Zodiac AI Monorepo)

- **Backend modules**: `back/src/modules/{domain}/`
- **Backend schemas**: `back/src/modules/{domain}/schemas/{entity}.schema.ts`
- **Backend DTOs**: `back/src/modules/{domain}/dto/{action}.dto.ts`
- **Backend services**: `back/src/modules/{domain}/{domain}.service.ts`
- **Backend controllers**: `back/src/modules/{domain}/{domain}.controller.ts`
- **Backend events**: `back/src/modules/{domain}/events/{event-name}.event.ts`
- **Backend listeners**: `back/src/modules/{domain}/listeners/{event-name}.listener.ts`
- **Backend adapters**: `back/src/modules/{domain}/adapters/{adapter-name}.adapter.ts`
- **Backend jobs**: `back/src/modules/{domain}/jobs/{job-name}.processor.ts`
- **Backend tests**: `back/src/modules/{domain}/__tests__/{name}.spec.ts`
- **Frontend features**: `front/src/features/{feature-name}/`
- **Frontend composables**: `front/src/features/{feature-name}/model/{name}.ts`
- **Frontend components**: `front/src/features/{feature-name}/ui/{ComponentName}.vue`
- **Frontend API**: `front/src/features/{feature-name}/api/{name}.ts`
- **Frontend entities**: `front/src/entities/{entity-name}/`
- **Frontend pages**: `front/src/pages/{PageName}.vue`
- **Frontend widgets**: `front/src/widgets/{widget-name}/`
- **Frontend shared UI**: `front/src/shared/ui/{ComponentName}.vue`
- **Frontend i18n**: `front/src/shared/i18n/locales/{lang}.json`
- **Frontend tests**: `front/src/features/{feature-name}/__tests__/{name}.spec.ts`
- **E2E tests**: `front/test/e2e/{feature}.spec.ts`

<!--
  ============================================================================
  IMPORTANT: The tasks below are SAMPLE TASKS for illustration purposes only.

  The /speckit.tasks command MUST replace these with actual tasks based on:
  - User stories from spec.md (with their priorities P1, P2, P3...)
  - Feature requirements from plan.md
  - Entities from data-model.md
  - Endpoints from contracts/

  Tasks MUST be organized by user story so each story can be:
  - Implemented independently
  - Tested independently
  - Delivered as an MVP increment

  DO NOT keep these sample tasks in the generated tasks.md file.
  ============================================================================
-->

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create Mongoose schema(s) in back/src/modules/{domain}/schemas/
- [ ] T002 [P] Create DTOs (request/response) in back/src/modules/{domain}/dto/
- [ ] T003 [P] Create FSD feature slice structure in front/src/features/{feature-name}/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 Register NestJS module in back/src/modules/{domain}/{domain}.module.ts
- [ ] T005 [P] Create domain events in back/src/modules/{domain}/events/
- [ ] T006 [P] Create adapter interfaces and injection tokens in back/src/modules/{domain}/interfaces/
- [ ] T007 [P] Create Pinia store in front/src/features/{feature-name}/model/
- [ ] T008 [P] Add i18n keys for all 10 languages in front/src/shared/i18n/locales/

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - [Title] (Priority: P1) 🎯 MVP

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 1 (OPTIONAL - only if tests requested) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T009 [P] [US1] Unit test for service in back/src/modules/{domain}/__tests__/{service}.spec.ts
- [ ] T010 [P] [US1] Component test in front/src/features/{feature-name}/__tests__/{component}.spec.ts

### Implementation for User Story 1

- [ ] T011 [P] [US1] Implement service method in back/src/modules/{domain}/{domain}.service.ts
- [ ] T012 [P] [US1] Create controller endpoint in back/src/modules/{domain}/{domain}.controller.ts
- [ ] T013 [US1] Emit domain event after DB persistence in back/src/modules/{domain}/events/
- [ ] T014 [P] [US1] Create Vue component in front/src/features/{feature-name}/ui/{Component}.vue
- [ ] T015 [US1] Create composable in front/src/features/{feature-name}/model/{useFeature}.ts
- [ ] T016 [US1] Add API integration in front/src/features/{feature-name}/api/
- [ ] T017 [US1] Add i18n keys and translations for US1
- [ ] T018 [US1] Verify dark mode and responsive layout

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- Backend [P] and Frontend [P] tasks within a story can run simultaneously

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Backend: Always emit events AFTER successful DB persistence
- Backend: Use adapter tokens for cross-module deps, never forwardRef
- Frontend: Always export through index.ts barrel files
- Frontend: All strings through vue-i18n, test dark mode
- Verify tests fail before implementing (TDD)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
