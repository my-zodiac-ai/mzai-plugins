---
name: capacitor-mobile-ops
description: >
  Full mobile lifecycle for My Zodiac AI — Capacitor 8 builds (debug/release/staging),
  plugin management, splash/icon generation, app signing, native dependency checks,
  and CI/CD pipelines for iOS/Android. Trigger on: "capacitor build", "cap sync",
  "мобильная сборка", "iOS build", "Android build", "build APK/IPA", "app signing",
  "подпись приложения", "keystore", "provisioning profile", "splash screen", "app icons",
  "генерация иконок", "capacitor plugin", "cap doctor", "native dependencies",
  "mobile CI/CD", "GitHub Actions mobile", "билд для стора", "Play Store", "App Store",
  "TestFlight", "product flavors", "versionCode", "hot reload mobile", "cap run".
  Also trigger on mobile debugging: white screen on device, pod install failures,
  Gradle errors, Xcode signing problems — even without "Capacitor" keyword.
---

# Capacitor Mobile Ops — My Zodiac AI

Complete mobile development lifecycle for the Vue 3 + Quasar + Capacitor 8 app.

## Project Layout

```
front/
├── src-capacitor/
│   ├── capacitor.config.ts    # Main config (appId, plugins, server)
│   ├── package.json           # Capacitor deps
│   ├── android/               # Android Studio project
│   │   └── app/
│   │       └── build.gradle   # Flavors (dev/prod), signing, SDK versions
│   ├── ios/
│   │   └── App/
│   │       ├── App.xcodeproj
│   │       ├── Podfile         # CocoaPods dependencies
│   │       └── Pods/
│   └── scripts/
│       └── fix-package-swift.js
└── package.json               # Quasar build scripts (build:android, build:ios, sync:*, etc.)
```

## Key Config Values

| Property | Android | iOS |
|----------|---------|-----|
| App ID | `org.yakovliev.myzodiacai` | `org.yakovliev.myzodiacai` |
| Min SDK / Version | 24 / compileSdk 36 | iOS 16.0 |
| Current version | `1.0.8.beta-7` (versionCode 220) | Check Xcode |
| Package manager | Gradle + google-services | CocoaPods (SPM disabled) |
| Flavors | `dev` (`.debug` suffix), `prod` | — |

## Commands Quick Reference

All commands run from `front/` directory.

### Build & Sync

```bash
# Full production build + sync
pnpm build:android            # quasar build -m capacitor -T android
pnpm build:ios                # quasar build -m capacitor -T ios

# Sync only (after web build)
pnpm sync:android             # build + cap sync android
pnpm sync:ios                 # build + cap sync ios

# Dev environment build
pnpm build:android:dev        # BUILD_ENV=dev variant

# Open native IDE
pnpm open:android             # cap open android
pnpm open:ios                 # cap open ios
```

### Run & Hot Reload

```bash
# Run on device/emulator
pnpm preview:android          # build + cap run android
pnpm preview:ios              # build + cap run ios

# Hot reload (dev server on device)
pnpm android:hot              # quasar dev -m capacitor -T android --host
pnpm ios:hot:local            # quasar dev -m capacitor -T ios --host --lan

# Production run (for QA testing)
pnpm prod:run:ios
pnpm prod:run:android
```

### Assets

```bash
# Generate splash screens and icons from source images
pnpm splash:generate          # cd src-capacitor && npx @capacitor/assets generate
pnpm splash:remove            # Clean generated splash assets
```

## Workflows

### 1. Debug Build (Development)

The goal is to get the app running on a local device or emulator with hot reload for fast iteration.

```bash
cd front

# Option A: Hot reload (fastest iteration)
pnpm ios:hot:local    # or android:hot

# Option B: Full debug build
pnpm sync:android:dev   # Builds with dev flavor
pnpm open:android       # Opens Android Studio → Run
```

For Android dev flavor, the app installs as "My Zodiac AI DEV" with `.debug` suffix on the app ID, so it can coexist with the production app.

### 2. Release Build

Read `references/signing.md` for detailed signing setup — this is the most error-prone part of mobile development and getting it wrong blocks store submission.

**Android:**
```bash
cd front
pnpm build:android
pnpm open:android
# In Android Studio: Build → Generate Signed Bundle/APK
# Select "prod" flavor, "release" build type
```

**iOS:**
```bash
cd front
pnpm build:ios
pnpm open:ios
# In Xcode: Product → Archive → Distribute App
```

### 3. Plugin Management

When adding or updating Capacitor plugins:

