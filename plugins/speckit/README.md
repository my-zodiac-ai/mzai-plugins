# SpecKit Plugin

Full feature lifecycle management from idea to implementation.

## Overview

SpecKit orchestrates the complete feature development process with human-in-the-loop checkpoints at every stage. From writing specifications to verification, each phase has dedicated tooling.

## Core Skills

| Skill | Trigger Phrases | Description |
|-------|----------------|-------------|
| specify | "create spec", "write specification", "new feature" | Create feature specification from description |
| clarify | "clarify spec", "clarify requirements" | Identify and resolve spec ambiguities |
| plan | "create plan", "technical plan" | Generate technical implementation plan |
| tasks | "generate tasks", "create task list" | Break plan into actionable tasks |
| implement | "implement feature", "start implementation" | Execute tasks from tasks.md |
| analyze | "analyze consistency", "cross-artifact analysis" | Check spec/plan/tasks consistency |
| verify | "verify implementation", "post-implementation check" | Validate code against spec |
| checklist | "create checklist", "quality checklist" | Generate domain-specific checklists |
| constitution | "update constitution", "project principles" | Manage project constitution |

## Orchestration

| Skill | Trigger Phrases | Description |
|-------|----------------|-------------|
| fleet | "fleet run", "full lifecycle", "orchestrate feature" | Full 10-phase lifecycle orchestrator |
| ralph | "ralph run", "autonomous loop" | Autonomous implementation loop |

## Product Forge — Full Feature Lifecycle (v1.4.0)

| Skill | Trigger Phrases | Description |
|-------|----------------|-------------|
| product-forge-forge | "forge feature", "full cycle", "product-forge" | 14-phase lifecycle orchestrator |
| product-forge-research | "research feature" | Adaptive research (competitors, UX, codebase + constraints + events) |
| product-forge-product-spec | "create product spec" | Interactive product spec creation |
| product-forge-revalidate | "revalidate spec" | Iterative review with decision log + drift detection |
| product-forge-bridge | "bridge to speckit" | Research → spec.md with type detection, NFR contracts, EDA patterns |
| product-forge-plan | "create plan", "technical plan" | Plan with constitution compliance checks |
| product-forge-tasks | "generate tasks" | Task breakdown |
| product-forge-pre-impl-review | "pre-impl review" | Design + architecture + risk before coding *(Phase 5C)* |
| product-forge-implement | "implement feature" | Implementation from tasks |
| product-forge-code-review | "code review" | Multi-dimensional code review *(Phase 6B)* |
| product-forge-verify-full | "verify full" | 6-layer traceability verification |
| product-forge-test-plan | "create test plan" | Test plan generation *(Phase 8A)* |
| product-forge-test-run | "run tests" | Playwright test execution with bug loop *(Phase 8B)* |
| product-forge-release-readiness | "release readiness", "ready to ship?" | Pre-ship checklist *(Phase 9)* |
| product-forge-sync-verify | "sync verify", "artifact drift" | 7-layer consistency checker *(cross-cutting)* |
| product-forge-change-request | "change request", "scope change" | Formal CR-NNN change management *(cross-cutting)* |
| product-forge-status | "forge status" | Show lifecycle progress |
| product-forge-problem-discovery | "discover problem" | JTBD analysis *(Phase 0)* |
| product-forge-security-check | "security check" | OWASP feature audit |
| product-forge-api-docs | "generate API docs" | OpenAPI 3.1 + Postman collection |
| product-forge-tracking-plan | "tracking plan" | Analytics event taxonomy |
| product-forge-retrospective | "retrospective" | Post-launch metrics vs predictions |

## Quality & Review

| Skill | Trigger Phrases | Description |
|-------|----------------|-------------|
| cleanup | "cleanup", "quality gate" | Post-implementation quality gate |
| review | "comprehensive review", "PR review" | Multi-agent code review |
| retrospective | "retrospective", "lessons learned" | Post-implementation retrospective |
| drift | "spec drift", "analyze drift" | Detect spec-code divergence |

## Sync Skills

| Skill | Description |
|-------|-------------|
| sync-analyze | Analyze drift between specs and code |
| sync-apply | Apply proposed spec changes |
| sync-backfill | Backfill specs from existing code |
| sync-conflicts | Detect and resolve sync conflicts |
| sync-propose | Propose spec updates from code changes |

## V-Model Skills

| Skill | Description |
|-------|-------------|
| v-model-requirements | Generate V-Model requirements |
| v-model-acceptance | Generate acceptance tests |
| v-model-trace | Traceability matrix |
| v-model-system-design | System-level design |
| v-model-module-design | Module-level design |
| v-model-architecture-design | Architecture design |
| v-model-unit-test | Unit test specifications |
| v-model-integration-test | Integration test specifications |
| v-model-system-test | System test specifications |

## Bundled Resources

- `scripts/bash/` — Shell scripts for feature creation, prerequisites check, plan setup
- `templates/` — Markdown templates for spec, plan, tasks, checklists, constitution
- `memory/constitution.md` — Project constitution
- `config/` — Configuration files

## Setup

This plugin works with an existing `.specify/` directory in your project. The scripts and templates are bundled for reference, but the skills primarily interact with your project's `.specify/` directory.

## Usage

Invoke any skill by describing what you want to do. For example:
- "I want to create a specification for a new user authentication feature"
- "Run the full fleet lifecycle for my feature"
- "Analyze drift between my spec and implementation"
