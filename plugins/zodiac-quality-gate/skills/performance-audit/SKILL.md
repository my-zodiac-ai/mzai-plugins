---
name: performance-audit
description: >
  Audit code for performance issues — N+1 queries, memory leaks, algorithmic complexity,
  unbounded operations, missing caching, and optimization opportunities. Use when the user asks to
  "check performance", "performance audit", "optimize", "find bottlenecks", "проверь производительность",
  "найди утечки памяти", "N+1 queries", "memory leak", "slow query", or wants to improve
  application speed and resource efficiency. Trigger proactively when reviewing database queries,
  loops over collections, or API endpoint handlers.
---

# Performance Audit

Identify performance bottlenecks, resource leaks, and optimization opportunities across backend and frontend.

## Audit Dimensions

### 1. Database Performance (MongoDB)

| Issue | Pattern to find |
|---|---|
| **N+1 queries** | Loop containing `await model.findOne()` or `await model.findById()` |
| **Missing indexes** | Queries on fields without indexes; check with `.explain()` |
| **Unbounded queries** | `find({})` without `.limit()` — can return entire collection |
| **Over-fetching** | Queries without `.select()` that return all fields when only a few are needed |
| **Missing lean()** | Read-only queries without `.lean()` — wastes memory on Mongoose hydration |
| **Aggregation misuse** | Large `$lookup` pipelines that could be denormalized |

### 2. Memory & Resource Leaks

- Event listeners not cleaned up in `onModuleDestroy`
- Redis connections not properly closed
- BullMQ workers without graceful shutdown
- Frontend: subscriptions/intervals not cleared in `onUnmounted`
- Large objects held in closure scope unnecessarily
- Unbounded in-memory caches without TTL or size limits

### 3. Algorithmic Complexity

- O(n^2) or worse in hot paths (nested loops over arrays)
- String concatenation in loops (use array.join)
- Repeated array.includes/find where a Set/Map would be O(1)
- Sorting followed by filtering (filter first, sort the smaller set)

### 4. API & Network

- Missing response caching (Redis/Keyv) for expensive computations
- No request deduplication for concurrent identical requests
- Missing pagination on list endpoints
- Large payloads without compression
- Sequential API calls that could be parallel (`Promise.all`)

### 5. Frontend Performance

| Issue | Check |
|---|---|
| **Bundle size** | Unnecessary large imports; tree-shaking not working |
| **Re-renders** | Computed without memoization; reactive objects triggering unnecessary updates |
| **Lazy loading** | Routes and heavy components not lazy-loaded |
| **Image optimization** | Missing srcset, uncompressed images, no lazy loading |
| **Virtual scrolling** | Long lists (>100 items) without virtual scrolling |

### 6. Caching Strategy

- AI interpretation results: should be semantically cached (ai-manager)
- Horoscope calculations: should be cached by date+sign (deterministic)
- User profile data: should have short TTL in Redis
- Static reference data: should be cached at startup

## Output Format

```markdown
# Performance Audit Report

## Summary
- **Risk**: HIGH / MEDIUM / LOW
- **Estimated Impact**: [e.g., "3x latency reduction on horoscope endpoint possible"]
- **Critical Bottlenecks**: N | **Optimizations**: N | **Info**: N

## Critical Bottlenecks
### [PERF-001] N+1 query in getRelationships endpoint
- **File**: `back/src/modules/astrology/features/relationships/relationships.service.ts:67-82`
- **Issue**: For each relationship, fetches partner's natal chart individually
- **Impact**: 1 + N queries per request; with 10 relationships = 11 DB calls
- **Fix**: Use `$lookup` aggregation or batch query with `$in` operator
- **Estimated gain**: ~10x latency reduction

## Optimization Opportunities
...

## Caching Recommendations
| Resource | Current | Recommended | Strategy |
|---|---|---|---|
| Daily horoscope | No cache | 1h TTL | Redis, key: `horoscope:{sign}:{date}` |
```
