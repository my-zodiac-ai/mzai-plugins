---
name: ai-provider-integration
description: >
  LLM provider integration patterns for My Zodiac AI — Messages API, streaming,
  tool use, prompt caching, and cost tracking. Use when the user asks
  to "integrate LLM provider", "add AI provider", "add streaming",
  "add tool use", "prompt caching", "add AI SDK", "AI provider pattern",
  "добавь AI провайдер", "стриминг", "кэширование промптов",
  or works with the anthropic.provider.ts in the ai-manager module.
x-scope: core
x-stack: any
---

# AI Provider Integration — My Zodiac AI

Patterns for the LLM provider in `back/src/modules/ai/ai-manager/providers/anthropic.provider.ts`.

## SDK Setup

```typescript
import Anthropic from '@anthropic-ai/sdk';

const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});
```

## Messages API

```typescript
const response = await anthropic.messages.create({
  model: 'claude-sonnet-4-20250514',
  max_tokens: 4096,
  messages: [
    { role: 'user', content: prompt },
  ],
  system: 'You are an expert astrologer providing personalized interpretations.',
});

const text = response.content[0].type === 'text' ? response.content[0].text : '';
```

## Streaming

```typescript
const stream = anthropic.messages.stream({
  model: 'claude-sonnet-4-20250514',
  max_tokens: 4096,
  messages: [{ role: 'user', content: prompt }],
});

for await (const event of stream) {
  if (event.type === 'content_block_delta' && event.delta.type === 'text_delta') {
    yield event.delta.text; // SSE to frontend
  }
}

const finalMessage = await stream.finalMessage();
// Track tokens: finalMessage.usage.input_tokens, finalMessage.usage.output_tokens
```

## Prompt Caching

```typescript
// Cache system prompt to reduce costs on repeated calls
const response = await anthropic.messages.create({
  model: 'claude-sonnet-4-20250514',
  max_tokens: 4096,
  system: [
    {
      type: 'text',
      text: longSystemPrompt, // Cached after first call
      cache_control: { type: 'ephemeral' },
    },
  ],
  messages: [{ role: 'user', content: userPrompt }],
});
// Check: response.usage.cache_read_input_tokens
```

## Cost Tracking

```typescript
interface AICostMetrics {
  provider: 'anthropic';
  model: string;
  inputTokens: number;
  outputTokens: number;
  cacheReadTokens: number;
  costCents: number;
  latencyMs: number;
}

// Model pricing (per 1M tokens, approximate)
const PRICING = {
  'claude-sonnet-4-20250514': { input: 3.0, output: 15.0, cacheRead: 0.3 },
  'claude-haiku-3-5-20241022': { input: 0.8, output: 4.0, cacheRead: 0.08 },
};
```

## Provider Pattern in My Zodiac AI

```typescript
@Injectable()
export class AnthropicProvider {
  private client: Anthropic;
  private circuitBreaker: CircuitBreaker;

  async generate(prompt: string, options: GenerationOptions): Promise<string> {
    if (this.circuitBreaker.isOpen()) {
      throw new ProviderUnavailableError('anthropic');
    }

    try {
      const response = await this.client.messages.create({
        model: this.selectModel(options.tier),
        max_tokens: options.maxTokens ?? 4096,
        messages: [{ role: 'user', content: prompt }],
        system: options.systemPrompt,
      });

      this.circuitBreaker.recordSuccess();
      return this.extractText(response);
    } catch (error) {
      this.circuitBreaker.recordFailure();
      throw error;
    }
  }

  private selectModel(tier: string): string {
    return tier === 'premium'
      ? 'claude-sonnet-4-20250514'
      : 'claude-haiku-3-5-20241022';
  }
}
```

## Rules

1. **Always track token usage and costs** — emit to AIMetricsService
2. **Use prompt caching** for repeated system prompts (saves 90%+ on system tokens)
3. **Circuit breaker** on every provider — open after 5 failures in 60s
4. **Timeout**: 30s for standard, 60s for streaming
5. **Never expose API keys** — always from environment variables
6. **Model routing**: Haiku for basic, Sonnet for detailed interpretations
