# mzai-plugins — Жёсткий технический разбор (критика)

> **Дата:** 2026-06-28
> **Объём:** все 9 плагинов marketplace + install.sh + README + marketplace.json + reports/
> **Метод:** прочитаны все SKILL.md, agents, hooks, шаблоны, скрипты; ключевые claim'ы перепроверены напрямую по исходникам (file:line); внешние практики сверены с GitHub spec-kit и Anthropic Agent Skills docs.
> **Тон:** без лести, по фактам. Каждое утверждение привязано к конкретному файлу.

> **ОБНОВЛЕНО 2026-06-28:** `speckit` и `speckit-product-forge` **удалены из этого репозитория** — они устанавливаются отдельно как SpecKit-инструменты ([github/spec-kit](https://github.com/github/spec-kit) + [VaiYav/speckit-product-forge](https://github.com/VaiYav/speckit-product-forge) через `specify extension add`), это не Claude-плагины и им не место в marketplace. Разбор этих двух ниже **сохранён как обоснование выноса и фидбек для апстрима**, но к текущему репо (теперь **7 плагинов**) больше не относится. Доп. подтверждение дрейфа: vendored-копия была помечена `v1.5.0`, тогда как официальный последний релиз — `v1.3.0` (apr 2026).

---

## 0. TL;DR — главное

1. **Это не «универсальный тулкит», это приватный мануал по `my_zodiac_ai`, переупакованный в плагины.** Из 23 скиллов `zodiac-dev-toolkit` реально портируемы только **2** (`langfuse`, `playwright-cli`) — и то лишь потому, что они скопированы дословно из Anthropic-reference и в них не успели вписать астрологию.
2. **Захардкожена инфраструктурная идентичность прямо в тела скиллов:** NewRelic account `7715788`, NewRelic Browser `appId=538822289` (внутри NRQL `WHERE appId = ...`), живой MCP-хэш `mcp__3dc9ae8a-...`, имя БД `my_zodiac_ai`, два разных bundle ID одного приложения. Это делает скиллы и их eval'ы неработающими в любом другом репозитории без ручной хирургии.
3. **`speckit-product-forge` не запускается как задумано:** оркестратор `forge` и 12 других скиллов 50+ раз ссылаются на `../docs/*` (policy.md, runtime.md, schema.md, phase-digest…), а каталога `docs/` в плагине **нет вообще**. Весь «operating contract» оркестратора — висячие ссылки.
4. **`speckit` — главный блокатор портируемости:** его шаблоны и 6 ключевых скиллов (`tasks`, `plan`, `implement`, `verify`, `review`, `fleet`) написаны под `my_zodiac_ai` (хардкод `back/`+`front/`, NestJS/Vue/Quasar/Mongoose/Swiss Ephemeris). А `forge` делегирует в `speckit`, поэтому связанность «протекает» снизу вверх.
5. **Два advisory-хука физически мертвы.** `gsap-import-guard.sh` и `i18n-key-checker.sh` никогда не срабатывают из-за бага чтения stdin в subshell (`lib/_common.sh:20-27`). Smoke-тест даёт ложный «зелёный», потому что не проверяет позитивный сценарий.
6. **Дублирование «скилл↔агент» как система:** в `quality-gate` 7 пар, в `design-review` 5 пар. Агенты — lossy-копии своих же скиллов, добавляют почти ноль. Это ×2 поверхность поддержки за ×1 контента, и копии уже разошлись.
7. **`zodiac-research-lab` — тонкий рескин:** 6 из 6 скиллов имеют одноимённые встроенные/Anthropic-скиллы (`deep-research`, `competitor-analysis`, `ux-research`, `tech-stack-research`, `codebase-analysis`, `metrics-analysis`). Уникально — только астрологическая обёртка.
8. **`astrology-data-validator`** — reference-данные без провенанса, есть значения, собранные руками (Moon = Sun + ровно 180.00; `longitude: 20.0` как заглушка). Плагину место в продуктовом репо, а не в общем marketplace.
9. **Документация врёт:** README заявляет `zodiac-dev-toolkit` = 11 скиллов (реально 23) и ссылается на несуществующий `claude-api-integration`; `zodiac-hooks-pack` в README отсутствует вовсе; `BUNDLING_REPORT.md` устарел (битые `/sessions/...` пути, неверный AI-tool, 0 задокументированных скиллов); версии расходятся (speckit `0.5.0` vs init-options `0.4.0` vs README `v1.4.0`).
10. **install.sh опасен:** `rm -rf "$dst"; cp -r` без бэкапа/подтверждения молча затирает одноимённый плагин (включая Anthropic-овский `cowork-plugin-management`); детект клиента взаимоисключающий; зависит от Bash ≥4 (`mapfile`) при заявленном «any OS».

Вывод одной строкой: **контент местами сильный (паттерны корректны, описания-триггеры двуязычны и хороши), но архитектура marketplace — это «вынесли свой проект в плагины и забыли вычистить». Портируемость близка к нулю, часть инфраструктуры либо мёртвая, либо ссылается в пустоту.**

---

## 1. Сводка по плагинам (проверенные цифры)

`find` по факту (НЕ по README):

| Плагин | skills | agents | Вердикт |
|---|---|---|---|
| `zodiac-dev-toolkit` | 23 | 3 | Грабь-бэг из 6+ несвязанных тем; 2/23 портируемы |
| `zodiac-quality-gate` | 8 | 7 | Дублирование скилл↔агент 1:1; хардкод ADR/dep-graph |
| `zodiac-research-lab` | 6 | 3 | Рескин встроенных скиллов 6/6 |
| `zodiac-design-review` | 6 | 5 | Дублирование 5/5; завязан на Cosmic Glass |
| `astrology-data-validator` | 1 | 1 | Доменный, не для общего marketplace; данные без провенанса |
| ~~`speckit`~~ | — | — | ВЫНЕСЕН (внешний SpecKit, github/spec-kit). Разбор — раздел 2/«внешнее» |
| ~~`speckit-product-forge`~~ | — | — | ВЫНЕСЕН (внешний, VaiYav/speckit-product-forge). Был блокатором портируемости |
| `cowork-plugin-management` | 2 | 0 | Vendored Anthropic Apache-2.0; частично нерабочий здесь |
| `zodiac-hooks-pack` | 0 | 0 | Хуки; 2 из 8 мертвы; smoke даёт ложный green |

README заявляет `zodiac-dev-toolkit` = **11** (`README.md:9`) — расхождение на 12. README заявляет `speckit` = 29 (верно), но описание `speckit/plugin.json:4` рекламирует скиллы Forge, которых в этом плагине нет.

---

## 2. Сквозные проблемы (ранжированы по тяжести)

### CRITICAL

**C1. Захардкоженная инфраструктурная идентичность в телах скиллов и во всех eval'ах.**
Эти значения существуют ровно в одном репозитории и делают скиллы неперено­симыми «как есть»:
- `zodiac-dev-toolkit/skills/rum-analytics/SKILL.md:101,120` — `WHERE appId = 538822289` прямо в NRQL.
- `rum-analytics/SKILL.md:37-39` — литеральный MCP-хэш `mcp__3dc9ae8a-...` (instance-specific, протухнет).
- `newrelic-dashboard-builder/SKILL.md:33,129` — NewRelic account `7715788` (EU), appName `My_Zodiac_AI_prod`.
- `mongodb-ops` — имя БД `my_zodiac_ai`, коллекции `horoscope-caches`, `ai-metrics`.
- Конфликт: `devops-deploy/SKILL.md:62` bundle `com.myzodiac.ai` vs `capacitor-mobile-ops/SKILL.md:44` `org.yakovliev.myzodiacai` — два разных ID одного приложения в одном плагине.
- Все 6 `evals.json` завязаны на эти же значения (account `7715788`, ветки `001-auth-v2-telemetry`, роуты `/horoscope/daily`) → eval'ы не запускаются вне репо.

**C2. `speckit-product-forge` ссылается на несуществующий каталог `docs/`.**
`ls plugins/speckit-product-forge/` → только `README.md` + `skills/`. При этом 13 скиллов (50+ вхождений) ссылаются на `../docs/policy.md`, `../docs/runtime.md`, `../docs/schema.md`, `../docs/templates/phase-digest.md`, `../docs/testing-strategy.md`. `forge/SKILL.md:81,90-97,219-223` отдаёт туда весь свой operating contract: state-lock, pre-flight, sync-verify, schema статуса. **Оркестратор не может работать по спецификации — его «мозг» не поставляется.**

**C3. Хуки `gsap-import-guard.sh` и `i18n-key-checker.sh` мертвы (баг чтения stdin).**
`lib/_common.sh:20-27`: `_ZH_PAYLOAD="$(cat -)"` присваивается ВНУТРИ функции, которую вызывают через `file="$(zh_get_file_path)"` — то есть в subshell. Кэш в subshell теряется при возврате; второй вызов `zh_get_content` снова делает `cat -`, но stdin уже вычитан → `content` пустой → хук выходит на `[[ -z "${content}" ]] && exit 0`. Ирония: комментарий в коде сам признаёт «stdin is not seekable». Затронуты ровно те 2 хука, что читают и путь, и контент. Проверяемо: `printf '{...}' | { fp=$(zh_get_file_path); ct=$(zh_get_content); ... }` → `content=[]`.

**C4. `qa-check.sh` / `qa-fix.sh` / `qa-report.sh` захардкодили путь к ноутбуку автора.**
`plugins/speckit/scripts/bash/qa-check.sh:9` (и `qa-fix.sh:10`, `qa-report.sh:12`): `PROJECT_ROOT="/Users/valentinyakovlev/projects/my_zodiac_ai"`. Запускается только на машине автора. Вдобавок эти скрипты — сироты: ни один SKILL.md/конфиг их не вызывает (мёртвый код).

### HIGH

**H1. `speckit` шаблоны и ядро жёстко под my_zodiac_ai → связанность протекает в `forge`.**
`templates/plan-template.md:16-24` хардкодит весь стек («NestJS 11, Mongoose/MongoDB, BullMQ, Redis… Vue 3… Quasar 2… Swiss Ephemeris… Capacitor… Monorepo back/+front/»). `templates/tasks-template.md:21-43` — 37 вхождений путей `back/src/modules/{domain}/`, `front/src/features/{feature}/`. `templates/spec-template.md:22-126` — секция «Astrology Domain Entities» (NatalChart, Transit, Sign), «Cosmic Glass». 48 coupling-вхождений в `templates/` суммарно. Скиллы `forge/skills/{plan,tasks,implement}` делегируют в speckit (`forge/skills/implement/SKILL.md:66-68` «Delegate to SpecKit Implement») → даже портируемые обёртки forge на рантайме вызывают непортируемый speckit.

**H2. Внутреннее противоречие в `speckit`: две модели каталогов.**
Скрипты (`scripts/bash/common.sh:95`) используют generic `specs/<slug>/` (как upstream spec-kit). А скиллы и шаблоны — `back/`+`front/`. А v-model — `specs/{feature}/v-model/` (`v-model-trace`). Три несовместимых соглашения о расположении в одном плагине.

**H3. V-model — мёртвый груз / несогласованная проводка.**
`speckit` поставляет 9 скиллов `v-model-*` (дефис). А `forge/SKILL.md:125-139` требует ВНЕШНИЙ пакет в dotted-namespace `speckit.v-model.*` и пишет, что он «NOT bundled». 4 команды, которые зовёт forge (`hazard-analysis`, `peer-review`, `test-results`, `audit-report`), не существуют нигде. При этом `bridge/SKILL.md:472,482` зовёт bundled `v-model-requirements`. Плюс `v-model-trace/SKILL.md:61` вызывает `{SCRIPTS_DIR}/build-matrix.sh` — скрипта нет, `{SCRIPTS_DIR}` не определён. Главный артефакт (RTM) не может быть сгенерирован.

**H4. Дублирование «скилл↔агент» в `quality-gate` (7 пар) и `design-review` (5 пар).**
Агент — lossy-подмножество одноимённого скилла. Пример: `architecture-auditor.md:69` («Check all active ADRs») ВЫБРАСЫВАЕТ явный список ADR-001..007, который есть в `architecture-audit/SKILL.md:87-94`. В `design-review` 4 из 5 агентов вообще не читают свой скилл, хотя `comprehensive-review/SKILL.md:35` велит «Read the design-critique skill». Суммарный «новый» вклад всех 7 агентов quality-gate: CVSS-полосы + одно слово примера. Это чистый bloat и гарантированный дрейф двух копий.

**H5. `zodiac-research-lab` дублирует встроенные скиллы 6/6.**
`deep-research` vs хостовый `deep-research` + `speckit-product-forge:research`; `competitor-analysis` vs `anthropic-skills:competitor-analysis` + `product-management:competitive-brief`; то же для `ux-research`, `tech-stack-research`, `codebase-analysis`, `metrics-analysis`. Тела generic, отличие — только астрологический рескин. `deep-research/SKILL.md:44` к тому же содержит протухший абсолютный путь `/sessions/kind-wonderful-gates/mnt/my_zodiac_ai/`.

**H6. README и сопутствующие доки недостоверны.**
- `README.md:9` — dev-toolkit «11» (реально 23); `:74` перечисляет 11 имён, 12 реальных скиллов не задокументированы; упомянут несуществующий `claude-api-integration` (реальный — `ai-provider-integration`).
- `zodiac-hooks-pack` отсутствует в таблице README (`:7-16`) и в описаниях, хотя это реальный плагин и предмет всей миграции 2026-05.
- `README.md` хуков-пака `:94` заявляет «file paths are validated as absolute» — `zh_in_project`/`zh_project_root` (`_common.sh:83,116`) **ни разу не вызываются**. Ложное заявление о безопасности.

### MEDIUM / LOW

**M1. Версии и метаданные расходятся.** `speckit/plugin.json:3` = `0.5.0`, `config/init-options.json:10` = `0.4.0`, `speckit/README.md:30` = «v1.4.0», `forge` = `1.5.0`. `extensions.yml` использует dotted-команды (`speckit.cleanup.run`, `speckit.v-model.trace`), не совпадающие с плоскими именами установленных скиллов.

**M2. `BUNDLING_REPORT.md` устарел и противоречив.** Битые `/sessions/jolly-magical-ride/mnt/...` пути (`:5,182,203`); заявляет несуществующий `memory/constitution.md`; `:117` «AI tool: windsurf» при `init-options.json:2` `"ai":"claude"`; неверные line-count'ы; документирует 0 из 29 скиллов.

**M3. install.sh — затирание без бэкапа + узкий детект.** `install.sh:73-74,80-81` `rm -rf "$dst"; cp -r`; `:43-55` детект взаимоисключающий (есть `claude` CLI → Cowork никогда не получит плагины); `mapfile` (`:137`) требует Bash ≥4 при заявленном «any OS» (`README.md:23`).

**M4. `cowork-plugin-management` — vendored Anthropic, частично нерабочий здесь.** Apache-2.0 (`LICENSE` + дубль `LICENSE.txt`), но в репо нет top-level LICENSE. `cowork-plugin-customizer/SKILL.md` требует mount'ы `mnt/.local-plugins`, которых install.sh не создаёт. У `cowork-plugin-management/plugin.json` нет `keywords` (единственный без них).

**M5. Несогласованность авторства/frontmatter.** `astrology-data-validator/plugin.json` author = `"Valentyn"`, у всех остальных `"Valentyn Yakovliev"`. Агенты используют `tools: ["Read","Grep","Glob"]` (flow-array) вместо документированной строковой формы; два агента quality-gate имеют одинаковый `color: green` (`dependency-auditor.md:18`, `testing-auditor.md:18`).

**M6. `astrology-data-validator` — данные без провенанса.** `known-positions.json:2` — единственный комментарий «Source: Swiss Ephemeris / JPL Horizons», без пер-значной ссылки/версии/даты. `:40-41` Moon `185.08` = Sun `5.08` + ровно 180.00 (сконструировано, а не измерено). `:83,85` `longitude: 20.0` / `signDegree: 20.0` — круглая заглушка. Орбы (`aspect-orbs.json:2`) валидируются против копии собственного конфига продукта (`aspects.config.ts`) — циклический провенанс.

---

## 3. Что объективно сделано хорошо (без лести, но честно)

Чтобы критика была сбалансированной и доверительной — вот что НЕ надо переделывать:

- **Описания-триггеры скиллов** — сильная сторона. Плотные, двуязычные (RU+EN), с конкретными фразами активации. Это ровно то, что Anthropic рекомендует для срабатывания скиллов. Сохранить подход (но вычистить из них имя проекта — см. C1/H6).
- **Безопасность блокирующего хука.** `block-sensitive-files.sh` корректен: чистый `case`-матчинг по пути, JSON парсится python'ом через env-var (не интерполируется в shell), переменные закавычены. Инъекции не найдено. Kill-switch (`ZODIAC_HOOKS_DISABLE`, пер-хуковые) работают; `set -u` без `set -e` — осознанно.
- **`speckit-product-forge` как архитектура** — лучший из двух SDD. Большинство скиллов (`research`, `product-spec`, `test-plan`, `test-run`, `problem-discovery`, `tracking-plan` 4 провайдера, `migration-plan` с auto-detect mongodb/postgres/mysql, `backfill`, `api-docs` 6 фреймворков) уже stack-agnostic с реальным auto-detection. Проблема операционная (нет `docs/`), не концептуальная.
- **Eval'ы — реальные, не заглушки.** 6 `evals.json` содержат настоящие prompt+expected. Беда только в том, что фикстуры захардкожены под репо (C1).
- **Слоистость speckit↔forge концептуально верна:** forge = продуктовый/оркестрационный слой, speckit = инженерный исполнительный. Границу надо чистить, а не ломать.
- **`common.sh`** (git-root detection + fallback, generic `specs/`) — самый портируемый кусок во всём speckit. Парадокс: скрипты правильные, проза — нет.

---

## 4. Корневые причины (почему так вышло)

1. **Скиллы извлекались из `.claude/` живого проекта без «генерализации».** Поэтому пути `back/`/`front/`, имена модулей и инфра-ID попали в тела дословно. Подтверждение: `phase-2-3-execution.md` сам отмечает «works for MZAI; front/ refs (TODO: parameterize)» — TODO не закрыт.
2. **Нет границы «universal-core ↔ stack-adapter».** Один плагин (`zodiac-dev-toolkit`) смешал backend-паттерны, mobile-ops, observability, payments, AI/LLM, тестирование и доменную астрологию. Keyword-список самого манифеста (`nestjs,vue3,quasar,eda,ddd,fsd,astrology,ai,monorepo`) — признание в 6+ несвязанных темах.
3. **Нет единого стандарта авторинга** (структура, frontmatter, лимит строк, провенанс данных, обязательность eval, запрет на инфра-литералы). Отсюда дрейф, дубли скилл↔агент, мёртвые ссылки.
4. **Нет CI/линтера для самих плагинов.** Битые `../docs/` ссылки, протухшие `/sessions/...` пути, мёртвые хуки, ложные счётчики в README — всё это поймал бы простой валидатор. Его нет.
5. **`reports/audits/2026-05` уже всё это частично диагностировал, но фиксы не доведены** (хуки-пак собран с багом; lift сделан без параметризации; speckit-дедуп частичный).

---

## 5. Куда это ведёт (риски, если не чинить)

- Любая попытка применить плагины на `companion-ai` (Nuxt+Prisma) или `astro-ai-landing` (Nuxt4) упрётся в `back/`/`front/`, Quasar и Mongoose — то есть «универсальный тулкит» не применим к 2 из 3 проектов орги.
- `forge` будет молча деградировать (ссылки в пустоту) и выдавать неполный результат, создавая ложную уверенность в «полном lifecycle».
- Мёртвые хуки создают ложное чувство защищённости (думаешь, что i18n/gsap проверяются — нет).
- Дрейф «скилл↔агент» и копий speckit гарантирует, что через 3-6 месяцев разные источники будут советовать разное.

Конкретный план исправления — в `02-BACKLOG.md`. Правила, чтобы это не повторялось — в `03-UNIVERSAL-STANDARD.md` и `04-ENGINEERING-CANON.md`.
