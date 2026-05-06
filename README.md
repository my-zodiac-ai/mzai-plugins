# my-zodiac-ai/mzai-plugins

Кастомные плагины и скиллы для Claude Code и Cowork — специально под стек My Zodiac AI.

## Плагины

| Плагин | Скиллов | Описание |
|--------|---------|----------|
| [`zodiac-dev-toolkit`](#zodiac-dev-toolkit) | 11 | NestJS + Vue 3 + Quasar patterns, EDA/DDD/FSD |
| [`zodiac-quality-gate`](#zodiac-quality-gate) | 8 | Аудиты: code quality, security, architecture, performance |
| [`zodiac-research-lab`](#zodiac-research-lab) | 6 | Deep research: конкуренты, UX, tech stack, метрики |
| [`zodiac-design-review`](#zodiac-design-review) | 6 | Design critique, a11y, UX/UI, Cosmic Glass tokens |
| [`astrology-data-validator`](#astrology-data-validator) | 1 | Валидация Swiss Ephemeris, регрессии |
| [`speckit`](#speckit) | 29 | Feature lifecycle: specify → plan → implement → verify |
| [`speckit-product-forge`](#speckit-product-forge) | 29 | Product Forge v1.5.0 — полный цикл фичи |
| [`cowork-plugin-management`](#cowork-plugin-management) | 2 | Создание и кастомизация плагинов |

---

## Установка

### Требования
- macOS (для Cowork) или любая ОС (для Claude Code CLI)
- `bash`, `python3`

### Быстрый старт

```bash
git clone https://github.com/my-zodiac-ai/mzai-plugins.git
cd mzai-plugins
chmod +x install.sh
./install.sh
```

Перезапусти Claude Code или Cowork — плагины подхватятся автоматически.

### Установить конкретные плагины

```bash
./install.sh zodiac-dev-toolkit speckit
```

### Посмотреть доступные плагины

```bash
./install.sh --list
```

### Удалить все плагины

```bash
./install.sh --uninstall
```

---

## Обновление

```bash
git pull
./install.sh
```

Скрипт заменяет старые версии новыми.

---

## Описание плагинов

### `zodiac-dev-toolkit`

**Complete engineering toolkit for My Zodiac AI** — NestJS + Vue 3 + Quasar monorepo с EDA/DDD/FSD паттернами, экспертиза в astrology domain, AI/LLM оркестрация, TDD.

Скиллы: `ai-llm-patterns`, `ai-provider-integration`, `api-design`, `astrology-domain`, `devops-deploy`, `nestjs-backend-patterns`, `notifications-push`, `payments-subscriptions`, `redis-caching`, `tdd-testing`, `vue-frontend-patterns`

### `zodiac-quality-gate`

**Comprehensive code quality orchestrators** — специализированные аудиторы: code quality (SOLID/DRY/YAGNI), security, architecture (EDA/DDD/FSD), performance, dependencies, refactoring. Мега-оркестратор запускает все проверки параллельно.

Скиллы: `full-quality-gate`, `code-quality-audit`, `security-audit`, `architecture-audit`, `performance-audit`, `dependency-audit`, `refactor-audit`, `testing-audit`

### `zodiac-research-lab`

**Deep feature research lab** — анализ конкурентов, UI/UX паттерны, tech stack research, анализ кодовой базы, оценка метрик и бизнес-импакта.

Скиллы: `deep-research`, `competitor-analysis`, `ux-research`, `tech-stack-research`, `codebase-analysis`, `metrics-analysis`

### `zodiac-design-review`

**Comprehensive design review system** — параллельные агенты для design critique, UX/UI review, accessibility (WCAG 2.1 AA), design system token audit, feature enhancement. Заточено под Cosmic Glass design system.

Скиллы: `comprehensive-review`, `design-critique`, `ux-ui-review`, `accessibility-audit`, `design-system-tokens`, `feature-enhancement`

### `astrology-data-validator`

**Swiss Ephemeris validator** — валидация расчётов планет, аспектов, домов и орбов. Регрессионное тестирование после обновлений sweph, сравнение астро-движков.

Скиллы: `validate-astrology`

### `speckit`

**Full feature lifecycle management** — от идеи до реализации. Orchestrates: problem discovery, research, product-spec, planning, implementation, verification, testing, security, API docs, retrospectives.

Скиллы: `specify`, `clarify`, `plan`, `tasks`, `implement`, `verify`, `review`, `cleanup`, `fleet`, `ralph`, `analyze`, `checklist`, `constitution`, `drift`, `retrospective`, `sync-*`, `v-model-*`

### `speckit-product-forge`

**Product Forge v1.5.0** — полный product lifecycle под стек My Zodiac AI (NestJS 11 + Vue 3.5 + Quasar 2.18 + MongoDB 7 + Redis 7 + Capacitor 8). Три режима: `lite`, `standard`, `v-model`. 29 скиллов.

Скиллы: `forge`, `problem-discovery`, `research`, `product-spec`, `plan`, `tasks`, `implement`, `verify-full`, `test-plan`, `test-run`, `code-review`, `release-readiness`, `retrospective`, `tracking-plan`, `monitoring-setup`, `migration-plan`, `i18n-harvest`, `experiment-design`, `feature-flag-cleanup`, `portfolio`, `backfill`, `change-request`, `security-check`, `api-docs`, `bridge`, `pre-impl-review`, `revalidate`, `status`, `sync-verify`

### `cowork-plugin-management`

**Plugin builder** — создание новых плагинов с нуля и кастомизация существующих под инструменты и воркфлоу организации.

Скиллы: `create-cowork-plugin`, `cowork-plugin-customizer`

---

## Структура репозитория

```
mzai-plugins/
├── plugins/
│   ├── zodiac-dev-toolkit/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json      # манифест плагина
│   │   ├── skills/
│   │   │   ├── nestjs-backend-patterns/
│   │   │   │   └── SKILL.md
│   │   │   └── ...
│   │   └── agents/              # агенты (если есть)
│   ├── zodiac-quality-gate/
│   ├── speckit/
│   └── ...
├── install.sh                   # установочный скрипт
└── README.md
```

---

## Добавить новый плагин

1. Создать плагин через скилл `cowork-plugin-management:create-cowork-plugin` в Cowork
2. Найти папку плагина в `~/.remote-plugins/plugin_XXXXX/`
3. Скопировать в `plugins/<имя>/`, исключив `.mcpb-cache`
4. Обновить README
5. Запушить в репо

---

## Как это работает (для тех кто не знает)

Плагины — это папки с SKILL.md файлами (Markdown-инструкции для Claude) + `plugin.json` манифест. Claude Code и Cowork подхватывают их из определённых директорий:

- **Claude Code (CLI):** `~/.claude/plugins/<имя>/`
- **Cowork (desktop):** `~/Library/Application Support/Claude/plugins/<имя>/`

Скрипт `install.sh` определяет какой клиент установлен и копирует папки в нужное место.
# mzai-plugins
