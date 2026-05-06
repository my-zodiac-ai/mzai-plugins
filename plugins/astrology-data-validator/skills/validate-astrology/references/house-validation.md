# House System Validation Reference

## House System Overview

The project uses `house-system.enum.ts`. Supported systems:

| System      | Enum value | Description |
|-------------|-----------|-------------|
| Placidus    | `PLACIDUS` | Default; time-based; fails at high latitudes |
| Koch        | `KOCH`     | Similar to Placidus |
| Equal House | `EQUAL`    | Each house exactly 30° from ASC |
| Whole Sign  | `WHOLE_SIGN` | Each sign = one house |

## Mandatory Invariants

For ANY valid house calculation:

1. **Count:** Exactly 12 cusps returned
2. **Ascendant:** `cusps[HOUSE_ASCENDANT_INDEX]` = `cusps[0]` = ASC degree
3. **Midheaven:** `cusps[HOUSE_MIDHEAVEN_INDEX]` = `cusps[9]` = MC degree
4. **Range:** All cusps in [0°, 360°)
5. **Order:** Cusps generally increase (with wraparound at 360°)

## Placidus Polar Limit

Placidus is mathematically undefined at latitudes where some houses span more than 24 hours.

- **Limit:** Approximately ±66.33° (Arctic/Antarctic Circle)
- **Test coordinates:**
  - Helsinki: 60.17°N — valid (just under limit)
  - Tromsø: 69.65°N — INVALID, must trigger fallback
  - Anchorage: 61.22°N — valid

**Expected behavior:** When `|latitude| > 66`, use `WHOLE_SIGN` or `EQUAL` as fallback.

**Validation:** Check `calculations.service.ts` — look for `latitude > 66` guard before calling
`sweph.houses()` with Placidus flag.

## Equal House Validation

For Equal House at ASC = 15° Taurus (45°):

| House | Expected cusp |
|-------|-------------|
| 1     | 45°  (15° Taurus) |
| 2     | 75°  (15° Gemini) |
| 3     | 105° (15° Cancer) |
| 4     | 135° (15° Leo) |
| 5     | 165° (15° Virgo) |
| 6     | 195° (15° Libra) |
| 7     | 225° (15° Scorpio) |
| 8     | 255° (15° Sagittarius) |
| 9     | 285° (15° Capricorn) |
| 10    | 315° (15° Aquarius) |
| 11    | 345° (15° Pisces) |
| 12    | 15°  (15° Aries) — wraps |

## House Placement of Planets

Planet-in-house assignment logic:

```typescript
// Correct: planet is in house N if its longitude is between cusp N and cusp N+1
function getPlanetHouse(planetLon: number, cusps: number[]): number {
  for (let i = 0; i < 12; i++) {
    const next = (i + 1) % 12;
    if (isInArc(planetLon, cusps[i], cusps[next])) return i + 1;
  }
}

// isInArc must handle 360° wraparound:
function isInArc(lon: number, start: number, end: number): boolean {
  if (start <= end) return lon >= start && lon < end;
  return lon >= start || lon < end; // wraparound case
}
```

**Test case:** Cusp 12 = 340°, Cusp 1 = 10° — planet at 355° should be in house 12, planet at 5° in house 1.

## HOUSE_ASCENDANT_INDEX and HOUSE_MIDHEAVEN_INDEX Constants

Verify these constants in `thresholds.constants.ts` match Swiss Ephemeris array conventions:

- Swiss Ephemeris `sweph.houses()` returns cusps as 1-indexed array — `cusps[1]` through `cusps[12]`
- The codebase may convert to 0-indexed: `cusps[0]` = house 1 = ASC
- Confirm `HOUSE_ASCENDANT_INDEX = 0` and `HOUSE_MIDHEAVEN_INDEX = 9` match this convention
