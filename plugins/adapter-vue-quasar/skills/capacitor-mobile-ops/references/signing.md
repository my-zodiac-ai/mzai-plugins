# App Signing — My Zodiac AI

## Table of Contents
1. [Current State](#current-state)
2. [Android Signing](#android-signing)
3. [iOS Signing](#ios-signing)
4. [Migration to Env-Based Secrets](#migration)
5. [GitHub Actions Secrets](#github-actions-secrets)

---

## Current State

**Android** signing is configured in `front/src-capacitor/android/app/build.gradle`:

```groovy
signingConfigs {
    debug {
        storeFile file('debug.keystore')
        storePassword 'android'
        keyAlias 'androiddebugkey'
        keyPassword 'android'
    }
    release {
        storeFile file('upload-key.keystore')
        storePassword '40602092'      // ⚠️ HARDCODED — migrate to env
        keyAlias 'upload'
        keyPassword '40602092'        // ⚠️ HARDCODED — migrate to env
    }
}
```

**iOS** uses Xcode's automatic signing with a team configured in the project settings.

## Android Signing

### Keystore Files

- `debug.keystore` — default Android debug key, no security concern
- `upload-key.keystore` — Play Store upload key, MUST be kept secure

The upload keystore lives at `front/src-capacitor/android/app/upload-key.keystore`. It should NOT be committed to git (add to `.gitignore` if not already there). For CI/CD, store it as a base64-encoded GitHub secret.

### Product Flavors

The project uses two flavors defined in `build.gradle`:

| Flavor | App ID Suffix | App Name | Use Case |
|--------|--------------|----------|----------|
| `dev` | `.debug` | My Zodiac AI DEV | Development, can coexist with prod |
| `prod` | (none) | My Zodiac AI | Production, Play Store |

Build variants are: `devDebug`, `devRelease`, `prodDebug`, `prodRelease`. For Play Store, use `prodRelease`.

## iOS Signing

### Automatic Signing (Local Dev)

Xcode handles provisioning profiles automatically when a team is selected:
1. Open `front/src-capacitor/ios/App/App.xcodeproj`
2. Select the "App" target → Signing & Capabilities
3. Enable "Automatically manage signing"
4. Select your Apple Developer team

### Manual Signing (CI/CD)

For CI/CD, you need:
- **Certificate** (.p12) — Apple Distribution certificate exported from Keychain
- **Provisioning Profile** (.mobileprovision) — App Store distribution profile from Apple Developer portal
- **Export Options Plist** — defines distribution method

Store these as base64-encoded GitHub secrets.

## Migration to Env-Based Secrets {#migration}

### Step 1: Update build.gradle

Replace hardcoded values with environment variable reads:

```groovy
signingConfigs {
    release {
        storeFile file(System.getenv('ANDROID_KEYSTORE_PATH') ?: 'upload-key.keystore')
        storePassword System.getenv('ANDROID_KEYSTORE_PASSWORD') ?: ''
        keyAlias System.getenv('ANDROID_KEY_ALIAS') ?: 'upload'
        keyPassword System.getenv('ANDROID_KEY_PASSWORD') ?: ''
    }
}
```

### Step 2: Create local .env for Android

Create `front/src-capacitor/android/signing.properties` (gitignored):

```properties
ANDROID_KEYSTORE_PATH=upload-key.keystore
ANDROID_KEYSTORE_PASSWORD=40602092
ANDROID_KEY_ALIAS=upload
ANDROID_KEY_PASSWORD=40602092
```

Then load it in `build.gradle`:

```groovy
def signingProps = new Properties()
def signingPropsFile = file('signing.properties')
if (signingPropsFile.exists()) {
    signingProps.load(new FileInputStream(signingPropsFile))
}

signingConfigs {
    release {
        storeFile file(signingProps['ANDROID_KEYSTORE_PATH'] ?: System.getenv('ANDROID_KEYSTORE_PATH') ?: 'upload-key.keystore')
        storePassword signingProps['ANDROID_KEYSTORE_PASSWORD'] ?: System.getenv('ANDROID_KEYSTORE_PASSWORD') ?: ''
        keyAlias signingProps['ANDROID_KEY_ALIAS'] ?: System.getenv('ANDROID_KEY_ALIAS') ?: 'upload'
        keyPassword signingProps['ANDROID_KEY_PASSWORD'] ?: System.getenv('ANDROID_KEY_PASSWORD') ?: ''
    }
}
```

### Step 3: Update .gitignore

```
# Android signing
front/src-capacitor/android/app/upload-key.keystore
front/src-capacitor/android/app/signing.properties
```

## GitHub Actions Secrets

For CI/CD, set these repository secrets:

| Secret | Description | How to Get |
|--------|-------------|-----------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded upload-key.keystore | `base64 -i upload-key.keystore` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password | From signing.properties |
| `ANDROID_KEY_ALIAS` | Key alias | Usually "upload" |
| `ANDROID_KEY_PASSWORD` | Key password | From signing.properties |
| `IOS_CERTIFICATE_BASE64` | Base64-encoded .p12 certificate | Export from Keychain Access |
| `IOS_CERTIFICATE_PASSWORD` | .p12 export password | Set during export |
| `IOS_PROVISION_PROFILE_BASE64` | Base64-encoded .mobileprovision | Download from Apple Developer |
| `APPLE_ID` | Apple Developer email | Your Apple ID |
| `APP_SPECIFIC_PASSWORD` | App-specific password for notarization | appleid.apple.com → Security |
