# astrology-data-validator

Validates Swiss Ephemeris calculations, aspects, houses, and edge cases in **My Zodiac AI**.
Catches regressions after Swiss Ephemeris updates and ensures business-domain accuracy.

## Components

**Skill — `validate-astrology`**
Guided validation across all domains: ephemeris, aspects, houses, edge cases, and cross-engine comparison. Saves a structured Markdown report to `reports/`.

**Agent — `validation-runner`**
Autonomous pipeline that reads code, runs existing tests, does live spot-checks, and produces the full validation report without manual steps. Best for pre-release sweeps and post-sweph-update regression.

## Usage

**Quick validation (any domain):**
> "validate astrology calculations"
> "проверь расчёты эфемерид"
> "ephemeris check"
> "aspect validation"

**Full autonomous regression:**
> "run full astrology validation"
> "запусти регрессию после обновления Swiss Ephemeris"

**Scoped checks:**
> "validate aspects only"
> "check retrograde detection"
> "house system validation"
> "compare with another astro engine"

## What Gets Validated

| Domain | Checks |
|--------|--------|
| Ephemeris | Julian Day in UTC, LRU cache key correctness, planet longitude range, sign/degree assignment |
| Aspects | Angular difference algorithm (incl. 360° wraparound), orb values vs reference, isApplying logic |
| Houses | Count, ASC/MC indices, Placidus polar fallback, planet-in-house boundary wraparound |
| Edge cases | Retrograde detection (speed < 0), sign cusps (floor vs round), polar coordinates, unknown birth time |
| Cross-engine | sweph vs astronomy-engine comparison for equinox/solstice positions |
| Regression | Existing Vitest suite, position drift after sweph version update |

## Reference Data

Located in `reference-data/`:
- `known-positions.json` — Verifiable planetary positions (equinoxes, solstices, Great Conjunction, Mercury retrograde stations)
- `aspect-orbs.json` — Reference orb values and validation test cases including 360° wraparound
- `house-systems.json` — Equal house reference, polar coordinate test cases, house placement boundary tests

## Report Output

Reports are saved to `reports/astrology-validation-YYYY-MM-DD.md` in the project root.
Each report contains: executive summary table, critical issues (block deploy), warnings, passed checks, and recommendations.

## Module Coverage

```
back/src/modules/astrology/
├── common/services/swiss-ephemeris.service.ts        ← ephemeris
├── common/utils/aspect-calculator.util.ts            ← aspects
├── common/configs/aspects.config.ts                  ← orbs
├── systems/western/services/calculations.service.ts  ← natal chart
└── features/cosmic-self/utils/validate-natal-chart.util.ts
```
