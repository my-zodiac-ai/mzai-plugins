---
name: notifications-push
description: >
  Push notification and notifications-v2 module patterns for My Zodiac AI — Firebase
  Cloud Messaging, Apple Push Notification Service, in-app notifications, WebSocket
  delivery, scheduling, templates, and AI-generated content. Use when the user asks
  to "add push notification", "send notification", "FCM", "APN", "in-app notification",
  "notification template", "scheduled notification", "пуш-нотификация", "добавь уведомление",
  "нотификация", or works with the notifications-v2 module.
x-scope: adapter:nestjs
x-stack: nestjs
---

# Notifications & Push — My Zodiac AI

## Module Structure

```
notifications-v2/
├── delivery/
│   ├── push/              # FCM (Android), APN (iOS), DeviceToken management
│   └── in-app/            # In-app history, WebSocket gateway
├── content/               # Content resolver, static templates, AI pipeline
├── engine/                # Decision engine, rate limiter
├── queues/                # 5 BullMQ priority queues
├── scheduling/            # Timezone-aware scheduling, crons, digest
├── monitoring/            # Metrics, AI budget, admin
├── prediction/            # Event prediction service
├── listeners/             # NotificationEventsListener (EDA)
└── proxy/                 # Legacy proxy controller
```

## Delivery Channels

### Firebase Cloud Messaging (Android + Web)

```typescript
import * as admin from 'firebase-admin';

async sendPush(token: string, notification: PushPayload): Promise<void> {
  await admin.messaging().send({
    token,
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: notification.data,
    android: {
      priority: 'high',
      notification: { channelId: notification.channel },
    },
  });
}
```

### Apple Push Notification Service (iOS)

```typescript
// Uses @parse/node-apn or firebase-admin (FCM can deliver to iOS too)
// Device tokens stored in DeviceToken collection
// Badge count tracked per user
```

### In-App Notifications (WebSocket)

```typescript
// Gateway delivers to connected clients
@WebSocketGateway({ namespace: '/notifications' })
export class NotificationGateway {
  @WebSocketServer() server: Server;

  async deliverToUser(userId: string, notification: InAppNotification): void {
    this.server.to(`user:${userId}`).emit('notification', notification);
  }
}
```

## Priority Queue System

```
CRITICAL   → Immediate delivery (payment confirmations, security alerts)
HIGH       → Within 1 minute (transit alerts, Forge Alerts)
NORMAL     → Within 5 minutes (daily horoscope ready)
BULK       → Batch processing (weekly digest, marketing)
AI_GENERATION → AI content generation before send
```

## Content Pipeline

```
1. Event triggers notification (EDA)
2. Content resolver picks template or AI pipeline
3. Template: static with variable interpolation
4. AI pipeline: prompt → generate → moderate → deliver
5. Localization applied (user's preferred language)
```

### Template Pattern

```typescript
// content/templates/forge-alert.template.ts
export const forgeAlertTemplate = {
  push: {
    title: '{{planetName}} {{aspectType}} {{targetPlanet}}',
    body: '{{shortDescription}}',
  },
  inApp: {
    title: '{{planetName}} {{aspectType}} {{targetPlanet}}',
    body: '{{fullDescription}}',
    action: { type: 'navigate', route: '/cosmic-weather/forge-alert/{{alertId}}' },
  },
};
```

## EDA Integration

```typescript
// listeners/notification-events.listener.ts
@Injectable()
export class NotificationEventsListener {
  @OnEvent('cosmic-weather.forge-alert.created', { async: true })
  async handleForgeAlertCreated(payload: ForgeAlertCreatedEvent): Promise<void> {
    try {
      await this.notificationEngine.enqueue({
        userId: payload.userId,
        channel: ['push', 'in-app'],
        priority: 'HIGH',
        template: 'forge-alert',
        data: payload,
      });
    } catch (error) {
      this.logger.error('Failed to enqueue forge alert notification', { error });
    }
  }

  @OnEvent(PaymentEvents.SUBSCRIPTION_UPGRADED, { async: true })
  async handleSubscriptionUpgraded(payload: SubscriptionUpgradedEvent): Promise<void> {
    try {
      await this.notificationEngine.enqueue({
        userId: payload.userId,
        channel: ['push', 'in-app'],
        priority: 'CRITICAL',
        template: 'subscription-upgraded',
        data: { newTier: payload.newTier },
      });
    } catch (error) {
      this.logger.error('Failed to enqueue upgrade notification', { error });
    }
  }
}
```

## Scheduling

- **Timezone-aware**: All scheduled notifications respect user's IANA timezone
- **Digest**: Weekly/monthly notification summaries
- **Quiet hours**: Configurable per user (default: 22:00-08:00 local time)
- **Cron jobs**: Daily horoscope notification at user's preferred time

## Device Token Management

```typescript
// Store device tokens per user per platform
interface DeviceToken {
  userId: string;
  token: string;
  platform: 'ios' | 'android' | 'web';
  createdAt: Date;
  lastUsedAt: Date;
  isActive: boolean;
}
```

## Rules

1. **Always use EDA** — never send notifications by calling notification service directly from other modules
2. **Always localize** — use user's preferred language for content
3. **Respect quiet hours** — check scheduling service before sending
4. **Rate limit per user** — prevent notification spam (engine/rate-limiter)
5. **Handle token expiry** — mark tokens inactive on delivery failure
6. **AI budget tracking** — monitor cost of AI-generated notification content
7. **Never throw from listeners** — catch, log, degrade gracefully
