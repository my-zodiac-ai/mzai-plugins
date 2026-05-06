# Cross-Engine Comparison Reference

## Available Reference Engines

| Engine | npm package | Notes |
|--------|------------|-------|
| Astronomy Engine | `astronomy-engine` | NASA-grade, MIT license |
| astronomia | `astronomia` | VSOP87-based |
| ephemeris (npm) | `ephemeris` | Swiss Ephemeris JS port |
| AstroSeek (web) | — | Online reference, manual lookup |
| JPL Horizons (web) | — | NASA authoritative source |

## Quick Comparison Script

Install and run from back/:

```bash
cd back && npm install --no-save astronomy-engine && node -e "
const Astronomy = require('astronomy-engine');

// Spring Equinox 2024
const date = new Date('2024-03-20T03:06:00Z');
const sun = Astronomy.GeoVector('Sun', date, true);
const ecliptic = Astronomy.Ecliptic(sun);
console.log('Sun ecliptic longitude:', ecliptic.elon.toFixed(4));
// Expected: ~0.0 (±0.05)

// Winter Solstice 2024
const date2 = new Date('2024-12-21T09:20:00Z');
const sun2 = Astronomy.GeoVector('Sun', date2, true);
const ecliptic2 = Astronomy.Ecliptic(sun2);
console.log('Sun ecliptic longitude (solstice):', ecliptic2.elon.toFixed(4));
// Expected: ~270.0 (±0.05)
"
```

Compare results against sweph output. Acceptable delta: ≤ 0.05° for Sun, ≤ 0.15° for Moon.

## Systematic Comparison Checklist

For each planet, compare sweph vs reference engine for 3 dates:
1. Spring Equinox 2024 (2024-03-20 03:06 UTC)
2. Winter Solstice 2024 (2024-12-21 09:20 UTC)
3. Current date at 00:00 UTC

| Planet   | sweph lon | engine lon | delta | Status |
|---------|-----------|------------|-------|--------|
| Sun     |           |            |       |        |
| Moon    |           |            |       |        |
| Mercury |           |            |       |        |
| Venus   |           |            |       |        |
| Mars    |           |            |       |        |
| Jupiter |           |            |       |        |
| Saturn  |           |            |       |        |

Fill this table in the validation report.

## Known Differences Between Engines

### Ayanamsa (Tropical vs Sidereal)
- Swiss Ephemeris defaults to **tropical** zodiac (no ayanamsa)
- My Zodiac AI uses tropical — verify no ayanamsa correction is applied unless explicitly in sidereal mode
- Ayanamsa currently ≈ 24° (Lahiri) — if results are off by ~24°, ayanamsa is being incorrectly applied

### Light-Time Correction
- Swiss Ephemeris applies light-time correction (geometric position at time of observation)
- Some simpler engines use geometric position — 4-8 arcsecond difference for Sun, up to 1° for Moon
- Acceptable for My Zodiac AI use case

### Coordinate Systems
- Swiss Ephemeris returns **ecliptic longitude** (what we use)
- Some engines return **right ascension** — requires conversion
- Verify the coordinate system being used: `sweph.calc_ut()` with `SEFLG_SWIEPH` returns ecliptic coordinates

## Post-Update Regression Baseline

When updating `sweph` package, record these baseline values and compare after update:

```json
{
  "baseline_date": "YYYY-MM-DD",
  "sweph_version": "x.x.x",
  "test_jd": 2460389.629167,
  "positions": {
    "Sun": { "lon": 0.0, "lat": 0.0, "dist": 0.994 },
    "Moon": { "lon": 180.5, "lat": -1.2, "dist": 0.00257 }
  }
}
```

If any position drifts > 0.001° between versions, investigate sweph changelog for algorithm changes.
