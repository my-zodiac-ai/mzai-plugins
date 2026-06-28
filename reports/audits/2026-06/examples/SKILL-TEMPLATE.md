---
name: skill-name                      # MUST equal the directory name (kebab-case)
description: >
  One to three sentences. What it does + concrete trigger phrases, bilingual RU+EN.
  NO project identity ("for My Zodiac AI"), NO module names. This text decides
  activation in OTHER repos too. Example triggers: "do X", "сделай X", "add Y".
x-scope: core                         # core | adapter:<stack> | domain:<name>
x-stack: any                          # any | nestjs | nuxt | vue-quasar | prisma | ...
allowed-tools: Bash(tool:*)           # REQUIRED if the skill shells out; else omit
---

# Skill Title (no project name)

## When to use
Bullet the trigger situations. Lead with the decision, not narrative.

## Method / Steps
The portable procedure. Framework-agnostic for `core`; one stack only for `adapter`.
- Use repo-relative paths derived at runtime (`git rev-parse --show-toplevel`), never absolute.
- Reference infra via placeholders read from config: `${ACCOUNT_ID}`, `${APP_NAME}`.
- For adapters: "Apply the `<core-skill>` core, then map it to <stack> as below." Do NOT
  re-explain the method — link to the core skill (single source of truth).

## Output
What the skill produces (file, report shape, code). Make it checkable.

## Example
The ONLY place domain/project specifics may appear, clearly labelled as an example.

## References
- `references/<detail>.md` — load on demand (keep SKILL.md ≤ 500 lines).

<!--
evals/evals.json — ≥3 representative tasks (prompt + expected), parameterized/synthetic.
Definition of Done: see 03-UNIVERSAL-STANDARD.md §9. Must pass CI-1…CI-7.
-->
