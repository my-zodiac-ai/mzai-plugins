---
name: chaos-engineering
description: >
  Chaos engineering for My Zodiac AI — create fault injection experiments, execute chaos tests,
  validate circuit breakers and fallbacks, monitor auto-recovery, and generate resilience reports.
  Integrated with the fault-tolerance module (opossum, graceful degradation, retry, auto-recovery)
  and tests/chaos/. Use whenever the user mentions: "chaos test", "fault injection", "resilience
  check", "circuit breaker test", "проверь отказоустойчивость", "хаос тест", "fallback test",
  "memory pressure test", "database failure test", "network latency test", "kill service",
  "recovery test", or asks "what happens if X goes down", "will the app survive", "test our
  fallbacks", "how resilient is [service]" — even without saying "chaos engineering".
x-scope: adapter:nestjs
x-stack: nestjs
---

# Chaos Engineering Skill

You are a chaos engineering specialist for the My Zodiac AI monorepo. Your job is to help the
team build confidence in the system's resilience by designing, executing, and reporting on
controlled failure experiments.

## Why this matters

My Zodiac AI runs a complex stack: NestJS backend, MongoDB, Redis, BullMQ queues, external AI
providers, geocoding APIs, and push notification services. Any of these can fail. The
`fault-tolerance` module provides circuit breakers, retries, graceful degradation, and
auto-recovery — but those mechanisms are only valuable if they're tested under realistic failure
conditions. That's what this skill is for.

---

## Project Context

### Fault-Tolerance Module Structure

The backend has a full DDD-structured fault-tolerance module at
`back/src/modules/fault-tolerance/`:

```
fault-tolerance/
├── domain/
│   ├── entities/          # CircuitBreakerState, SystemHealthMetric, ErrorLog, etc.
│   ├── events/            # HealthCheckCompleted, CircuitBreakerTripped, ServiceRecovered, etc.
│   ├── services/          # FaultToleranceDomainService
│   └── repositories.ts
├── application/services/
│   ├── circuit-breaker.service.ts      # Opossum-based circuit breakers
│   ├── retry.service.ts               # Configurable retry with backoff
│   ├── graceful-degradation.service.ts # Multi-level degradation (full → degraded → minimal → emergency)
│   ├── auto-recovery.service.ts        # Automatic health checks + recovery
│   ├── error-recovery.service.ts       # Error classification + recovery strategies
│   ├── memory-pressure.service.ts      # Memory usage monitoring + GC triggers
│   ├── component-health.service.ts     # Per-component health tracking
│   ├── availability-monitor.service.ts # Uptime and availability metrics
│   ├── alerting.service.ts             # Alert triggering based on thresholds
│   └── fault-tolerance-metrics.service.ts
├── infrastructure/
│   ├── external/
│   │   ├── opossum-circuit-breaker.service.ts  # Opossum library wrapper
│   │   └── load-balancer.service.ts
│   ├── caching/           # Multi-layer cache (memory L1 + Redis L2) with fallback
│   ├── database/          # Connection pool management
│   └── monitoring/        # Diagnostic collector, resource monitor
└── presentation/controllers/
    ├── health.controller.ts
    ├── circuit-breaker.controller.ts
    ├── performance.controller.ts
    └── error-recovery.controller.ts
```

### Existing Chaos Tests

Located in `tests/chaos/`:
- `database-failure.test.ts` — MongoDB connection timeout, query failures
- `network-latency.test.ts` — Simulated network delays with config in `network-latency.json`
- `memory-pressure.test.ts` — Heap pressure scenarios

Additional resilience tests:
- `tests/resilience/db-recovery.spec.ts` — Database recovery after failure
- `tests/fault-tolerance/circuit-breaker.spec.ts` — Circuit breaker state transitions

### Key EDA Events

All fault-tolerance communication uses EventEmitter2:
- `HealthCheckCompleted` — status: healthy | degraded | unhealthy
- `CircuitBreakerTripped` — state transitions: closed → open → half-open
- `GracefulDegradationActivated` — degradation levels: partial | minimal | offline
- `ServiceRecovered` — automatic or manual recovery completed
- `PerformanceAlertTriggered` — threshold breaches with severity levels

### Circuit Breakers in the Wild

Circuit breakers are used across many modules (not just fault-tolerance):
- **AI Manager** — `ai-circuit-breaker.config.ts` for LLM provider failover
- **Redis** — `redis-circuit-breaker.service.ts` for cache layer protection
- **Notifications** — `circuit-breaker.service.ts` for push/email delivery
- **Horoscope Generator** — circuit breaker for AI generation calls
- **Geocoding** — Google API service with circuit breaker wrapping
- **NewRelic Monitoring** — `circuit-breaker-monitoring.service.ts` for observability

---

## Workflow

When the user asks for a chaos engineering task, follow this sequence:

### 1. Understand the Target

Identify what the user wants to test. Common scenarios:

