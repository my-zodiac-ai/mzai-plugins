# CI/CD for Mobile Builds — My Zodiac AI

## Table of Contents
1. [Android Debug APK (PR Check)](#android-debug)
2. [Android Release AAB (Tag)](#android-release)
3. [iOS TestFlight Upload](#ios-testflight)
4. [Firebase App Distribution](#firebase-distribution)
5. [Secrets Setup](#secrets-setup)

---

## Android Debug APK (PR Check) {#android-debug}

Builds a debug APK on every PR to catch build breakage early.

```yaml
# .github/workflows/android-debug.yml
name: Android Debug Build

on:
  pull_request:
    paths:
      - 'front/**'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 22

      - uses: pnpm/action-setup@v4
        with:
          version: 9

      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Install dependencies
        run: |
          pnpm --dir front install
          pnpm --dir front/src-capacitor install

      - name: Build web assets
        run: pnpm --dir front build
        env:
          BUILD_ENV: dev

      - name: Sync Capacitor
        run: cd front/src-capacitor && npx cap sync android

      - name: Build debug APK
        run: |
          cd front/src-capacitor/android
          ./gradlew assembleDevDebug

      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: debug-apk
          path: front/src-capacitor/android/app/build/outputs/apk/dev/debug/*.apk
```

## Android Release AAB (Tag) {#android-release}

Builds a signed release AAB when a version tag is pushed. The AAB can be uploaded to Play Store.

```yaml
# .github/workflows/android-release.yml
name: Android Release Build

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 22

      - uses: pnpm/action-setup@v4
        with:
          version: 9

      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Install dependencies
        run: |
          pnpm --dir front install
          pnpm --dir front/src-capacitor install

      - name: Build web assets
        run: pnpm --dir front build

      - name: Sync Capacitor
        run: cd front/src-capacitor && npx cap sync android

      - name: Decode keystore
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > front/src-capacitor/android/app/upload-key.keystore

      - name: Build release AAB
        run: |
          cd front/src-capacitor/android
          ./gradlew bundleProdRelease
        env:
          ANDROID_KEYSTORE_PASSWORD: ${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
          ANDROID_KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
          ANDROID_KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}

      - name: Upload AAB artifact
        uses: actions/upload-artifact@v4
        with:
          name: release-aab
          path: front/src-capacitor/android/app/build/outputs/bundle/prodRelease/*.aab
```

## iOS TestFlight Upload {#ios-testflight}

Builds and uploads to TestFlight on tag push. Requires macOS runner.

```yaml
# .github/workflows/ios-testflight.yml
name: iOS TestFlight

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 22

      - uses: pnpm/action-setup@v4
        with:
          version: 9

      - name: Install dependencies
        run: |
          pnpm --dir front install
          pnpm --dir front/src-capacitor install

      - name: Build web assets
        run: pnpm --dir front build

      - name: Sync Capacitor
        run: cd front/src-capacitor && npx cap sync ios

      - name: Install CocoaPods
        run: |
          cd front/src-capacitor/ios/App
          pod install

      - name: Install Apple certificate and profile
        env:
          IOS_CERTIFICATE_BASE64: ${{ secrets.IOS_CERTIFICATE_BASE64 }}
          IOS_CERTIFICATE_PASSWORD: ${{ secrets.IOS_CERTIFICATE_PASSWORD }}
          IOS_PROVISION_PROFILE_BASE64: ${{ secrets.IOS_PROVISION_PROFILE_BASE64 }}
        run: |
          # Create temp keychain
          KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db
          security create-keychain -p "" $KEYCHAIN_PATH
          security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
          security unlock-keychain -p "" $KEYCHAIN_PATH

          # Import certificate
          CERT_PATH=$RUNNER_TEMP/certificate.p12
          echo "$IOS_CERTIFICATE_BASE64" | base64 --decode > $CERT_PATH
          security import $CERT_PATH -P "$IOS_CERTIFICATE_PASSWORD" \
            -A -t cert -f pkcs12 -k $KEYCHAIN_PATH
          security list-keychain -d user -s $KEYCHAIN_PATH

          # Install provisioning profile
          PROFILE_PATH=$RUNNER_TEMP/profile.mobileprovision
          echo "$IOS_PROVISION_PROFILE_BASE64" | base64 --decode > $PROFILE_PATH
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          cp $PROFILE_PATH ~/Library/MobileDevice/Provisioning\ Profiles/

      - name: Build and archive
        run: |
          cd front/src-capacitor/ios/App
          xcodebuild archive \
            -workspace App.xcworkspace \
            -scheme App \
            -configuration Release \
            -archivePath $RUNNER_TEMP/App.xcarchive \
            -allowProvisioningUpdates \
            CODE_SIGN_STYLE=Manual

      - name: Export IPA
        run: |
          xcodebuild -exportArchive \
            -archivePath $RUNNER_TEMP/App.xcarchive \
            -exportPath $RUNNER_TEMP/export \
            -exportOptionsPlist front/src-capacitor/ios/ExportOptions.plist

      - name: Upload to TestFlight
        env:
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APP_SPECIFIC_PASSWORD: ${{ secrets.APP_SPECIFIC_PASSWORD }}
        run: |
          xcrun altool --upload-app \
            -f $RUNNER_TEMP/export/*.ipa \
            -u "$APPLE_ID" \
            -p "$APP_SPECIFIC_PASSWORD" \
            --type ios

      - name: Upload IPA artifact
        uses: actions/upload-artifact@v4
        with:
          name: ios-ipa
          path: ${{ runner.temp }}/export/*.ipa
```

## Firebase App Distribution {#firebase-distribution}

For beta testing before store submission. Works for both platforms.

```yaml
# Add after the APK/IPA build step in any workflow:

      - name: Upload to Firebase App Distribution
        uses: wzieba/Firebase-Distribution-Github-Action@v1
        with:
          appId: ${{ secrets.FIREBASE_APP_ID_ANDROID }}  # or IOS
          serviceCredentialsFileContent: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          groups: beta-testers
          file: path/to/app.apk  # or .ipa
          releaseNotes: |
            Build ${{ github.ref_name }}
            Commit: ${{ github.sha }}
```

## Secrets Setup {#secrets-setup}

All required GitHub repository secrets:

### Android
| Secret | How to Generate |
|--------|----------------|
| `ANDROID_KEYSTORE_BASE64` | `base64 -i front/src-capacitor/android/app/upload-key.keystore \| pbcopy` |
| `ANDROID_KEYSTORE_PASSWORD` | From `signing.properties` |
| `ANDROID_KEY_ALIAS` | Usually `upload` |
| `ANDROID_KEY_PASSWORD` | From `signing.properties` |

### iOS
| Secret | How to Generate |
|--------|----------------|
| `IOS_CERTIFICATE_BASE64` | Export .p12 from Keychain Access, then `base64 -i cert.p12` |
| `IOS_CERTIFICATE_PASSWORD` | Password set during .p12 export |
| `IOS_PROVISION_PROFILE_BASE64` | Download from Apple Developer, then `base64 -i profile.mobileprovision` |
| `APPLE_ID` | Your Apple Developer account email |
| `APP_SPECIFIC_PASSWORD` | Generate at appleid.apple.com → Security → App-Specific Passwords |

### Firebase (Optional)
| Secret | How to Generate |
|--------|----------------|
| `FIREBASE_APP_ID_ANDROID` | Firebase Console → Project Settings → Your Android App |
| `FIREBASE_APP_ID_IOS` | Firebase Console → Project Settings → Your iOS App |
| `FIREBASE_SERVICE_ACCOUNT` | Firebase Console → Service Accounts → Generate new private key |
