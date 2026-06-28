# mzai-plugins — Аудит и план универсализации (2026-06)

> **Заказ:** жёсткий разбор всех плагинов/скиллов/документов + бэклог + стандарт, чтобы тулкит можно было применять на любом проекте орги (`github.com/orgs/my-zodiac-ai`) без привязки к фреймворкам/домену, на базе SDD (spec-kit / product-forge).
> **Решения по объёму (согласованы):** аудит + бэклог + стандарт (план-фёрст, без массового переписывания); портируемость в пределах JS/TS-стеков орги (universal-core + тонкие адаптеры); критика всех плагинов; RU-документы + EN-артефакты.

> **ОБНОВЛЕНО 2026-06-28:** `speckit` и `speckit-product-forge` удалены из репо — подключаются как внешние SpecKit-инструменты ([github/spec-kit](https://github.com/github/spec-kit) + [VaiYav/speckit-product-forge](https://github.com/VaiYav/speckit-product-forge)). Аудит изначально покрывал 9 плагинов; **актуальный скоуп репо — 7**. Их разбор в `01-CRITIQUE` сохранён как обоснование выноса. Снятые задачи: **B-02, B-08, B-11** (внешние) и **B-03** (файлы `qa-*.sh` удалились вместе со `speckit`).

## Документы

| # | Файл | Язык | Что внутри |
|---|---|---|---|
| 00 | `00-INDEX.md` | RU | Этот файл — навигатор + executive summary |
| 01 | `01-CRITIQUE.md` | RU | Жёсткая критика по фактам. Каждое утверждение привязано к `file:line` |
| 02 | `02-BACKLOG.md` | RU | Бэклог P0–P3, value×reach, оценки, зависимости, acceptance, дорожная карта |
| 03 | `03-UNIVERSAL-STANDARD.md` | EN | Стандарт авторинга: core+adapter, frontmatter, портируемость, хуки, eval, SDD-конвеншн, CI |
| 04 | `04-ENGINEERING-CANON.md` | EN | Универсальные правила dev/arch/quality из проверенных источников (SOLID, 12-Factor, C4, ADR, OWASP, DORA…) |
| 05 | `examples/SKILL-TEMPLATE.md` | EN | Канонический шаблон скилла |
| 06 | `examples/REF-01-caching-patterns.md` | EN | Эталон рефакторинга: `redis-caching` → core + adapter (before/after) |
| 07 | `examples/REF-02-hooks-stdin-fix.md` | EN | Эталон фикса: мёртвые хуки (баг stdin) before/after + тест |

Связь с прошлым аудитом: `reports/audits/2026-05/` (gap-analysis по 3 проектам) — этот заход не дублирует его, а смотрит под другим углом (портируемость + качество авторинга) и доделывает незакрытое.

## Executive summary (5 строк)

1. Это приватный мануал по `my_zodiac_ai`, переупакованный в плагины: из 23 скиллов dev-toolkit портируемы 2. Захардкожены инфра-ID (NewRelic `7715788`, appId `538822289`, MCP-хэш, имя БД) прямо в тела и eval'ы.
2. *(внешний, удалён из репо)* `speckit-product-forge` не запускается как задумано — 13 скиллов ссылаются на каталог `docs/`, которого нет в плагине (50+ висячих ссылок). Апстрим-баг VaiYav/speckit-product-forge.
3. *(внешний, удалён из репо)* `speckit` — был блокатором портируемости (шаблоны и ядро под `back/`+`front/`+NestJS/Vue/Quasar).
4. 2 из 8 хуков физически мертвы (баг чтения stdin); smoke-тест даёт ложный green. Дублирование «скилл↔агент» (7+5 пар) и рескин research-lab (6/6) — bloat.
5. Документация недостоверна (README: 11 vs 23 скилла; нет hooks-pack; протухшие пути; рассинхрон версий). `install.sh` молча затирает чужие плагины.

Что хорошо и не трогаем: двуязычные описания-триггеры, безопасность блокирующего хука, архитектура product-forge (концептуально), реальные eval'ы, `common.sh`.

## Как это использовать

1. Прочитать `01-CRITIQUE.md` — понять, что и почему сломано (с пруфами).
2. Принять `03-UNIVERSAL-STANDARD.md` + `04-ENGINEERING-CANON.md` как правила орги (положить в корень репо как `CONTRIBUTING`/`STANDARD`).
3. Идти по `02-BACKLOG.md` волнами: P0 (починить) → P1 (фундамент core+adapter + CI) → P2 (дедуп) → P3 (домен/расширение).
4. При рефакторинге сверяться с `examples/` (шаблон + 2 эталона) и «Definition of Done» (§9 стандарта).

## Первые 5 действий (если начинать сегодня)
1. **B-01** — оживить мёртвые хуки + позитивные тесты (0.5д).
2. **B-10** — поставить CI-линтер плагинов (ловит большинство регрессий) (2–3д).
3. **B-04** — зачистить инфра-литералы/абсолютные пути под grep-гейтом (1д; осталось: dev-toolkit ID, stale-путь в research-lab).
4. **B-05** — починить `install.sh` (бэкап перед затиранием, оба клиента).
5. **B-06/B-07** — ввести модель core+adapter, начать разбор dev-toolkit (старт фундамента).

## Источники (внешние)
- spec-kit: <https://github.com/github/spec-kit> (канонический flow Constitution→Specify→Plan→Tasks→Implement)
- Anthropic Agent Skills: <https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices>
- Claude Code plugins: <https://code.claude.com/docs/en/plugins>
- Инженерный канон — см. ссылки в `04-ENGINEERING-CANON.md`.
