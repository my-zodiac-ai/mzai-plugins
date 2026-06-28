# Engineering Canon (universal, framework-agnostic)

> **Purpose:** the proven, source-backed rules that the org's *quality / architecture / testing / API / security* skills should encode — instead of project-specific ADRs and `zodiac-rules.md`. This is the "universal core" content layer. Each item names its canonical source so skills cite authority, not opinion.
> **Use:** `core-engineering` skills reference these sections; `domain-*`/`adapter-*` plugins add the project's concrete choices on top (e.g. "ADR-002: no forwardRef" belongs in the product repo, not in a shared skill).

The current `zodiac-quality-gate` bakes project ADRs (`ADR-001..007`), a hardcoded dependency graph, and `pnpm --dir back ...` scripts directly into skill bodies (`architecture-audit/SKILL.md:63-94`, `references/zodiac-rules.md:49-78`). That is project config, not a reusable rule set. Replace with the canon below + a project overlay.

---

## 1. Code quality (what `code-quality-audit` should check)

- **SOLID** — single-responsibility, open/closed, Liskov, interface-segregation, dependency-inversion. Source: Robert C. Martin, *Agile Software Development* / *Clean Architecture*.
- **DRY / KISS / YAGNI** — don't repeat, keep simple, don't build speculative. Sources: Hunt & Thomas *The Pragmatic Programmer*; Fowler.
- **Function/module size & cyclomatic complexity** — flag long units and deep nesting (thresholds are project overlay, not universal absolutes). Source: McCabe complexity; *Clean Code* (Martin).
- **Naming & cohesion** — intention-revealing names, high cohesion / low coupling. Source: *Clean Code*; Constantine/Yourdon coupling-cohesion.
- **Error handling** — fail fast, no swallowed errors, typed errors at boundaries. Source: *Effective Java* (Bloch) item set; 12-Factor "logs as event streams".

## 2. Architecture (what `architecture-audit` should check)

- **C4 model** for describing architecture at 4 zoom levels (Context, Container, Component, Code). Use C4 instead of ad-hoc diagrams. Source: <https://c4model.com>.
- **Architecture Decision Records (ADR)** — every significant decision is one immutable, numbered markdown file (context → decision → consequences). The *format* is universal; the *specific ADRs* are per-project. Source: Michael Nygard's ADR; <https://adr.github.io>.
- **Dependency direction / boundaries** — dependencies point inward toward stable abstractions; no cycles; enforce module boundaries. Source: *Clean Architecture* (Martin); Acyclic Dependencies Principle.
- **Bounded contexts & ubiquitous language** (DDD) — model boundaries follow business capabilities. The *principle* is universal; the concrete contexts (astrology/cosmic-weather) are domain overlay. Source: Evans, *Domain-Driven Design*.
- **12-Factor App** — config in env, stateless processes, explicit dependencies, dev/prod parity, logs as streams, disposability. The universal baseline for any service. Source: <https://12factor.net>.

## 3. API design (what `api-design` / `api-docs` should check)

