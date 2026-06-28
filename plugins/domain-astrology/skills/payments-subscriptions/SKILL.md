---
name: payments-subscriptions
description: >
  Payment processing and subscription management patterns for My Zodiac AI —
  DodoPayments, Apple In-App Purchase, Google Play Billing, webhook handling,
  subscription lifecycle, tier management, and receipt validation. Use when the
  user asks to "add payment", "subscription flow", "Apple IAP", "Google billing",
  "DodoPayments", "webhook", "receipt validation", "tier management",
  "платежи", "подписка", "добавь оплату", or works with the payments or sagas modules.
x-scope: domain:astrology
x-stack: any
---

# Payments & Subscriptions — My Zodiac AI

## Module Structure

```
business/
├── payments/              # Payment providers & processing
│   ├── providers/
│   │   ├── dodo.provider.ts        # DodoPayments (web/card)
│   │   ├── apple.provider.ts       # Apple IAP
│   │   └── google.provider.ts      # Google Play Billing
│   ├── webhooks/
│   │   ├── dodo.webhook.ts         # DodoPayments webhook handler
│   │   ├── apple.webhook.ts        # Apple Server Notifications V2
│   │   └── google.webhook.ts       # Google RTDN
│   ├── services/
│   │   └── subscription.service.ts # Subscription lifecycle
│   └── schemas/
│       ├── subscription.schema.ts
│       └── payment-event.schema.ts
├── sagas/                 # Subscription sagas (EDA)
│   └── subscription.saga.ts
└── cost-tracking/         # AI cost tracking per user
```

## Subscription Tiers

| Tier | Features | Price |
|------|----------|-------|
| `free` | Basic horoscope, limited AI | $0 |
| `premium` | Full horoscope, cosmic weather, relationships, unlimited AI | $X/month |
| `premium_annual` | Same as premium, annual billing | $X/year |

## Subscription Lifecycle (State Machine)

```
[created] → [active] → [grace_period] → [expired]
                ↕                            ↓
           [cancelled]                   [free]
```

### Key Transitions:
- **Purchase** → `created` → `active` (immediate)
- **Renewal** → `active` stays `active` (extends expiry)
- **Cancel** → `active` → `cancelled` (still active until period end)
- **Period end after cancel** → `cancelled` → `expired` → `free`
- **Grace period** → `active` → `grace_period` (payment retry window)
- **Resubscribe** → any → `active`

## Webhook Handling Pattern

```typescript
// webhooks/apple.webhook.ts
@Controller('webhooks/apple')
export class AppleWebhookController {
  @Post()
  @HttpCode(200) // Apple requires 200 response
  async handleNotification(@Body() body: AppleServerNotification): Promise<void> {
    // 1. Verify signature (JWS)
    const verified = await this.verifyAppleSignature(body.signedPayload);
    if (!verified) throw new UnauthorizedException('Invalid signature');

    // 2. Parse notification type
    const { notificationType, subtype, data } = this.parsePayload(verified);

    // 3. Process based on type
    switch (notificationType) {
      case 'DID_RENEW':
        await this.subscriptionService.handleRenewal(data);
        break;
      case 'DID_CHANGE_RENEWAL_STATUS':
        if (subtype === 'AUTO_RENEW_DISABLED') {
          await this.subscriptionService.handleCancellation(data);
        }
        break;
      case 'EXPIRED':
        await this.subscriptionService.handleExpiry(data);
        break;
      case 'GRACE_PERIOD_EXPIRED':
        await this.subscriptionService.handleGracePeriodExpiry(data);
        break;
    }

    // 4. Emit event (for EDA side effects)
    // Event is emitted INSIDE subscriptionService AFTER DB save
  }
}
```

## EDA Events for Payments

```typescript
// events/enums/payment-events.enum.ts
export enum PaymentEvents {
  SUBSCRIPTION_CREATED = 'payment.subscription.created',
  SUBSCRIPTION_UPGRADED = 'payment.subscription.upgraded',
  SUBSCRIPTION_DOWNGRADED = 'payment.subscription.downgraded',
  SUBSCRIPTION_CANCELLED = 'payment.subscription.cancelled',
  SUBSCRIPTION_EXPIRED = 'payment.subscription.expired',
  SUBSCRIPTION_RENEWED = 'payment.subscription.renewed',
  PAYMENT_FAILED = 'payment.failed',
  REFUND_PROCESSED = 'payment.refund.processed',
}
```

**Side effects via EDA:**
- `SUBSCRIPTION_UPGRADED` → invalidate tier cache, send notification, unlock features
- `SUBSCRIPTION_EXPIRED` → lock premium features, send win-back notification
- `PAYMENT_FAILED` → notify user, enter grace period

## Subscription Saga

```typescript
// sagas/subscription.saga.ts
// Orchestrates complex subscription state transitions
// that span multiple modules (payments, users, notifications, restrictions)

@Injectable()
export class SubscriptionSaga {
  @OnEvent(PaymentEvents.SUBSCRIPTION_UPGRADED, { async: true })
  async onUpgrade(payload: SubscriptionUpgradedEvent): Promise<void> {
    try {
      // 1. Update user tier in DB
      await this.restrictionsService.updateTier(payload.userId, payload.newTier);

      // 2. Invalidate caches (tier, horoscope, cosmic weather)
      await this.cacheService.invalidateUserCaches(payload.userId);

      // 3. Send confirmation notification
      this.eventEmitter.emit('notification.send', {
        userId: payload.userId,
        template: 'subscription-upgraded',
        priority: 'CRITICAL',
      });

      // 4. Track analytics
      this.eventEmitter.emit('analytics.track', {
        userId: payload.userId,
        event: 'subscription_upgraded',
        properties: { from: payload.oldTier, to: payload.newTier },
      });
    } catch (error) {
      this.logger.error('Subscription saga failed', { error });
      // Never throw — saga failures are logged and monitored
    }
  }
}
```

## Receipt Validation

### Apple

```typescript
// Verify receipt with Apple App Store Server API
async validateAppleReceipt(transactionId: string): Promise<boolean> {
  const response = await this.appleClient.getTransactionInfo(transactionId);
  return response.status === 0 && !response.isRevoked;
}
```

### Google

```typescript
// Verify with Google Play Developer API
async validateGooglePurchase(packageName: string, subscriptionId: string, token: string): Promise<boolean> {
  const result = await this.googleClient.purchases.subscriptions.get({
    packageName, subscriptionId, token,
  });
  return result.data.paymentState === 1; // Received
}
```

## Tier Restrictions

```typescript
// core/restrictions/ module
// Controls what features are available per tier

interface TierRestrictions {
  tier: 'free' | 'premium';
  maxAiGenerationsPerDay: number;
  hasCosmicWeather: boolean;
  hasRelationships: boolean;
  hasForgeAlerts: boolean;
  hasDetailedHoroscope: boolean;
}
```

## Rules

1. **Webhook idempotency** — always check if event was already processed (store `transactionId`)
2. **Verify signatures** — never trust unverified webhook payloads
3. **DB save before event emit** — subscription state saved, then EDA event emitted
4. **Never throw from sagas** — log failures, alert via monitoring
5. **Return 200 to webhooks immediately** — process asynchronously via BullMQ if needed
6. **Grace period handling** — give users time before locking features
7. **Test with sandbox** — Apple Sandbox and Google test accounts for development
8. **Track all payments** — every transaction logged to `payment-event` collection for audit
