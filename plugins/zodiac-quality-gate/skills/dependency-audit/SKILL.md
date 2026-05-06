---
name: dependency-audit
description: >
  Audit project dependencies for outdated packages, security vulnerabilities, license compliance,
  best practice alternatives, and supply chain risks. Use when the user asks to "check dependencies",
  "audit packages", "проверь зависимости", "update libraries", "best library for",
  "какие библиотеки лучше", "npm audit", "dependency check", "license compliance",
  or wants to evaluate whether the project uses the best available libraries.
  Trigger proactively during quarterly maintenance or before major releases.
---

# Dependency Audit

Evaluate project dependencies for security, quality, alternatives, and maintenance health.

## Audit Process

### Step 1: Inventory

Read `package.json` files for both backend (`back/package.json`) and frontend (`front/package.json`).
Categorize dependencies:

| Category | Examples |
|---|---|
| **Framework core** | NestJS, Vue, Quasar, Pinia |
| **Database/Cache** | Mongoose, Redis, BullMQ |
| **AI providers** | @anthropic-ai/sdk, openai, @google/generative-ai |
| **Auth/Security** | Passport, JWT, Helmet |
| **Testing** | Vitest, Playwright, MSW |
| **Utilities** | lodash, dayjs, uuid |
| **Build/Dev** | TypeScript, Vite, ESLint |

### Step 2: Security Scan

For each dependency:
- Check for known CVEs (reference npm advisory database)
- Flag packages with no recent releases (>2 years)
- Flag packages with very few maintainers (bus factor risk)
- Check for deprecated packages

### Step 3: Best Practice Evaluation

Compare current choices against industry best practices:

| Need | Current | Best Practice | Action |
|---|---|---|---|
| Date handling | moment.js | dayjs / date-fns | Migrate if using moment |
| HTTP client | axios | axios / ky / ofetch | axios is fine, check config |
| Validation | class-validator | zod / class-validator | Both valid for NestJS |
| State mgmt | Pinia | Pinia | Correct choice for Vue 3 |

Evaluate based on:
- **Bundle size** — smaller is better, especially for frontend
- **Maintenance activity** — last commit, open issues ratio, release frequency
- **Community adoption** — npm weekly downloads, GitHub stars trend
- **TypeScript support** — native types vs @types package
- **Tree-shaking** — ESM support for frontend dependencies
- **API stability** — frequency of breaking changes

### Step 4: Duplicate Detection

Find functional duplicates:
- Two packages solving the same problem (e.g., lodash + underscore)
- Built-in Node/browser APIs that replace a package (e.g., native fetch vs axios for simple cases)
- Framework features that replace standalone packages

### Step 5: License Compliance

Check all dependency licenses:
- **Green**: MIT, Apache-2.0, BSD-2/3-Clause, ISC
- **Yellow**: LGPL, MPL-2.0 (copyleft for modifications)
- **Red**: GPL, AGPL (viral copyleft — may affect your licensing)
- **Unknown**: No license specified — avoid in production

### Step 6: Supply Chain Risk

- Packages with inline install scripts (`preinstall`, `postinstall`)
- Packages from unknown publishers with similar names to popular ones (typosquatting)
- Packages that recently changed ownership
- Transitive dependencies with security issues

## Output Format

```markdown
# Dependency Audit Report

## Summary
- **Total deps**: N (production) + N (dev)
- **Vulnerable**: N packages | **Outdated**: N packages | **Deprecated**: N packages
- **License issues**: N packages

## Security Vulnerabilities
| Package | Installed | Fixed In | CVE | Severity |
|---|---|---|---|---|

## Recommended Upgrades
| Package | Current | Latest | Breaking? | Priority |
|---|---|---|---|---|

## Better Alternatives
| Current | Alternative | Why | Effort |
|---|---|---|---|

## Duplicate/Removable Dependencies
| Package | Reason | Action |
|---|---|---|

## License Report
| License | Count | Packages |
|---|---|---|
| MIT | 85 | ... |

## Action Plan
1. [Immediate] Fix critical CVEs
2. [This sprint] Remove deprecated packages
3. [Next sprint] Evaluate alternatives for flagged packages
4. [Quarterly] Major version upgrades
```
