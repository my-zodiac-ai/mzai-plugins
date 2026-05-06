# Edge Cases Reference

## Retrograde Planet Handling

### Detection
Planet is retrograde when `speed < 0` (degrees/day moving backward).

**Check in code:**
```typescript
const isRetrograde = planetData.speed < 0;
```

**Validate:** Grep for retrograde assignment. Must NOT use `speed <= 0` (0 = stationary, not retrograde).

### LRU Cache and Retrograde
When a planet turns retrograde/direct between two calls with same JD (impossible, but ensure the cache key includes speed or isn't used cross-day for real-time charts):
- Cache TTL is 1 hour — acceptable for daily transit checks
- Natal chart cache should be invalidated when recalculation is forced

### Station Points (Speed ≈ 0)
- When `speed` is between -0.001 and 0.001, planet is "stationary"
- This is NOT retrograde and NOT direct
- Validate: some implementations set `isRetrograde = speed < 0` which correctly handles this
- Warn if `isRetrograde` is forced true at station

## Sign Boundary (Cusp) Planets

### 29°59' vs 0°01' Test
```
longitude 29.99° → Aries (signIndex = floor(29.99/30) = 0)
longitude 30.00° → Taurus (signIndex = floor(30.00/30) = 1)
longitude 30.001° → Taurus (correct)
longitude 59.99° → Taurus
longitude 60.00° → Gemini
```

**Common bug:** Using `round()` instead of `floor()` for sign index assignment.

### Sign Degree Calculation
```typescript
const signDegree = longitude % 30;
// At 30.00°: signDegree = 0.00 (correct — 0° Taurus)
// At 29.99°: signDegree = 29.99 (correct — 29°59' Aries)
```

## Polar Coordinate Edge Cases

| Latitude | Longitude | Expected behavior |
|----------|-----------|-------------------|
| 90°N     | any       | Reject — North Pole |
| 89.99°N  | any       | Placidus fails, use fallback |
| 66.5°N   | any       | Borderline — verify fallback activates |
| 0°       | 0°        | Reject — `validateCoordinatesOrThrow()` catches (0,0) as likely invalid |
| -90°     | any       | Reject — South Pole |

**Note on (0,0):** This coordinate (Gulf of Guinea) is technically valid geographically but conventionally rejected as a likely data error. Verify project behavior.

## Unknown Birth Time

When user doesn't provide birth time:
1. `DEFAULT_BIRTH_TIME = '12:00'` applied
2. Moon position is ±6° uncertain (moves 12°/day)
3. Houses are unreliable (ASC changes ~1° every 4 minutes)
4. Validate: warning is logged/returned indicating noon approximation

**Vitest test to check:**
```
back/src/modules/astrology/features/cosmic-self/utils/__tests__/validate-natal-chart.util.spec.ts
```
This already exists — run it and confirm it passes.

## Historical Date Handling

### Pre-Gregorian Calendar (before 1582-10-15)
Swiss Ephemeris supports Julian calendar via `sweph.SE_JUL_CAL` flag.
- Verify: no crash for dates like 1492-10-12 (Columbus)
- Expected behavior: use Julian calendar for pre-1582 dates

### Far-Future Dates (2100+)
Swiss Ephemeris valid through 5400 CE.
- Verify: `julday()` call doesn't throw for year 2100
- Validate: planet returned, no NaN in result

## Timezone Edge Cases

| Case | Expected |
|------|---------|
| DST transition hour | UTC conversion ignores DST (IANA handles it) |
| "America/New_York" at 2:30 AM during spring forward | Should map to valid UTC (spring-forward gap) |
| Offset-only timezone ("+05:30") | Should convert correctly |
| Historical timezone offset change | IANA database covers; verify `convertToUTC()` uses full IANA, not fixed offset |

## Forge Alert Severity Edge Cases

- Transit orb tightening to 0° (exact aspect) — should escalate severity to `critical`
- Multiple simultaneous transits — each should be a separate Forge Alert
- Transit involving retrograde planet — valid trigger; retrograde doesn't suppress alert
