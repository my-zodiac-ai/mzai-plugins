---
name: nestjs-backend-patterns
description: >
  NestJS backend architecture patterns for My Zodiac AI monorepo. Use when the user asks
  to "create a NestJS module", "add a service", "implement EDA event", "create event listener",
  "add repository", "create adapter", "resolve circular dependency", "add BullMQ job",
  "NestJS паттерн", "создай модуль", "добавь сервис", or needs guidance on EDA, DDD,
  adapter pattern, or bounded context design in the backend.
x-scope: adapter:nestjs
x-stack: nestjs
---

# NestJS Backend Patterns — My Zodiac AI

> **Not sure which skill to use?** See `references/when-to-use.md` for a full decision tree across all 11 skills.

Apply these patterns for ALL backend code in `back/src/modules/`.

## Architecture Stack

- **NestJS 11** + TypeScript 5.9
- **MongoDB** + Mongoose 9.1 (schemas, not raw driver)
- **Redis** + Keyv (caching), **BullMQ** (queues)
- **EventEmitter2** (EDA events)
- **Passport + JWT** (auth)
- **Vitest** (testing)

## Bounded Contexts

| Context | Modules | Owner |
|---------|---------|-------|
| `core` | auth, users, onboarding, restrictions, auth-shared | Auth & identity |
| `astrology` | systems/western, systems/lunar, features/horoscopes, features/relationships, features/cosmic-weather, features/cosmic-self, features/cosmic-story, common | Astrology calculations & interpretations |
| `ai` | ai-manager, ai-chat, ai-streaming, prompt-builder | AI orchestration |
| `business` | payments, analytics, reports, gdpr | Revenue & compliance |
| `notifications-v2` | channels, templates, scheduling | Push/email/in-app notifications |
| `infrastructure` | redis, queues, logging, monitoring | Technical services |

**Rule**: Never import directly across bounded contexts — use events or adapter tokens.

## EDA (Event-Driven Architecture)

### Domain Event Pattern

```typescript
// domain/events/subscription-upgraded.event.ts
export class SubscriptionUpgradedEvent {
  constructor(
    public readonly userId: string,
    public readonly newTier: string,
    public readonly oldTier: string,
    public readonly correlationId: string,
    public readonly occurredAt: Date = new Date(),
  ) {}
}
```

**Rules:**
- Name: `{Entity}{PastTense}Event`
- Always include `correlationId`
- Emit ONLY after `await repository.save()` succeeds
- Never emit inside a transaction

### Event Listener Pattern

```typescript
// listeners/cosmic-weather-events.listener.ts
@Injectable()
export class CosmicWeatherEventsListener {
  private readonly logger = new Logger(CosmicWeatherEventsListener.name);

  constructor(
    @Inject(CACHE_MANAGER) @Optional() private readonly cacheManager?: Cache,
    @InjectQueue('cosmic-weather-v2-forge-scan') @Optional() private readonly cwQueue?: Queue,
  ) {}

  @OnEvent(PaymentEvents.SUBSCRIPTION_UPGRADED, { async: true })
  async handleSubscriptionUpgraded(payload: { userId: string }): Promise<void> {
    try {
      await this.invalidateUserTierCache(payload.userId, 'upgraded');
    } catch (error) {
      // NEVER throw from async event listeners — only log
      this.logger.error('Failed to handle subscription upgrade', { error });
    }
  }
}
```

**Rules:**
- Always `{ async: true }` for async handlers
- Wrap in try/catch, NEVER throw
- Don't rely on listener execution order
- Side effects only (notifications, analytics, cache invalidation)

### Event Enums

Events are organized in `@events/enums/`:
- `PaymentEvents` — `SUBSCRIPTION_UPGRADED`, `SUBSCRIPTION_DOWNGRADED`, `SUBSCRIPTION_EXPIRED`
- `ChartEvents` — `chart.natal.calculated`, `chart.transit.calculated`
- `SystemEvents` — `user.registered`, `user.deleted`

## DDD Patterns

### Repository Pattern

```typescript
// domain/repositories/user.repository.interface.ts
export interface IUserRepository {
  findById(id: string): Promise<User | null>;
  save(user: User): Promise<User>;
  delete(id: string): Promise<void>;
}

export const USER_REPOSITORY = Symbol('IUserRepository');

// infrastructure/repositories/user.mongoose.repository.ts
@Injectable()
export class UserMongooseRepository implements IUserRepository {
  constructor(@InjectModel(User.name) private model: Model<UserDocument>) {}

  async findById(id: string): Promise<User | null> {
    const doc = await this.model.findById(id).exec();
    return doc ? UserMapper.toDomain(doc) : null;
  }
}
```

