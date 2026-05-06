# Ephemeris Validation Reference

## Tolerance Standards

| Planet  | Acceptable delta | Notes |
|---------|-----------------|-------|
| Sun     | ±0.01°          | Slow mover, high precision required |
| Moon    | ±0.10°          | Moves ~13°/day, time-sensitive |
| Mercury | ±0.05°          | Fast mover near Sun |
| Venus   | ±0.05°          |  |
| Mars    | ±0.02°          |  |
| Jupiter | ±0.01°          |  |
| Saturn  | ±0.01°          |  |
| Uranus  | ±0.005°         |  |
| Neptune | ±0.005°         |  |
| Pluto   | ±0.005°         |  |

## Key Validation Checks

### Julian Day Calculation

Swiss Ephemeris requires Julian Day in Terrestrial Time (or UTC with UT1 correction).
The project uses UTC via `sweph.julday()` — verify the signature:

```typescript
// Correct: UTC datetime components
sweph.julday(year, month, day, hour + minute/60 + second/3600, sweph.SE_GREG_CAL)

// Common mistake: passing local time instead of UTC
// This causes planet positions offset by timezone hours
```

Validation: For Spring Equinox 2024-03-20 03:06 UTC, JD should be ≈ 2460389.629167.

### Coordinate Hashing in LRU Cache

The LRU cache key MUST include both julian day AND location:

```typescript
// Correct cache key pattern
const cacheKey = `${julianDay}_${latitude.toFixed(4)}_${longitude.toFixed(4)}`;

// Wrong — same JD, different location returns cached wrong result
const badKey = `${julianDay}`;
```

Check: Search for LRU cache key construction in `calculations.service.ts`.

### Sign Index Calculation

```typescript
// Correct: floor division
const signIndex = Math.floor(longitude / 30); // 0-11
const signDegree = longitude % 30;            // 0-29.999...

// Validates: longitude 29.99 → Aries (index 0), not Taurus
// Validates: longitude 30.00 → Taurus (index 1) exactly
```

## Known Reference Positions

These are verifiable against public astronomical databases (JPL Horizons, AstroSeek).

### Spring Equinox 2024
- **Date/Time:** 2024-03-20 03:06:00 UTC
- **Julian Day:** 2460389.629167
- **Sun longitude:** ~0.0° (±0.01°) — 0° Aries exactly
- **Expected sign:** Aries, degree: ~0°

### Winter Solstice 2024
- **Date/Time:** 2024-12-21 09:20:00 UTC
- **Julian Day:** 2460665.889583
- **Sun longitude:** ~270.0° (±0.01°) — 0° Capricorn
- **Expected sign:** Capricorn, degree: ~0°

### Full Moon 2024-03-25
- **Date/Time:** 2024-03-25 07:00:00 UTC
- **Julian Day:** 2460394.791667
- **Moon longitude:** ~185° (±0.1°) — in Libra
- **Sun longitude:** ~5.1° — in Aries
- **Angular separation:** ~180° (full moon condition)

### Saturn-Jupiter Conjunction Reference (2020-12-21)
- **Date/Time:** 2020-12-21 18:20:00 UTC
- **Jupiter longitude:** ~300.4° (Aquarius)
- **Saturn longitude:** ~300.5° (Aquarius)
- **Orb:** ~0.1° — tightest conjunction in 400 years, verifiable
