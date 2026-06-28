---
name: nestjs-caching
description: >
  NestJS mapping of the caching-patterns core — cache-manager/Keyv, Redis, BullMQ queues, and
  Redlock distributed locks. Use when implementing or reviewing caching, background jobs, or
  distributed locks in a NestJS service ("add caching", "cache this endpoint", "BullMQ job",
  "distributed lock", "кэш в Nest", "добавь очередь").
x-scope: adapter:nestjs
x-stack: nestjs
---

# NestJS Caching (adapter)

Apply the `caching-patterns` core first — it owns the method, TTL policy, and rules. This file only
maps it to NestJS syntax; do not duplicate the method here.

## Cache-aside
Inject the cache as optional so the app degrades without Redis (core rule #1):
```typescript
constructor(@Inject(CACHE_MANAGER) @Optional() private readonly cache?: Cache) {}

async getDaily(userId: string) {
  const key = cacheKey(CACHE_PREFIX.FORECAST, userId);     // key generator from config
  const hit = await this.cache?.get(key);
  if (hit) return hit;
  const value = await this.compute(userId);
  await this.cache?.set(key, value, FORECAST_TTL_MS);      // explicit TTL
  return value;
}
```

## Keys
Put the prefix map + `cacheKey()` generator in the project's `config/` — never inline key strings.

## Invalidation (event-driven, never throws)
```typescript
@OnEvent(PaymentEvents.SUBSCRIPTION_UPGRADED, { async: true })
async onUpgrade({ userId }: { userId: string }) {
  try { await this.cache?.del(cacheKey(CACHE_PREFIX.ENTITLEMENT, userId)); }
  catch (e) { this.logger.error('cache invalidation failed', { e }); }  // swallow + log
}
```

## Stampede protection (Redlock)
```typescript
const lock = await this.lockService.acquire(`lock:${key}`, 30_000);
try {
  const existing = await this.repo.findOne({ userId });   // double-check after acquiring
  if (existing) return existing;
  return await this.computeAndSave(userId);
} finally { await lock.release(); }
```

## Background jobs (BullMQ)
```typescript
BullModule.registerQueue({
  name: 'forecast-scan',
  defaultJobOptions: { attempts: 3, backoff: { type: 'exponential', delay: 5000 },
                       removeOnComplete: 100, removeOnFail: 200 },
});
// @Processor('forecast-scan') extends WorkerHost; job name = {feature}-{action}
```

See core `caching-patterns` for the TTL policy, in-memory LRU guidance, and the full rule list.
