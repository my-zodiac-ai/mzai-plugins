# Aspect Validation Reference

## Standard Aspect Angles

| Aspect       | Angle | Symbol | Nature  |
|-------------|-------|--------|---------|
| Conjunction  | 0°    | ☌      | Neutral |
| Sextile      | 60°   | ⚹      | Soft    |
| Square       | 90°   | □      | Hard    |
| Trine        | 120°  | △      | Soft    |
| Quincunx     | 150°  | ⚻      | Neutral |
| Opposition   | 180°  | ☍      | Hard    |

Minor aspects (if implemented): Semisquare 45°, Sesquiquadrate 135°, Semisextile 30°.

## Orb Validation Logic

### Expected Default Orbs (from `aspects.config.ts`)

| Aspect      | Standard orb | Sun/Moon orb |
|-------------|-------------|-------------|
| Conjunction | 8°          | 10°         |
| Opposition  | 8°          | 10°         |
| Trine       | 8°          | 8°          |
| Square      | 7°          | 8°          |
| Sextile     | 6°          | 6°          |

**Validation:** Read `common/configs/aspects.config.ts` and check these values match `DEFAULT_ASPECT_ORBS`.

### Aspect Detection Algorithm

Correct formula for angular difference between two planets:

```typescript
// Correct: shortest arc on the circle
function angularDiff(lon1: number, lon2: number): number {
  let diff = Math.abs(lon1 - lon2);
  if (diff > 180) diff = 360 - diff;
  return diff;
}

// Check against each aspect angle:
function detectAspect(lon1: number, lon2: number): AspectType | null {
  const diff = angularDiff(lon1, lon2);
  for (const [aspectType, angle] of ASPECT_ANGLES) {
    const orb = getAspectOrb(aspectType, planet1, planet2);
    if (Math.abs(diff - angle) <= orb) {
      return { type: aspectType, angle: diff, orb: Math.abs(diff - angle) };
    }
  }
  return null;
}
```

**Common bug:** Using `lon1 - lon2` without taking shortest arc → misses aspects across 0°/360° boundary.

### Applying vs Separating

```typescript
// Planet with higher speed is "applying" if moving toward exact aspect
// Applying = orb is decreasing over time
const isApplying = (speed1 - speed2) * (lon2 - lon1) > 0;
// Simplified: compare current orb vs orb 1 day later
```

### Validation Test Cases

| Planet 1 | lon1  | Planet 2 | lon2  | Expected Aspect | orb   |
|----------|-------|----------|-------|----------------|-------|
| Sun      | 0°    | Moon     | 180°  | Opposition     | 0°    |
| Sun      | 0°    | Jupiter  | 120°  | Trine          | 0°    |
| Sun      | 5°    | Saturn   | 95°   | Square         | 0°    |
| Mercury  | 350°  | Venus    | 10°   | Conjunction    | 0° (cross 360) |
| Sun      | 179°  | Mars     | 1°    | Opposition     | 2° (cross 360) |

**Critical:** The Mercury/Sun and Sun/Mars cases test the 360° wraparound.

## Synastry Context

Synastry uses slightly wider orbs. Validate that `getSynastryAspectOrb()` in
`features/relationships/configs/aspect-orbs.config.ts` delegates to unified config
and does NOT hardcode its own values (regression risk on config changes).

Search for: duplicate orb definitions outside `common/configs/aspects.config.ts`.
