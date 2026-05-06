# Capacitor Plugins — My Zodiac AI

## Currently Installed

All plugins are Capacitor 8.x compatible. Listed with their purpose and any platform-specific notes.

### Core Capacitor

| Package | Version | Purpose |
|---------|---------|---------|
| `@capacitor/core` | ^8.1.0 | Core runtime |
| `@capacitor/cli` | ^8.1.0 | CLI tools (dev dependency) |
| `@capacitor/android` | ^8.1.0 | Android platform |
| `@capacitor/ios` | ^8.1.0 | iOS platform |

### Device & System

| Package | Version | Purpose |
|---------|---------|---------|
| `@capacitor/app` | ^8.0.1 | App lifecycle events (foreground, background, URL open) |
| `@capacitor/device` | ^8.0.1 | Device info (model, OS, platform) |
| `@capacitor/keyboard` | ^8.0.1 | Keyboard show/hide events, scroll behavior |
| `@capacitor/network` | ^8.0.1 | Network status monitoring |
| `@capacitor/status-bar` | ^8.0.1 | Status bar styling (dark text on dark background in this app) |
| `@capacitor/splash-screen` | ^8.0.1 | Splash screen control (auto-hide after 2s, bg: #0A0E27) |

### Storage & Files

| Package | Version | Purpose |
|---------|---------|---------|
| `@capacitor/preferences` | ^8.0.1 | Key-value storage (async, replaces old Storage plugin) |
| `@capacitor/filesystem` | ^8.1.2 | File read/write operations |

### Interaction

| Package | Version | Purpose |
|---------|---------|---------|
| `@capacitor/haptics` | ^8.0.1 | Haptic feedback (used for UI interactions) |
| `@capacitor/browser` | ^8.0.1 | In-app browser for external links |
| `@capacitor/share` | ^8.0.1 | Native share sheet |

### Push & Notifications

| Package | Version | Purpose |
|---------|---------|---------|
| `@capacitor/push-notifications` | ^8.0.1 | Firebase/APNs push notifications |

### Third-Party (Capawesome / Capgo)

| Package | Version | Purpose | Notes |
|---------|---------|---------|-------|
| `@capawesome/capacitor-app-review` | ^8.0.1 | Native app review prompt | Triggers in-app review dialog |
| `@capawesome/capacitor-posthog` | ^8.2.1 | PostHog analytics native bridge | Pairs with web PostHog SDK |
| `@capgo/capacitor-social-login` | ^8.3.6 | Google + Apple Sign-In | Configured in capacitor.config.ts |

### Asset Generation (Dev Only)

| Package | Version | Purpose |
|---------|---------|---------|
| `@capacitor/assets` | ^3.0.5 | Generate splash screens and icons from source images |

## Adding a New Plugin

```bash
cd front

# 1. Install the package
pnpm add @capacitor/camera

# 2. Sync native projects
cd src-capacitor && npx cap sync

# 3. If the plugin needs config, add to capacitor.config.ts:
# plugins: { Camera: { ... } }

# 4. For iOS — verify pod was added
cd ios/App && cat Podfile  # should list new pod
pod install                # if not auto-run by sync

# 5. For Android — most plugins auto-register
# Check android/app/src/main/java/.../MainActivity.java if issues
```

## Updating Plugins

```bash
cd front

# Update all Capacitor packages to latest compatible
pnpm update @capacitor/core @capacitor/cli @capacitor/android @capacitor/ios
pnpm update @capacitor/app @capacitor/browser @capacitor/device ...

# Always sync after updating
cd src-capacitor && npx cap sync

# Check for breaking changes
npx cap doctor
```

When upgrading major versions (e.g., Capacitor 8 → 9), follow the official migration guide — don't just bump versions. Plugin APIs may change.

## Plugin Configuration in capacitor.config.ts

Currently configured plugins:

```typescript
plugins: {
    PushNotifications: {
        presentationOptions: ['badge', 'sound', 'alert'],
    },
    SplashScreen: {
        launchShowDuration: 2000,
        launchAutoHide: true,
        backgroundColor: '#0A0E27',  // Match app background
        showSpinner: false,
        splashFullScreen: true,
        splashImmersive: true,
    },
    SocialLogin: {
        providers: {
            google: true,
            apple: true,
            facebook: false,
            twitter: false,
        },
    },
    StatusBar: {
        style: 'DARK',
        backgroundColor: '#000000',
        overlaysWebView: false,
    },
}
```