| Scenario | Target Services | Key Files |
|----------|----------------|-----------|
| Database failure | MongoDB, ConnectionPool | `database-resilience.service.ts`, `tests/chaos/database-failure.test.ts` |
| Redis outage | Cache layers, BullMQ | `redis-circuit-breaker.service.ts`, `fallback-cache.service.ts` |
| AI provider failure | AI Manager, LLM providers | `ai-circuit-breaker.config.ts`, `ai-generation-orchestrator.service.ts` |
| Network latency | External APIs, Geocoding | `tests/chaos/network-latency.test.ts` |
| Memory pressure | All services | `memory-pressure.service.ts`, `tests/chaos/memory-pressure.test.ts` |
| Push notification failure | FCM/APN delivery | `push-notification-sender.ts`, `circuit-breaker.service.ts` |
| Full system resilience | All of the above | Combined experiment |

### 2. Audit Existing Protections

Before injecting faults, verify what protections exist for the target:

```typescript
// Check: Does the target service have a circuit breaker?
// Search for opossum usage or CircuitBreakerService.createCircuitBreaker() calls
// targeting the service in question.

// Check: Is there a fallback/degradation path?
// Look for GracefulDegradationService usage and FallbackConfig definitions.

// Check: Are there retry policies?
// Search for RetryService usage with the target service.

// Check: Are there existing chaos tests covering this scenario?
// Check tests/chaos/, tests/resilience/, tests/fault-tolerance/
```

Use `grep` or Serena's `search_for_pattern` to find these. Report gaps — if a service lacks
circuit breaker protection, that's a finding even before running any experiment.

### 3. Create the Chaos Experiment

Generate a Vitest test file following the project's existing patterns. Place new experiments in
`tests/chaos/` to keep them alongside the existing ones.

**Template for a new chaos experiment:**

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { describe, it, expect, vi, beforeAll, afterAll, beforeEach } from 'vitest';

describe('Chaos: [Scenario Name]', () => {
  let app: INestApplication;
  let eventEmitter: EventEmitter2;
  const emittedEvents: Array<{ event: string; payload: any }> = [];

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [/* AppModule or targeted module */],
    })
      // Override providers to inject faults
      .overrideProvider(/* TargetService */)
      .useValue(/* Faulty mock */)
      .compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    // Capture EDA events for verification
    eventEmitter = app.get(EventEmitter2);
    eventEmitter.onAny((event, payload) => {
      emittedEvents.push({ event: String(event), payload });
    });
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    emittedEvents.length = 0;
  });

  describe('Fault Injection: [specific failure]', () => {
    it('should activate graceful degradation when [service] fails', async () => {
      // 1. Inject the fault (timeout, error, resource exhaustion)
      // 2. Make a request that touches the faulty service
      // 3. Assert: response is degraded but not a 500
      // 4. Assert: circuit breaker tripped event was emitted
      // 5. Assert: fallback data was served
    });

    it('should recover automatically when [service] comes back', async () => {
      // 1. Inject fault
      // 2. Verify degradation
      // 3. Remove fault (restore mock)
      // 4. Wait for auto-recovery interval
      // 5. Assert: ServiceRecovered event emitted
      // 6. Assert: service returns to full functionality
    });
  });

  describe('Blast Radius Validation', () => {
    it('should not affect unrelated endpoints during [service] failure', async () => {
      // Verify that failure in one bounded context doesn't cascade
    });
  });
});
```

### 4. Execute the Experiment

Run the chaos test with verbose output and limited lines to keep context manageable:

```bash
cd back && npx vitest run ../tests/chaos/[experiment].test.ts --reporter=verbose 2>&1 | head -100
```

For existing chaos tests:
```bash
cd back && npx vitest run ../tests/chaos/ --reporter=verbose 2>&1 | head -150
```

If tests require the full app bootstrap and it's too heavy, suggest running targeted module
tests instead:
```bash
cd back && npx vitest run src/modules/fault-tolerance/__tests__/ --reporter=verbose 2>&1 | head -100
```

### 5. Validate Circuit Breaker Behavior

After running experiments, verify circuit breaker states are correct. The key state machine:

```
CLOSED (normal) → OPEN (failure threshold exceeded) → HALF-OPEN (recovery probe) → CLOSED
                                                     ↘ OPEN (probe failed)
```

Things to check:
- **Threshold sensitivity** — Does the breaker open at the configured `errorThresholdPercentage`?
- **Recovery timeout** — Does it transition to half-open after `resetTimeout` ms?
- **Probe behavior** — Does a successful probe close the breaker?
- **Event emission** — Is `CircuitBreakerTripped` emitted on every state change?
- **Metric recording** — Are failure counts persisted to `CircuitBreakerState` entity?

### 6. Generate the Resilience Report

After experiments complete, produce a structured markdown report. Save it to
`docs/reports/chaos/` with a timestamped filename.

**Report template:**

```markdown
# Chaos Engineering Report

**Date:** YYYY-MM-DD
**Experiment:** [Scenario Name]
**Target:** [Service/Module under test]
**Executed by:** AI Agent

## Executive Summary

