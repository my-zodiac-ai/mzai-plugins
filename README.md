# my-zodiac-ai/mzai-plugins

Custom Claude plugins and skills for Claude Code and Cowork — built for the My Zodiac AI stack.

## Plugins

| Plugin | Skills | Description |
|--------|--------|-------------|
| [`zodiac-dev-toolkit`](#zodiac-dev-toolkit) | 11 | NestJS + Vue 3 + Quasar patterns, EDA/DDD/FSD |
| [`zodiac-quality-gate`](#zodiac-quality-gate) | 8 | Audits: code quality, security, architecture, performance |
| [`zodiac-research-lab`](#zodiac-research-lab) | 6 | Deep research: competitors, UX, tech stack, metrics |
| [`zodiac-design-review`](#zodiac-design-review) | 6 | Design critique, a11y, UX/UI, Cosmic Glass tokens |
| [`astrology-data-validator`](#astrology-data-validator) | 1 | Swiss Ephemeris validation, regression testing |
| [`speckit`](#speckit) | 29 | Feature lifecycle: specify → plan → implement → verify |
| [`speckit-product-forge`](#speckit-product-forge) | 29 | Product Forge v1.5.0 — full product lifecycle |
| [`cowork-plugin-management`](#cowork-plugin-management) | 2 | Create and customize plugins |

---

## Installation

### Requirements
- macOS (for Cowork) or any OS (for Claude Code CLI)
- `bash`, `python3`

### Quick start

```bash
git clone https://github.com/my-zodiac-ai/mzai-plugins.git
cd mzai-plugins
chmod +x install.sh
./install.sh
```

Restart Claude Code or Cowork — plugins will be picked up automatically.

### Install specific plugins

```bash
./install.sh zodiac-dev-toolkit speckit
```

### List available plugins

```bash
./install.sh --list
```

### Uninstall all plugins

```bash
./install.sh --uninstall
```

---

## Updating

```bash
git pull
./install.sh
```

The script replaces old versions with new ones.

---

## Plugin descriptions

### `zodiac-dev-toolkit`

**Complete engineering toolkit for My Zodiac AI** — NestJS + Vue 3 + Quasar monorepo with EDA/DDD/FSD patterns, astrology domain expertise, AI/LLM orchestration, TDD workflows.

Skills: `ai-llm-patterns`, `ai-provider-integration`, `api-design`, `astrology-domain`, `devops-deploy`, `nestjs-backend-patterns`, `notifications-push`, `payments-subscriptions`, `redis-caching`, `tdd-testing`, `vue-frontend-patterns`

### `zodiac-quality-gate`

**Comprehensive code quality orchestrators** — specialized auditors for code quality (SOLID/DRY/YAGNI), security, architecture (EDA/DDD/FSD), performance, dependencies, refactoring. The mega-orchestrator runs all checks in parallel.

Skills: `full-quality-gate`, `code-quality-audit`, `security-audit`, `architecture-audit`, `performance-audit`, `dependency-audit`, `refactor-audit`, `testing-audit`

### `zodiac-research-lab`

**Deep feature research lab** — competitor analysis, UI/UX patterns, tech stack research, codebase analysis, metrics and business impact assessment.

Skills: `deep-research`, `competitor-analysis`, `ux-research`, `tech-stack-research`, `codebase-analysis`, `metrics-analysis`

### `zodiac-design-review`

**Comprehensive design review system** — parallel agents for design critique, UX/UI review, accessibility (WCAG 2.1 AA), design system token audit, and feature enhancement suggestions. Tailored for the Cosmic Glass design system.

Skills: `comprehensive-review`, `design-critique`, `ux-ui-review`, `accessibility-audit`, `design-system-tokens`, `feature-enhancement`

### `astrology-data-validator`

**Swiss Ephemeris validator** — validates planet positions, aspects, houses and orbs. Regression testing after sweph updates, cross-engine comparison.

Skills: `validate-astrology`

### `speckit`

**Full feature lifecycle management** — from idea to implementation. Orchestrates: problem discovery, research, product-spec, planning, implementation, verification, testing, security, API docs, retrospectives.

Skills: `specify`, `clarify`, `plan`, `tasks`, `implement`, `verify`, `review`, `cleanup`, `fleet`, `ralph`, `analyze`, `checklist`, `constitution`, `drift`, `retrospective`, `sync-*`, `v-model-*`

### `speckit-product-forge`

**Product Forge v1.5.0** — full product lifecycle for the My Zodiac AI stack (NestJS 11 + Vue 3.5 + Quasar 2.18 + MongoDB 7 + Redis 7 + Capacitor 8). Three modes: `lite`, `standard`, `v-model`. 29 skills.

Skills: `forge`, `problem-discovery`, `research`, `product-spec`, `plan`, `tasks`, `implement`, `verify-full`, `test-plan`, `test-run`, `code-review`, `release-readiness`, `retrospective`, `tracking-plan`, `monitoring-setup`, `migration-plan`, `i18n-harvest`, `experiment-design`, `feature-flag-cleanup`, `portfolio`, `backfill`, `change-request`, `security-check`, `api-docs`, `bridge`, `pre-impl-review`, `revalidate`, `status`, `sync-verify`

### `cowork-plugin-management`

**Plugin builder** — create new plugins from scratch and customize existing ones for your team's tools and workflows.

Skills: `create-cowork-plugin`, `cowork-plugin-customizer`

---

## Repository structure

```
mzai-plugins/
├── plugins/
│   ├── zodiac-dev-toolkit/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json      # plugin manifest
│   │   ├── skills/
│   │   │   ├── nestjs-backend-patterns/
│   │   │   │   └── SKILL.md
│   │   │   └── ...
│   │   └── agents/              # agents (if any)
│   ├── zodiac-quality-gate/
│   ├── speckit/
│   └── ...
├── install.sh                   # installer script
└── README.md
```

---

## Adding a new plugin

1. Create a plugin using the `cowork-plugin-management:create-cowork-plugin` skill in Cowork
2. Find the plugin folder at `~/.remote-plugins/plugin_XXXXX/`
3. Copy it to `plugins/<name>/`, excluding `.mcpb-cache`
4. Update README
5. Push to repo

---

## How it works

Plugins are folders containing `SKILL.md` files (Markdown instructions for Claude) and a `plugin.json` manifest. Claude Code and Cowork load them from specific directories:

- **Claude Code (CLI):** `~/.claude/plugins/<name>/`
- **Cowork (desktop):** `~/Library/Application Support/Claude/plugins/<name>/`

The `install.sh` script detects which client is installed and copies the folders to the right location.
