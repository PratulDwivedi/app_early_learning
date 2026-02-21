# Android Signing Quick Start

## TL;DR - Get Release Build in 2 Minutes

### Option 1: Automated Script (Recommended)
```bash
chmod +x setup_keystore.sh
./setup_keystore.sh
flutter build apk --release
```

### Option 2: Manual Steps
```bash
# 1. Generate keystore (interactive)
mkdir -p android/keystore
keytool -genkey -v -keystore android/keystore/app_early_learning.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias app_early_learning_key

# 2. Create key.properties (fill in the values from keytool)
cp android/key.properties.example android/key.properties
# Open and edit with your keystore credentials

# 3. Build release APK
flutter build apk --release
```

## Build Outputs

- **APK**: `build/app/outputs/flutter-apk/app-release.apk` (64-bit + 32-bit splits)
- **AAB**: `build/app/outputs/bundle/release/app-release.aab` (Google Play)

## Verify Signing
```bash
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

## Security Checklist
- ✅ android/key.properties in .gitignore
- ✅ android/keystore/ in .gitignore
- ✅ Never commit .jks files
- ✅ Backup keystore file in secure location
- ✅ Only one key per app (for Google Play consistency)

## Troubleshooting

**"keytool: command not found"**
- Java is not installed. Install JDK 8+

**"key.properties not found"**
- Run setup script or create manually with correct credentials

**"Unsigned APK"**
- Ensure key.properties path is correct relative to android/ folder
- Check signingConfig in build.gradle.kts

## For Detailed Info
See [ANDROID_SIGNING_GUIDE.md](ANDROID_SIGNING_GUIDE.md)
