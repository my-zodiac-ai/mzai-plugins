---
name: validate-astrology
description: >
  Validates Swiss Ephemeris calculations, aspects, houses, and orbs in the My Zodiac AI
  astrology module. Use when the user asks to "validate astrology", "проверь расчёты",
  "ephemeris check", "aspect validation", "astrology regression", "check planetary positions",
  "validate natal chart calculations", "test retrograde detection", "house cusp validation",
  "compare astro engines", "regression after sweph update", "проверь аспекты",
  "валидация эфемерид", or "регрессия астрологии".
metadata:
  version: "0.1.0"
  domain: astrology
  module: back/src/modules/astrology
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Astrology Data Validator

Validates the correctness of Swiss Ephemeris calculations in the My Zodiac AI backend.

## Module Locations

```
back/src/modules/astrology/
├── common/
│   ├── services/swiss-ephemeris.service.ts        # Low-level sweph wrapper
│   ├── services/swiss-ephemeris-gateway.service.ts
│   ├── utils/aspect-calculator.util.ts
│   ├── utils/astrology-math.util.ts
│   ├── utils/coordinate-validation.util.ts
│   └── configs/aspects.config.ts                  # Orb definitions
├── systems/western/services/calculations.service.ts  # Main natal chart calculator
└── features/cosmic-self/utils/validate-natal-chart.util.ts
```

Reference data for validation is in this plugin's `reference-data/` directory.

## Validation Workflow

