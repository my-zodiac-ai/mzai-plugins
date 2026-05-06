# Native Dependency Compatibility Check — My Zodiac AI

## Table of Contents
1. [Quick Health Check](#quick-health-check)
2. [Capacitor Version Matrix](#capacitor-version-matrix)
3. [Android Compatibility](#android)
4. [iOS Compatibility](#ios)
5. [Full Audit Checklist](#full-audit)

---

## Quick Health Check

Run these commands to get a fast overview of the current state:

```bash
cd front/src-capacitor

# Capacitor doctor — checks core + plugin versions
npx cap doctor

# Android dependency tree (look for version conflicts)
cd android && ./gradlew app:dependencies --configuration prodReleaseRuntimeClasspath 2>&1 | head -100

# iOS outdated pods
cd ../ios/App && pod outdated

# Check Node/pnpm versions
node -v   # should be 22+
pnpm -v   # should be 9+
```

## Capacitor Version Matrix

All `@capacitor/*` packages should share the same major version. Mixing majors (e.g., core 8.x with a plugin on 7.x) causes runtime errors.

**Current target: Capacitor 8.x**

Check alignment:
```bash
cd front
pnpm list | grep @capacitor
```

Every `@capacitor/*` package should show `8.x.x`. Third-party plugins (`@capawesome/*`, `@capgo/*`) have their own versioning but must declare Capacitor 8 peer dependency.

## Android Compatibility {#android}

### Current Settings (from build.gradle)

| Setting | Value | Notes |
|---------|-------|-------|
| `compileSdk` | 36 | Must match or exceed targetSdk |
| `targetSdk` | 36 | Latest stable API level |
| `minSdk` | 24 | Android 7.0 — covers ~97% of devices |
| `AGP` | Check `android/build.gradle` | Android Gradle Plugin version |
| `Gradle` | Check `gradle/wrapper/gradle-wrapper.properties` | |
| `Java` | 17 | Required for AGP 8+ |

### Compatibility Rules

- **AGP 8.x** requires **Gradle 8.x** and **Java 17+**
- **compileSdk 36** requires **Android Studio Ladybug** or newer
- **targetSdk 36** may require runtime permission changes — check Android 15 behavioral changes
- Google Play requires `targetSdk >= 34` for new apps/updates (as of Aug 2024)

### Firebase / Google Services

The project uses `com.google.gms.google-services` plugin. Ensure:
- `google-services.json` exists at `android/app/google-services.json`
- Google Services plugin version in `android/build.gradle` is compatible with AGP version
- Firebase BoM version is consistent across all Firebase libraries

### Common Version Conflict Patterns

1. **Duplicate classes** — two libraries include the same transitive dependency at different versions. Fix: add `exclude group:` in Gradle or use `resolutionStrategy`.
2. **AndroidX migration** — if any library still uses support libraries, add `android.enableJetifier=true` to `gradle.properties`.
3. **Kotlin version mismatch** — Capacitor 8 uses Kotlin that should match the version in `android/build.gradle`.

## iOS Compatibility {#ios}

### Current Settings

| Setting | Value | Notes |
|---------|-------|-------|
| Deployment target | iOS 16.0 | Set in capacitor.config.ts |
| Package manager | CocoaPods | SPM explicitly disabled |
| Xcode | 15+ required | For iOS 16 deployment target |
| Swift | 5.9+ | Bundled with Xcode 15 |

### CocoaPods Health

```bash
cd front/src-capacitor/ios/App

# Check Podfile.lock for version conflicts
cat Podfile.lock | grep -A1 "SPEC CHECKSUMS"

# Full dependency resolution
pod install --verbose

# Clear caches if things are weird
pod cache clean --all
rm -rf Pods Podfile.lock
pod install
```

### Common iOS Issues

1. **Swift version mismatch** — some pods require a minimum Swift version. Check with `pod spec cat <PodName> | grep swift_version`.
2. **Deployment target too low** — if a pod requires iOS 15+ but you target iOS 14, build will fail. Current target (16.0) is safe for most modern pods.
3. **Bitcode** — disabled since Xcode 14. Remove any `-fembed-bitcode` flags if present.
4. **SPM vs CocoaPods** — this project uses CocoaPods (`useSwiftPackageManager: false`). Don't mix — if a plugin only supports SPM, you'll need to add it manually or find a CocoaPods alternative.

## Full Audit Checklist {#full-audit}

Run through this when preparing for a major upgrade or troubleshooting build failures:

### Core Versions
- [ ] All `@capacitor/*` packages on same major version
- [ ] `@capacitor/cli` matches `@capacitor/core`
- [ ] Third-party Capacitor plugins declare compatible peer deps

### Android
- [ ] Java version matches AGP requirements (`java -version`)
- [ ] Gradle version matches AGP requirements (check wrapper properties)
- [ ] `compileSdk` >= `targetSdk`
- [ ] `targetSdk` meets Play Store minimum
- [ ] `google-services.json` present and matches Firebase project
- [ ] No duplicate class errors in dependency tree
- [ ] `gradle.properties` has correct AndroidX/Jetifier settings

### iOS
- [ ] Xcode version supports deployment target
- [ ] CocoaPods version is 1.14+ (`pod --version`)
- [ ] `Podfile.lock` is committed and up-to-date
- [ ] No pod version conflicts (`pod install` succeeds clean)
- [ ] Signing identity and provisioning profile are valid
- [ ] `google-services` / `GoogleService-Info.plist` matches Firebase project

### Cross-Platform
- [ ] `capacitor.config.ts` has correct `webDir` pointing to build output
- [ ] `npx cap doctor` shows no errors
- [ ] Both platforms build successfully after `cap sync`
- [ ] Hot reload connects on both platforms
