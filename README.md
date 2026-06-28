# my-zodiac-ai/mzai-plugins

Claude plugins and skills for Claude Code and Cowork — a **universal-core + thin stack-adapter** toolkit for the my-zodiac-ai org. Core skills are stack-agnostic (usable in any JS/TS repo); adapters map them onto a concrete stack; domain plugins hold product-specific knowledge.

## Plugins

| Plugin | Skills | Description |
|--------|--------|-------------|
| **Universal core** | | _stack-agnostic; usable in any JS/TS repo_ |
| [`core-engineering`](#core-engineering) | 7 | Caching, testing, load-testing, api-changelog, docker-compose, Playwright, Langfuse |
| [`ai-llm`](#ai-llm) | 2 | LLM orchestration: provider fallback, semantic cache, streaming, tool use |
| **Stack adapters** | | _map the core onto one stack_ |
| [`adapter-nestjs`](#adapter-nestjs) | 6 | NestJS: EDA/DDD, REST/DTO, Mongoose, Redis+BullMQ caching, push, fault-tolerance |
| [`adapter-vue-quasar`](#adapter-vue-quasar) | 5 | Vue 3 + Quasar + Capacitor: frontend patterns, mobile builds, bundle, Lighthouse |
| [`observability`](#observability) | 2 | NewRelic dashboards/NRQL/SLO + RUM (Core Web Vitals) |
| **Hooks & process** | | |
| [`zodiac-hooks-pack`](#zodiac-hooks-pack) | — | 8 hooks: sensitive-file block, ESLint, tsc, Prisma, GSAP, frontmatter, Serena, i18n |
| [`zodiac-quality-gate`](#zodiac-quality-gate) | 8 | Audits: code quality, security, architecture, performance |
| [`zodiac-research-lab`](#zodiac-research-lab) | 6 | Deep research: competitors, UX, tech stack, metrics |
| [`zodiac-design-review`](#zodiac-design-review) | 6 | Design critique, a11y, UX/UI, design-system tokens |
| **Product domain** | | _astrology-specific by design_ |
| [`domain-astrology`](#domain-astrology) | 2 | Swiss Ephemeris (natal/transits/synastry) + payment/subscription tiers |
| [`astrology-data-validator`](#astrology-data-validator) | 1 | Swiss Ephemeris validation, regression testing |
| **Meta** | | |
| [`cowork-plugin-management`](#cowork-plugin-management) | 2 | Create and customize plugins |

> **SDD tooling (`speckit`, `speckit-product-forge`) is NOT part of this marketplace.** It's installed separately via the SpecKit CLI — see [External SDD tooling](#external-sdd-tooling).

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
./install.sh core-engineering adapter-nestjs zodiac-quality-gate
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

### `zodiac-hooks-pack`

**Reusable Claude Code hooks** — self-detecting, fail-soft, individually disable-able. Covers: sensitive-file blocking (exit 2), ESLint `--fix` on save, `tsc`/`vue-tsc` checks, Prisma migration reminders, GSAP import guard, `@nuxt/content` frontmatter validation, Serena session nudges, and i18n hardcoded-string warnings. Wired via `hooks/hooks.json`; drop-in `examples/` per project.

### `core-engineering`

**Universal, stack-agnostic engineering skills** — work in any JS/TS repo with zero framework/domain coupling. Pair with a stack adapter for concrete syntax.

Skills: `caching-patterns`, `testing-patterns`, `load-testing`, `api-changelog`, `docker-compose-ops`, `playwright-cli`, `langfuse`

### `ai-llm`

**LLM orchestration patterns** — multi-provider fallback, semantic caching, cost optimization, streaming, tool use, prompt caching. Provider-agnostic with provider-specific notes.

Skills: `ai-llm-patterns`, `ai-provider-integration`

### `adapter-nestjs`

**NestJS adapter** — maps `core-engineering` onto NestJS: EDA/DDD module structure, REST/DTO design, Mongoose data ops, cache-manager/Redis + BullMQ caching, push notifications, fault-tolerance/chaos. Includes agents `nestjs-reviewer`, `build-resolver`.

Skills: `nestjs-backend-patterns`, `api-design`, `mongodb-ops`, `notifications-push`, `chaos-engineering`, `nestjs-caching`

### `adapter-vue-quasar`

**Vue 3 + Quasar + Capacitor adapter** — frontend patterns (Composition API, Pinia, FSD), mobile builds/signing, Vite bundle analysis, Lighthouse audits, deploy. Includes agent `vue-reviewer`. (For Nuxt, add a Nuxt adapter instead.)

Skills: `vue-frontend-patterns`, `capacitor-mobile-ops`, `bundle-analyzer`, `lighthouse-audit`, `devops-deploy`

### `observability`

**Observability adapter** — NewRelic dashboards/NRQL/SLO authoring and Real User Monitoring (Core Web Vitals). Account/app IDs read from config placeholders, never hardcoded.

Skills: `newrelic-dashboard-builder`, `rum-analytics`

### `domain-astrology`

**Astrology product domain** — Swiss Ephemeris (natal charts, transits, synastry, houses, aspects) and product payment/subscription tiers. Domain-specific by design; not for non-astrology projects.

Skills: `astrology-domain`, `payments-subscriptions`

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

### External SDD tooling

Spec-Driven Development tooling is **not vendored here** — it's distributed through the SpecKit CLI and installed per project, so it stays in sync with upstream and isn't duplicated in this marketplace.

- **SpecKit** (base SDD flow: constitution → specify → plan → tasks → implement) — [github/spec-kit](https://github.com/github/spec-kit). Install: `uvx --from git+https://github.com/github/spec-kit.git specify init` (see upstream README).
- **Product Forge** (product lifecycle extension on top of SpecKit) — [VaiYav/speckit-product-forge](https://github.com/VaiYav/speckit-product-forge). Install:
  ```bash
  specify extension add product-forge --from https://github.com/VaiYav/speckit-product-forge/archive/refs/heads/main.zip
  ```

Both are MIT-licensed. Do not copy their skills into this repo — reference the official sources above.

### `cowork-plugin-management`

**Plugin builder** — create new plugins from scratch and customize existing ones for your team's tools and workflows.

Skills: `create-cowork-plugin`, `cowork-plugin-customizer`

---

## Repository structure

```
mzai-plugins/
├── plugins/
│   ├── core-engineering/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json      # plugin manifest
│   │   ├── skills/
│   │   │   ├── caching-patterns/
│   │   │   │   └── SKILL.md
│   │   │   └── ...
│   │   └── agents/              # agents (if any)
│   ├── adapter-nestjs/
│   └── ...
├── scripts/
│   └── lint-plugins.py          # CI-1..CI-7 self-validation
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