[1-2 sentences: did the system pass or fail? What's the overall resilience posture?]

## Experiment Configuration

| Parameter | Value |
|-----------|-------|
| Fault type | [timeout / error / resource exhaustion / kill] |
| Target service | [service name] |
| Duration | [how long the fault was active] |
| Blast radius | [what other services were affected] |

## Results

### Circuit Breaker Behavior

| Breaker | Expected State | Actual State | Verdict |
|---------|---------------|--------------|---------|
| [service]-breaker | OPEN after 5 failures | OPEN after 5 failures | PASS |

### Graceful Degradation

| Degradation Level | Triggered | Fallback Served | User Impact |
|-------------------|-----------|-----------------|-------------|
| degraded | Yes | Cached data | Partial |

### Auto-Recovery

| Metric | Value |
|--------|-------|
| Time to detect failure | X ms |
| Time to activate fallback | X ms |
| Time to recover (after fault removed) | X ms |
| Recovery type | automatic / manual |

### Event Emission

| Event | Emitted | Payload Valid |
|-------|---------|---------------|
| CircuitBreakerTripped | Yes | Yes |
| GracefulDegradationActivated | Yes | Yes |
| ServiceRecovered | Yes | Yes |

## Findings

### Passed
- [What worked well]

### Issues Found
- **[CRITICAL/WARNING/INFO]**: [Description of the issue]
  - **Impact:** [What would happen in production]
  - **Recommendation:** [How to fix]

## Recommendations

1. [Prioritized action items]
```

---

## Fault Injection Patterns

Use these patterns when creating mocks for fault injection. They match what the existing chaos
tests already do.

### Database Timeout
```typescript
.overrideProvider(getModelToken(MyModel.name))
.useValue({
  find: vi.fn().mockImplementation(() => ({
    exec: vi.fn().mockRejectedValue(new Error('Connection timeout')),
    lean: vi.fn().mockReturnThis(),
    sort: vi.fn().mockReturnThis(),
    limit: vi.fn().mockReturnThis(),
  })),
  findOne: vi.fn().mockImplementation(() => ({
    exec: vi.fn().mockRejectedValue(new Error('Connection timeout')),
  })),
})
```

### Network Latency
```typescript
// Inject delay into an external service call
const originalMethod = targetService.callExternalApi;
targetService.callExternalApi = vi.fn().mockImplementation(async (...args) => {
  await new Promise(resolve => setTimeout(resolve, 5000)); // 5s delay
  return originalMethod.apply(targetService, args);
});
```

### Service Kill (complete unavailability)
```typescript
.overrideProvider(ExternalService)
.useValue({
  healthCheck: vi.fn().mockRejectedValue(new Error('ECONNREFUSED')),
  execute: vi.fn().mockRejectedValue(new Error('Service unavailable')),
})
```

### Memory Pressure
```typescript
// Allocate memory to trigger pressure detection
const memoryHog: Buffer[] = [];
const allocateMemory = () => {
  for (let i = 0; i < 100; i++) {
    memoryHog.push(Buffer.alloc(1024 * 1024)); // 1MB chunks
  }
};
// After test: memoryHog.length = 0; global.gc?.();
```

### Redis Failure
```typescript
// Mock Redis client to simulate outage
.overrideProvider('REDIS_CLIENT')
.useValue({
  get: vi.fn().mockRejectedValue(new Error('ECONNREFUSED')),
  set: vi.fn().mockRejectedValue(new Error('ECONNREFUSED')),
  del: vi.fn().mockRejectedValue(new Error('ECONNREFUSED')),
  ping: vi.fn().mockRejectedValue(new Error('ECONNREFUSED')),
})
```

---

## Safety Rules

Chaos experiments can be destructive if mishandled. Follow these rules:

1. **Never run against production data.** All experiments use mocked providers or test databases.
2. **Always clean up.** Restore original mocks in `afterAll`/`afterEach`. Free allocated memory.
3. **Limit blast radius.** Test one failure mode at a time unless explicitly testing cascading failures.
4. **Set timeouts.** Every fault injection should have a maximum duration. Use Vitest's built-in test timeout: `it('...', async () => { ... }, 30_000)`.
5. **Capture events.** Always wire up `eventEmitter.onAny()` to verify EDA behavior — silent failures are the most dangerous kind.
6. **Don't throw from async listeners.** This is a project-wide rule. If your test creates event listeners, wrap them in try/catch.

---

## Common Tasks

### "Run all chaos tests"
```bash
cd back && npx vitest run ../tests/chaos/ ../tests/resilience/ ../tests/fault-tolerance/ --reporter=verbose 2>&1 | head -200
```

### "Check circuit breaker coverage"
Search for services that call external APIs or databases but lack circuit breaker protection:
1. Find all external service calls (`@Injectable` classes that use HttpService, fetch, mongoose models)
2. Cross-reference with circuit breaker registrations in `CircuitBreakerService`
3. Report unprotected services

### "Validate fallback coverage"
For each service with a circuit breaker, check that there's a matching `FallbackConfig` in
`GracefulDegradationService`. Services with circuit breakers but no fallback will fail open
(return errors to users) rather than degrade gracefully.

### "Test cascading failure"
Create a multi-fault experiment that takes down two or more services simultaneously. This tests
whether the system's isolation boundaries (bounded contexts) actually work. The expectation is
that failure in one module (e.g., AI) should not affect unrelated modules (e.g., auth).
