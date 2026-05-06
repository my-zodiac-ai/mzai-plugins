---
name: ai-llm-patterns
description: >
  AI/LLM orchestration patterns for My Zodiac AI — multi-provider fallback,
  cost optimization, semantic caching, prompt building, and streaming. Use when
  the user asks to "add AI generation", "optimize AI costs", "create prompt",
  "add provider fallback", "AI оркестрация", "оптимизация AI", "добавь промпт",
  "semantic cache", "streaming", or works with the ai-manager module.
---

# AI/LLM Patterns — My Zodiac AI

Patterns for `back/src/modules/ai/`.

## AI Module Structure

```
ai/
├── ai-manager/
│   ├── ai-manager.service.ts              # Facade — entry point
│   ├── ai-cost-optimizer.service.ts        # Cost optimization (40-60% savings)
│   ├── ai-metrics.service.ts               # Cost & performance tracking
│   ├── rate-limiter.service.ts             # Per-user rate limiting
│   ├── intelligent-cache.service.ts         # Semantic similarity cache
│   ├── semantic-cache.service.ts            # Vector-based caching
│   ├── prompt-compression.service.ts        # Token reduction (-46%)
│   ├── ai-tier.service.ts                   # Model tier routing
│   ├── providers/
│   │   ├── openai.provider.ts              # Primary (GPT-4o)
│   │   ├── anthropic.provider.ts           # Secondary (Claude)
│   │   └── gemini.provider.ts              # Tertiary (Gemini)
│   ├── services/
│   │   ├── ai-provider-orchestrator.service.ts  # Provider lifecycle
│   │   ├── ai-generation-orchestrator.service.ts # Generation workflow
│   │   └── ai-fallback.service.ts               # Fallback logic
│   └── constants/
│       └── ai-constants.ts                 # Thresholds, model configs
├── ai-chat/                                # Conversational AI
├── ai-streaming/                           # SSE streaming responses
└── prompt-builder/                         # Prompt template system
```

## AIManagerService — Facade Pattern

```typescript
@Injectable()
export class AIManagerService {
  // Fallback chain: OpenAI → Anthropic → Gemini
  // Each provider has circuit breaker protection
  // Intelligent cache: 90%+ hit rate for similar requests

  async generateInterpretation(request: GenerationRequest): Promise<GenerationResult> {
    // 1. Check rate limits
    await this.rateLimiterService.checkLimit(request.userId);

    // 2. Check semantic cache
    const cached = await this.intelligentCacheService.get(request);
    if (cached) return cached;

    // 3. Route to optimal provider via orchestrator
    const result = await this.generationOrchestrator.generate(request);

    // 4. Cache result
    await this.intelligentCacheService.set(request, result);

    // 5. Track metrics
    this.aiMetricsService.trackGeneration(result);

    return result;
  }
}
```

## Cost Optimization Strategies

The `AICostOptimizer` achieves 40-60% cost reduction through:

### 1. Semantic Caching (Vector Similarity)

```typescript
// If a semantically similar request was made before, return cached result
// Uses vector embeddings to find similar prompts (cosine similarity > threshold)
const cached = await this.semanticCacheService.findSimilar(request.prompt);
```

### 2. Prompt Compression (-46% Tokens)

```typescript
// Compress prompt tokens while maintaining quality
const compressed = await this.promptCompressionService.compress(prompt);
// AI_QUALITY_THRESHOLD ensures output quality doesn't degrade
```

### 3. Tiered Model Routing

```typescript
// Route to cheaper models for simpler requests
interface GenerationRequest {
  metadata?: {
    detailLevel?: 'basic' | 'detailed' | 'comprehensive';
    // basic → smaller model, comprehensive → full model
  };
  forceTier?: string; // Override tier selection
}
```

## Provider Fallback Chain

```
OpenAI (Primary) → Anthropic (Secondary) → Gemini (Tertiary)
     ↓ if circuit open        ↓ if circuit open        ↓ if all fail
     Skip to next              Skip to next              Return error
```

Each provider has:
- **Circuit breaker** — opens after N failures, auto-resets after cooldown
- **Retry logic** — exponential backoff for transient errors
- **Timeout** — per-request timeout to prevent hanging

## Prompt Building

```typescript
// prompt-builder/templates/horoscope.template.ts
export function buildHoroscopePrompt(params: HoroscopeParams): string {
  return `You are an expert astrologer...
    Sign: ${params.sign}
    Planet positions: ${JSON.stringify(params.planets)}
    Aspects: ${JSON.stringify(params.aspects)}
    ...generate ${params.detailLevel} interpretation...`;
}
```

## Streaming Responses

```typescript
// ai-streaming/ — Server-Sent Events (SSE) for real-time AI output
@Controller('ai')
export class AIStreamController {
  @Sse('stream/:requestId')
  streamResponse(@Param('requestId') id: string): Observable<MessageEvent> {
    return this.aiStreamingService.getStream(id);
  }
}
```

## Key Interfaces

```typescript
interface GenerationRequest {
  prompt: string;
  type: string;          // 'horoscope', 'relationship', 'transit', 'cosmic-story'
  metadata?: {
    planet?: string;
    sign?: string;
    house?: number;
    relationshipType?: string;
    detailLevel?: 'basic' | 'detailed' | 'comprehensive';
  };
  userId?: string;
  useCompression?: boolean;
  forceTier?: string;
}

interface GenerationResult {
  text: string;
  provider: string;      // 'openai', 'anthropic', 'gemini'
  metadata: {
    tier: string;
    wasCompressed: boolean;
    tokensUsed: number;
    costCents: number;
    latencyMs: number;
    cacheHit: boolean;
  };
}
```

## Rules for AI Code

1. **Always go through AIManagerService** — never call providers directly
2. **Rate limit all user-facing AI calls** — prevent abuse
3. **Cache aggressively** — semantic cache for similar requests
4. **Track all costs** — every generation must emit cost metrics
5. **Test with mocks** — AI providers return mock responses in test env
6. **Handle provider failures gracefully** — fallback chain must work
7. **Never expose raw AI errors to users** — translate to user-friendly messages