### Adapter Pattern — Breaking Circular Dependencies

```typescript
// common/tokens.ts
export const TRANSIT_SIGNIFICANCE_SERVICE = Symbol('TRANSIT_SIGNIFICANCE_SERVICE');
export const SWISS_EPHEMERIS_SERVICE = Symbol('SWISS_EPHEMERIS_SERVICE');
export const REDIS_CACHE_PROVIDER = Symbol('REDIS_CACHE_PROVIDER');
```

Real patterns used in the project:

| Pattern | Example | Problem Solved |
|---------|---------|---------------|
| `AuthSharedModule` | auth ↔ users | AuthModule imports UsersModule, UsersModule imports AuthSharedModule (not AuthModule) |
| `SharedSchemasModule` | Mongoose schemas | Multiple modules share schemas without direct dependency |
| `SystemEventsModule` | EventEmitter2 | Emitter doesn't know receiver — coupled only through events |
| Symbol tokens | `NOTIFICATION_ADAPTER` | Module depends on interface, not concrete class |
| `OptionalAuthUsersAdapter` | AI ← Users | AI module doesn't depend directly on UsersModule |

**NEVER use `forwardRef()`** — it's been fully removed from the codebase.

### Service Layer Pattern

```typescript
@Injectable()
export class CosmicWeatherService {
  private readonly logger = new Logger(CosmicWeatherService.name);

  constructor(
    @InjectModel(CosmicWeather.name) private model: Model<CosmicWeatherDocument>,
    @Inject(CACHE_MANAGER) @Optional() private readonly cacheManager?: Cache,
    private readonly swissEphemerisService: SwissEphemerisService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async calculateForUser(userId: string): Promise<CosmicWeatherResult> {
    // 1. Load from cache
    const cached = await this.tryGetFromCache(userId);
    if (cached) return cached;

    // 2. Calculate
    const result = await this.swissEphemerisService.calculateTransits(userId);

    // 3. Save to DB FIRST
    await this.model.create(result);

    // 4. THEN emit event
    this.eventEmitter.emit('cosmic-weather.calculated', { userId, result });

    return result;
  }
}
```

## BullMQ Queue Pattern

```typescript
// processors/year-ahead-generation.processor.ts
@Processor('year-ahead-generation')
export class YearAheadGenerationProcessor extends WorkerHost {
  async process(job: Job<YearAheadJobData>): Promise<void> {
    const { userId, year } = job.data;
    // Process with retry and backoff configured in queue options
  }
}
```

## Module Structure

```
back/src/modules/{context}/{feature}/
├── controllers/          # HTTP endpoints
├── services/             # Business logic
├── handlers/             # Command/Query handlers (CQRS)
├── listeners/            # EDA event listeners
├── processors/           # BullMQ queue processors
├── schemas/              # Mongoose schemas
├── dto/                  # Request/Response DTOs
├── interfaces/           # TypeScript interfaces
├── domain/               # Domain entities, events, repositories
│   ├── events/
│   ├── repositories/
│   └── entities/
├── infrastructure/       # Concrete implementations
│   └── repositories/
├── __tests__/            # Unit tests
└── {feature}.module.ts   # NestJS module
```

## Error Handling

Use project exceptions from `@common/exceptions`:
- `ResourceNotFoundException` — 404
- `BusinessLogicException` — 422
- `InternalServerException` — 500
- `AstrologyCalculationException` — domain-specific errors

Always include `ErrorCode` enum values for machine-readable error codes.

## Key Imports

```typescript
import { SafeLogger } from '@common/utils/safe-logger.util';
import { ErrorCode } from '@common/enums/error-code.enum';
import { EventEmitterService } from '@events/services/event-emitter.service';
```

For detailed references, read the actual docs:
- `docs/AI_ARCHITECTURE.md` — ADRs and boundary rules
- `docs/AI_PATTERNS.md` — code pattern examples
- `docs/AI_CONTEXT.md` — full module map

## Related Skills in Other Plugins

- **zodiac-feature-forge** `orchestrate-feature/references/backend-protocol.md` — step-by-step implementation sequence for new features (Schema → DTO → Service → Events → Controller → Tests)
- **zodiac-quality-gate** `architecture-audit` — verifies EDA/DDD compliance after implementation
- **zodiac-dev-toolkit** `redis-caching` — detailed Redis/BullMQ/caching patterns
- **zodiac-dev-toolkit** `payments-subscriptions` — payment webhooks and subscription lifecycle
- **zodiac-dev-toolkit** `notifications-push` — push notification and notifications-v2 patterns