When the user asks to validate astrology calculations, execute all relevant sections below. Always save the final report to `reports/astrology-validation-YYYY-MM-DD.md` (create the `reports/` directory if it doesn't exist, relative to the project root).

### 1. Ephemeris Calculation Validation

Read `back/src/modules/astrology/common/services/swiss-ephemeris.service.ts` and `systems/western/services/calculations.service.ts`.

Check against `reference-data/known-positions.json` in this plugin:

1. Identify how Julian Day is computed — verify `sweph.julday()` is called with UTC (not local time)
2. Confirm timezone conversion uses `convertToUTC()` from `timezone.utils.ts` before any ephemeris call
3. Check that the LRU cache key includes both Julian Day AND coordinate hash (prevents stale hits across locations)
4. Verify planet longitude results land in [0, 360) range
5. For the Spring Equinox test case (Sun at 0° Aries = 0.0° longitude), check the calculated value is within ±0.01° of the reference
6. For the Winter Solstice (Sun at 0° Capricorn = 270.0°), same tolerance check

See `references/ephemeris-validation.md` for full test cases and tolerance tables.

### 2. Aspect Validation

Read `back/src/modules/astrology/common/utils/aspect-calculator.util.ts` and `common/configs/aspects.config.ts`.

Cross-reference with `reference-data/aspect-orbs.json`:

1. Verify each major aspect angle:
   - Conjunction: 0° (tolerance ±orb)
   - Opposition: 180° (tolerance ±orb)
   - Trine: 120° (tolerance ±orb)
   - Square: 90° (tolerance ±orb)
   - Sextile: 60° (tolerance ±orb)
2. Check orb values in `aspects.config.ts` against the reference orbs in `reference-data/aspect-orbs.json`
3. Confirm `isApplying` logic: applying = faster planet moving toward exact aspect angle
4. Check that `getSynastryAspectOrb()` in `features/relationships/configs/aspect-orbs.config.ts` delegates to the unified config (not duplicated)
5. Verify minor aspects if present (quincunx 150°, semisquare 45°, sesquiquadrate 135°)

See `references/aspect-validation.md` for calculation examples.

### 3. House System Validation

Read `back/src/modules/astrology/common/enums/house-system.enum.ts` and how houses are calculated in `calculations.service.ts`.

Check against `reference-data/house-systems.json`:

1. Verify 12 houses are always returned
2. Confirm Ascendant is house 1 cusp (index 0, constant `HOUSE_ASCENDANT_INDEX = 0`)
3. Confirm Midheaven is house 10 cusp (index 9, constant `HOUSE_MIDHEAVEN_INDEX = 9`)
4. Validate cusp degrees are in [0, 360) range, each 30° apart (approximately for Placidus)
5. For equal-house fallback: each cusp exactly 30° from the previous
6. Check polar latitude edge case: Placidus fails above ~66°N — verify fallback to Whole Sign or Equal House

See `references/house-validation.md`.

### 4. Edge Case Testing

Focus on these edge cases (see `references/edge-cases.md` for full list):

**Retrograde detection:**
- Read how `isRetrograde` is set — must derive from `speed < 0` (degrees/day negative)
- Check that retrograde flag is preserved through LRU cache (not discarded)
- Verify retrograde planets still get correct sign placement

**Cusp planets (sign boundaries):**
- Planet at 29°59' vs 0°01' of next sign — check sign assignment at boundary
- Verify `signDegree` resets to ~0 when crossing to new sign
- Validate `Math.floor(longitude / 30)` sign index is used (not rounding)

**Polar coordinates:**
- Latitude > 66.5°N or < 66.5°S — Placidus undefined, verify fallback activates
- Coordinates at (0, 0) — verify `validateCoordinatesOrThrow()` catches this as invalid

**Unknown birth time (noon default):**
- Verify `DEFAULT_BIRTH_TIME = '12:00'` is used when time is absent
- Moon position should carry a "time unknown" warning in this case (Moon moves ~12°/day)

**Julian Day edge cases:**
- Date before 1582-10-15 (Julian calendar cutoff) — Swiss Ephemeris handles this, verify no crash
- Far-future dates (2100+) — verify graceful handling

### 5. Cross-Engine Comparison

When asked to compare against another engine, use Bash to run a Node.js script using `astronomia` or `astronomy-engine` npm packages, then compare:

```bash
cd back && node -e "
const sweph = require('sweph');
// Calculate Sun position for Spring Equinox 2024: March 20, 2024, 03:06 UTC
// JD = 2460389.629167
const jd = 2460389.629167;
const result = sweph.calc_ut(jd, sweph.SE_SUN, sweph.SEFLG_SWIEPH);
console.log('Sun longitude:', result.data[0]);
"
```

Expected: Sun longitude ≈ 0.0° (±0.1°) for Spring Equinox.

See `references/engine-comparison.md` for full comparison methodology.

### 6. Regression Suite (Post Swiss Ephemeris Update)

Run after updating the `sweph` npm package version:

1. Check `back/package.json` for current `sweph` version
2. Run existing tests: `pnpm --dir back test -- --reporter=verbose 2>&1 | grep -E "(PASS|FAIL|astrology|ephemeris|chart|aspect)" | head -50`
3. Compare planet positions for all reference dates in `reference-data/known-positions.json` against previously recorded values
4. Flag any position drift > 0.001° (arcseconds) as a regression
5. Check that `aspect-calculator.util.ts` spec file passes: `pnpm --dir back test -- aspect-calculator --reporter=verbose`

## Report Format

Save the final report to `reports/astrology-validation-YYYY-MM-DD.md` with this structure:

```markdown
# Astrology Validation Report
**Date:** YYYY-MM-DD
**sweph version:** x.x.x
**Scope:** [what was validated]

## Summary
| Check | Status | Issues |
|-------|--------|--------|
| Ephemeris calculations | ✅ PASS / ❌ FAIL | count |
| Aspect validation | ✅ PASS / ❌ FAIL | count |
| House system | ✅ PASS / ❌ FAIL | count |
| Edge cases | ✅ PASS / ⚠️ WARN | count |
| Cross-engine | ✅ PASS / ❌ FAIL | count |

## Findings

### Critical (must fix before deploy)
...

### Warnings (should investigate)
...

### Passed Checks
...

## Recommendations
...
```