```bash
cd front

# Install a new plugin
pnpm add @capacitor/camera

# Sync native projects (ALWAYS after plugin changes)
cd src-capacitor && npx cap sync

# Verify plugin registration
npx cap doctor
```

After adding a plugin, check that:
- Android: plugin is auto-registered in `MainActivity` or `capacitor.build.gradle`
- iOS: pod is added to Podfile and `pod install` succeeds
- TypeScript types are available in your IDE

**Currently installed plugins** — read `references/plugins.md` for the full list with version compatibility notes.

### 4. Splash Screens & Icons

The project uses `@capacitor/assets` (v3.0.5) to generate all required sizes from source images.

```bash
cd front/src-capacitor

# Place source files:
#   resources/icon-only.png      (1024x1024, no background)
#   resources/icon-background.png (1024x1024, background color)
#   resources/icon-foreground.png (1024x1024, adaptive icon foreground)
#   resources/splash.png          (2732x2732, centered logo)
#   resources/splash-dark.png     (2732x2732, dark mode variant)

npx @capacitor/assets generate
```

This generates all platform-specific sizes into `android/app/src/main/res/` and `ios/App/App/Assets.xcassets/`.

### 5. Native Dependency Compatibility Check

When you suspect version conflicts or before major upgrades, run a full compatibility audit. Read `references/compatibility.md` for the checklist covering:
- Capacitor core ↔ plugin version matrix
- Android: Gradle version, AGP, compileSdk, targetSdk, Java/Kotlin version
- iOS: Xcode version, CocoaPods version, deployment target, Swift version
- Third-party native SDK compatibility (Firebase, PostHog, etc.)

Quick health check:
```bash
cd front/src-capacitor
npx cap doctor                    # Capacitor's built-in checker
cd android && ./gradlew dependencies  # Android dependency tree
cd ../ios/App && pod outdated     # iOS outdated pods
```

### 6. Version Bumping

Android versioning lives in `front/src-capacitor/android/app/build.gradle`:
- `versionCode` — integer, must increment for every Play Store upload (currently 220)
- `versionName` — human-readable string (currently "1.0.8.beta-7")

iOS versioning lives in Xcode project settings:
- `CFBundleShortVersionString` — marketing version
- `CFBundleVersion` — build number

When bumping, always update both platforms to stay in sync.

### 7. CI/CD Pipeline

Read `references/ci-cd.md` for GitHub Actions workflow templates covering:
- Android debug APK build on PR
- Android release AAB build on tag
- iOS archive + TestFlight upload
- Firebase App Distribution for beta testing

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| White screen on device | `webDir` mismatch or build not synced | Run `pnpm sync:android` (or ios), verify `capacitor.config.ts` has `webDir: 'www'` |
| `pod install` fails | CocoaPods version or cache | `cd ios/App && pod install --repo-update` or `pod deintegrate && pod install` |
| Gradle build error | SDK/AGP version mismatch | Check `references/compatibility.md`, delete `android/.gradle/` and retry |
| Plugin not found at runtime | Forgot to sync after install | `cd src-capacitor && npx cap sync` |
| iOS signing error | Missing provisioning profile | Open Xcode → Signing & Capabilities, select team, enable auto-signing |
| `BUILD_ENV` not affecting build | Quasar needs env prefix | Use `VITE_` prefix for frontend env vars, `BUILD_ENV` for Quasar mode only |
| Hot reload not connecting | Device not on same network | Use `--host 0.0.0.0` and check firewall, or use `--lan` flag |
| Android dev vs prod conflict | Both installed simultaneously | Dev flavor has `.debug` appId suffix — this is expected behavior |
| `cap doctor` warnings | Outdated native platforms | `npx cap update android` / `npx cap update ios` |

## Secret Management

**Current state:** The Android `build.gradle` has hardcoded keystore passwords. This works locally but is a security risk and blocks CI/CD.

**Target state:** All signing secrets in environment variables.

Read `references/signing.md` for the migration guide from hardcoded secrets to env-based signing config, including the Gradle changes needed and GitHub Actions secrets setup.

## Environment Requirements

| Tool | Minimum Version | Check Command |
|------|----------------|---------------|
| Node.js | 22+ | `node -v` |
| pnpm | 9+ | `pnpm -v` |
| Capacitor CLI | 8.1+ | `npx cap --version` |
| Java | 17+ | `java -version` |
| Android Studio | Hedgehog+ | — |
| Android SDK | API 36 (compileSdk) | SDK Manager |
| Xcode | 15+ | `xcode-select -v` |
| CocoaPods | 1.14+ | `pod --version` |
| Ruby | 3.0+ (for CocoaPods) | `ruby -v` |
