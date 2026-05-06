---
name: astrology-domain
description: >
  Astrology domain expertise for My Zodiac AI — Swiss Ephemeris calculations,
  natal charts, transits, synastry, and cosmic weather. Use when the user asks
  to "calculate natal chart", "add transit feature", "implement synastry",
  "astrology calculation", "Swiss Ephemeris", "planetary positions", "aspects",
  "houses", "natal chart", "horoscope", "космическая погода", "натальная карта",
  "транзиты", "синастрия", or works with the astrology module.
---

# Astrology Domain — My Zodiac AI

Domain expertise for the `back/src/modules/astrology/` module.

## Module Structure

```
astrology/
├── systems/
│   ├── western/          # Western zodiac (Swiss Ephemeris)
│   │   ├── services/
│   │   │   └── calculations.service.ts  # Main natal chart calculator
│   │   ├── schemas/
│   │   │   └── natal-chart.schema.ts
│   │   └── processors/
│   │       └── year-ahead-generation.processor.ts
│   └── lunar/            # Lunar calendar (lunar-typescript)
│       └── services/
├── features/
│   ├── horoscopes/       # Daily/weekly/monthly horoscopes
│   ├── relationships/    # Synastry & compatibility
│   ├── cosmic-weather/   # Transits & Forge Alerts (v2/v3)
│   ├── cosmic-self/      # Personal natal profile
│   └── cosmic-story/     # AI narrative interpretations
└── common/
    ├── services/
    │   ├── swiss-ephemeris.service.ts     # Low-level sweph wrapper
    │   ├── swiss-ephemeris-gateway.service.ts  # Higher-level API
    │   ├── sweph-adapter.ts              # Native binding adapter
    │   └── chart-events.service.ts       # Event emitter for charts
    ├── constants/
    │   ├── thresholds.constants.ts       # Orbs, degrees, counts
    │   └── astrology.constants.ts        # Zodiac signs, planets
    ├── utils/
    │   ├── aspect-calculator.util.ts     # Unified aspect calculation
    │   ├── astrology-math.util.ts        # Midpoints, degrees
    │   ├── transit-time.util.ts          # Transit timing
    │   ├── coordinate-validation.util.ts # Lat/lon validation
    │   └── timezone.utils.ts             # IANA timezone conversion
    └── enums/
        └── house-system.enum.ts          # Placidus, Koch, etc.
```

## Swiss Ephemeris Integration

The project uses `sweph` (npm package) as the native binding to Swiss Ephemeris C library.

### Key Service: `CalculationsService`

```typescript
// astrology/systems/western/services/calculations.service.ts
@Injectable()
export class CalculationsService {
  // LRU cache for planet positions (1000 entries, 1h TTL)
  private readonly positionCache = new LRUCache<string, PlanetPosition>({
    max: 1000,
    ttl: 3_600_000,
  });

  async calculateNatalChart(birthData: BirthData): Promise<NatalChart> {
    // 1. Convert birth time to UTC using IANA timezone
    const utcDate = convertToUTC(birthData.dateTime, birthData.timezone);

    // 2. Validate coordinates
    validateCoordinatesOrThrow(birthData.latitude, birthData.longitude);

    // 3. Calculate Julian day number
    const julianDay = swisseph.julday(utcDate);

    // 4. Calculate planetary positions
    const planets = await this.calculatePlanetPositions(julianDay);

    // 5. Calculate houses (default: Placidus)
    const houses = this.calculateHouses(julianDay, birthData.latitude, birthData.longitude);

    // 6. Calculate aspects between planets
    const aspects = calculateNatalAspects(planets);

    // 7. Emit chart calculated event
    this.chartEventsService.emitNatalChartCalculated({ userId, chart });

    return { planets, houses, aspects, metadata };
  }
}
```

### Key Constants

```typescript
// thresholds.constants.ts
export const DEGREES_PER_SIGN = 30;
export const ZODIAC_CIRCLE_DEGREES = 360;
export const HOUSES_COUNT = 12;
export const HOUSE_ASCENDANT_INDEX = 0;
export const HOUSE_MIDHEAVEN_INDEX = 9;
export const DEFAULT_BIRTH_TIME = '12:00'; // noon for unknown birth time
```

### Zodiac Signs

```typescript
// astrology.constants.ts
export const ZODIAC_SIGN_NAMES = [
  'Aries', 'Taurus', 'Gemini', 'Cancer',
  'Leo', 'Virgo', 'Libra', 'Scorpio',
  'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
];
```

## Key Schemas

### Natal Chart

```typescript
// schemas/natal-chart.schema.ts
interface NatalChart {
  userId: string;
  birthDate: Date;
  birthTime: string;
  birthPlace: { latitude: number; longitude: number; name: string };
  timezone: string;
  planets: PlanetPosition[];
  houses: House[];
  aspects: Aspect[];
  calculatedAt: Date;
}

interface PlanetPosition {
  planet: string;      // 'Sun', 'Moon', 'Mercury', etc.
  longitude: number;   // 0-360 degrees
  latitude: number;
  speed: number;       // degrees/day (negative = retrograde)
  sign: string;        // 'Aries', 'Taurus', etc.
  signDegree: number;  // 0-30 degrees within sign
  house: number;       // 1-12
  isRetrograde: boolean;
}

interface Aspect {
  planet1: string;
  planet2: string;
  type: string;        // 'conjunction', 'opposition', 'trine', 'square', 'sextile'
  angle: number;       // exact angle
  orb: number;         // deviation from exact
  isApplying: boolean; // approaching exact aspect
}
```

## Cosmic Weather (Transits)

The cosmic weather feature calculates current planetary transits and their impact on a user's natal chart.

**Forge Alerts** — real-time notifications about significant transits affecting the user. Severity levels: low, medium, high, critical.

**Events emitted:**
- `chart.natal.calculated` → triggers initial Forge Alert scan
- `cosmic-weather.calculated` → daily weather update

## Relationships & Synastry

Compares two natal charts to assess compatibility:
- Aspect analysis between charts
- House overlay (where partner's planets fall in your houses)
- Composite chart calculation

## Rules for Astrology Code

1. **Always validate coordinates** with `validateCoordinatesOrThrow()`
2. **Always handle timezone** — use `convertToUTC()` from timezone.utils
3. **Cache planet positions** — expensive calculations via Swiss Ephemeris
4. **Use distributed locks** for chart creation (prevent duplicates)
5. **Emit events after save** — `chart.natal.calculated` only after MongoDB commit
6. **Default birth time is noon** when user doesn't provide time
7. **Use unified aspect calculator** — `calculateNatalAspects()` from utils