- **REST maturity & resource modeling** — nouns/resources, correct verbs, status codes, idempotency, pagination, consistent error envelope. Source: Richardson Maturity Model; Fielding's REST.
- **Contract-first / OpenAPI 3.1** — spec is the source of truth; generate docs & clients from it. (forge `api-docs` already targets OpenAPI 3.1 + Postman — keep, make framework-detection the default.)
- **Versioning & deprecation** — explicit version strategy, additive-by-default, documented deprecation windows. Source: SemVer for the API surface; Stripe/Google API design guides.
- **Backward-compatibility classification** — breaking vs non-breaking change detection in changelogs (the `api-changelog` skill's job). Source: Keep a Changelog + SemVer.

## 4. Testing (what `testing-audit` / `tdd-testing` should check)

- **Testing pyramid** — many unit, fewer integration, few E2E. Source: Mike Cohn; Fowler "TestPyramid".
- **AAA / Given-When-Then** — Arrange-Act-Assert structure; one logical assertion per test. Source: xUnit Patterns (Meszaros).
- **Test-first (red-green-refactor)** where it pays. Source: Beck, *TDD by Example*. (This is a project *choice*, document in constitution — not a universal mandate.)
- **Coverage as a signal, not a target** — flag untested critical paths; Goodhart-aware (don't game %). Source: Fowler "TestCoverage".
- **Flaky-test detection & test isolation** — deterministic, independent tests. Source: Google Testing Blog.
- **Framework-agnostic**: detect the runner (Vitest/Jest/Playwright/pytest), don't hardcode "Vitest only" (current `testing-audit` hardcodes ADR-005).

## 5. Security (what `security-audit` / `security-check` should check)

- **OWASP Top 10** (web) + **OWASP ASVS** (verification standard) as the checklist backbone. Source: <https://owasp.org/Top10>, OWASP ASVS.
- **Secrets management** — no secrets in code/history; env/secret store; rotation. Source: 12-Factor config; OWASP.
- **Input validation & output encoding at boundaries**; injection (SQLi/NoSQLi/XSS) prevention. Source: OWASP.
- **AuthN/AuthZ** — least privilege, deny-by-default, server-side checks. Source: OWASP ASVS.
- **Dependency / supply-chain** — CVE scanning, lockfile integrity, license compliance (the `dependency-audit` skill's job — already mostly portable). Source: OWASP Dependency-Check; SLSA.

## 6. Performance (what `performance-audit` should check)

- **Avoid N+1 and unbounded operations**; paginate; index hot queries. (Principle universal; "Mongoose"/"BullMQ" specifics are adapter overlay.)
- **Cache-aside with TTL + stampede protection + explicit invalidation keys** (universal; Redis/Keyv/in-memory are adapter). 
- **Core Web Vitals** for frontends (LCP/CLS/INP), measured both synthetic (Lighthouse) and field (RUM). Source: web.dev Core Web Vitals. (Keep the appId/account in config, not in the skill — see standard S-11.)
- **Algorithmic complexity & memory** — flag obvious super-linear hot paths and leaks (intervals/listeners/cursors without cleanup).

## 7. Delivery & process (cross-cutting)

- **Conventional Commits** for commit messages → enables automated changelog/version. Source: <https://www.conventionalcommits.org>.
- **Semantic Versioning** for every plugin and API. Source: <https://semver.org>.
- **Keep a Changelog** format for human changelogs. Source: <https://keepachangelog.com>.
- **DORA metrics** (deploy frequency, lead time, change-fail rate, MTTR) as the north-star for delivery health. Source: DORA / *Accelerate* (Forsgren, Humble, Kim).
- **Trunk-based or short-lived branches**, small PRs, fast review. Source: DORA; Google Eng Practices.

---

## How this maps to the refactor

| Current (coupled) | Replace with |
|---|---|
| `zodiac-rules.md` hardcoded stack + ADR-001..007 | `core-engineering` cites canon §1–§7; project ADRs live in product repo's `constitution.md` + `docs/adr/` |
| `architecture-audit` hardcodes dep-graph in body | Canon §2 (C4, ADR, boundaries) in core; the actual graph is a project-supplied input |
| `testing-audit` "Vitest only (ADR-005)" | Canon §4 + runner auto-detect; "Vitest" is a project choice in constitution |
| `performance-audit`/`rum-analytics` infra IDs | Canon §6 + config placeholders (`${NEW_RELIC_ACCOUNT_ID}`, `${APP_NAME}`) |
| `security-audit` Mongoose/class-validator specifics | Canon §5 (OWASP) in core; validators are adapter examples |

**Principle:** a *core* skill teaches the canon and asks the repo for its specifics; it never ships another team's specifics as if they were universal law.

---

## Sources (canonical)
- SOLID / Clean Architecture / Clean Code — Robert C. Martin
- *The Pragmatic Programmer* — Hunt & Thomas
- *Domain-Driven Design* — Eric Evans
- C4 model — <https://c4model.com>
- ADR — Michael Nygard; <https://adr.github.io>
- 12-Factor App — <https://12factor.net>
- Richardson Maturity Model / REST — Fielding, Fowler
- OpenAPI 3.1 — <https://spec.openapis.org>
- Testing Pyramid / TestCoverage — Martin Fowler; *TDD by Example* — Kent Beck; *xUnit Test Patterns* — Meszaros
- OWASP Top 10 / ASVS — <https://owasp.org>
- Core Web Vitals — <https://web.dev/vitals>
- Conventional Commits — <https://www.conventionalcommits.org>
- Semantic Versioning — <https://semver.org>
- Keep a Changelog — <https://keepachangelog.com>
- DORA / *Accelerate* — Forsgren, Humble, Kim
