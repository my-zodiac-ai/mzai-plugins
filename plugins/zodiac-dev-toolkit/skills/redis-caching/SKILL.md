---
name: redis-caching
description: >
  Redis and Keyv caching patterns for My Zodiac AI — cache-aside, TTL strategies,
  invalidation, hot keys, BullMQ queue patterns, and distributed locks. Use when
  the user asks to "add caching", "cache this endpoint", "Redis pattern",
  "invalidate cache", "кэширование", "добавь кэш", "Redis TTL", "distributed lock",
  "BullMQ queue", "add background job", or works with the infrastructure/redis or
  infrastructure/cache modules.
---

# Redis & Caching Patterns — My Zodiac AI

## Stack

- **Redis 7+** via `@nestjs/cache-manager` (Keyv adapter)
- **BullMQ 5.x** for job queues
- **Distributed locks** via Redlock (`infrastructure/redlock/`)
- **LRU in-memory caches** for hot data (e.g., planet positions)

## Cache Architecture

```
infrastructure/
├── redis/                 # Redis connection, config
├── cache/                 # Cache layer abstractions
├── queue/                 # BullMQ queue definitions
└── redlock/               # Distributed lock service
```

## Cache-Aside Pattern (Primary Pattern)

```typescript
@Injectable()
export class CosmicWeatherService {
  constructor(
    @Inject(CACHE_MANAGER) @Optional() private readonly cacheManager?: Cache,
  ) {}

  async getDaily(userId: string): Promise<CosmicWeatherResult> {
    const cacheKey = generateCacheKey(CACHE_KEY_PREFIX.COSMIC_WEATHER, userId);

    // 1. Try cache
    const cached = await this.cacheManager?.get<CosmicWeatherResult>(cacheKey);
    if (cached) return cached;

    // 2. Compute
    const result = await this.calculateWeather(userId);

    // 3. Store in cache with TTL
    await this.cacheManager?.set(cacheKey, result, COSMIC_WEATHER_TTL_MS);

    return result;
  }
}
```

## Cache Key Conventions

```typescript
// config/redis.config.ts
export const CACHE_KEY_PREFIX = {
  COSMIC_WEATHER: 'cw',
  HOROSCOPE: 'horoscope',
  NATAL_CHART: 'natal',
  USER_TIER: 'tier',
  AI_GENERATION: 'ai-gen',
  RATE_LIMIT: 'rl',
} as const;

export function generateCacheKey(prefix: string, ...parts: string[]): string {
  return `${prefix}:${parts.join(':')}`;
}
// Example: "cw:userId:2026-03-19"
```

## TTL Strategy

| Data Type | TTL | Reasoning |
|-----------|-----|-----------|
| Natal chart | 24h | Rarely changes, expensive to compute |
| Daily horoscope | 6h | Updated few times per day |
| Cosmic weather | 1h | Transits change slowly |
| User tier | 5min | Must reflect subscription changes quickly |
| AI generation | 24h | Semantic cache, costly to regenerate |
| Rate limit counters | 1min sliding window | Per-user rate limiting |

## Cache Invalidation

**Event-driven invalidation** (preferred):

```typescript
// listeners/cosmic-weather-events.listener.ts
@OnEvent(PaymentEvents.SUBSCRIPTION_UPGRADED, { async: true })
async handleSubscriptionUpgraded(payload: { userId: string }): Promise<void> {
  try {
    const key = generateCacheKey(CACHE_KEY_PREFIX.COSMIC_WEATHER, payload.userId);
    await this.cacheManager?.del(key);
    this.logger.log(`Invalidated CW cache for ${payload.userId} after upgrade`);
  } catch (error) {
    // Never throw from listeners
    this.logger.error('Cache invalidation failed', { error });
  }
}
```

**Pattern rules:**
- Invalidate on write (subscription change, chart recalculation)
- Use EDA listeners for cross-module invalidation
- Batch delete with prefix: `del cw:userId:*`
- Never rely on TTL alone for critical data changes

## In-Memory LRU Cache (Hot Data)

```typescript
import { LRUCache } from 'lru-cache';

// For extremely hot, frequently accessed, compute-heavy data
private readonly positionCache = new LRUCache<string, PlanetPosition>({
  max: 1000,           // Max entries
  ttl: 3_600_000,      // 1 hour
});
```

Use LRU cache for:
- Planet position calculations (Swiss Ephemeris is CPU-heavy)
- Zodiac sign lookups
- Aspect orb configurations

## BullMQ Queue Patterns

```typescript
// Defining a queue
@Module({
  imports: [
    BullModule.registerQueue({
      name: 'cosmic-weather-v2-forge-scan',
      defaultJobOptions: {
        attempts: 3,
        backoff: { type: 'exponential', delay: 5000 },
        removeOnComplete: 100,
        removeOnFail: 200,
      },
    }),
  ],
})

// Adding a job
@InjectQueue('cosmic-weather-v2-forge-scan')
private readonly cwQueue: Queue;

await this.cwQueue.add('scan-user', { userId, triggerSource: 'natal-chart-calculated' }, {
  priority: 1,  // Higher priority
  delay: 2000,  // Wait 2s for eventual consistency
});

// Processing a job
@Processor('cosmic-weather-v2-forge-scan')
export class ForgeAlertScanProcessor extends WorkerHost {
  async process(job: Job<ForgeAlertScanData>): Promise<void> {
    const { userId, triggerSource } = job.data;
    // Process...
  }
}
```

**Queue naming convention:** `{feature}-{action}` → `cosmic-weather-v2-forge-scan`

**5 Priority Queues** (notifications-v2):
- `CRITICAL` — immediate delivery
- `HIGH` — within 1 minute
- `NORMAL` — within 5 minutes
- `BULK` — batch processing
- `AI_GENERATION` — AI content generation

## Distributed Locks

```typescript
// Prevent duplicate chart calculations
const lockKey = `lock:natal-chart:${userId}`;
const lock = await this.distributedLockService.acquire(lockKey, 30_000); // 30s TTL
try {
  // Check if chart already exists (double-check after lock)
  const existing = await this.model.findOne({ userId }).exec();
  if (existing) return existing;

  // Calculate and save
  const chart = await this.calculateNatalChart(birthData);
  await this.model.create(chart);
  return chart;
} finally {
  await lock.release();
}
```

## Rules

1. **Always use `@Optional()`** for cache manager injection — app must work without Redis
2. **Always wrap cache operations** in try/catch — cache failures should degrade, not crash
3. **Use `generateCacheKey()`** — never hardcode cache key strings
4. **Invalidate through events** — not direct service calls across modules
5. **Set TTL on everything** — no unbounded cache entries
6. **LRU for hot paths** — Redis for shared state, LRU for single-instance hot data
7. **BullMQ retries** — always configure `attempts` and `backoff`
