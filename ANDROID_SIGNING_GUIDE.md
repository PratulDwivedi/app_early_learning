# Android App Signing Setup Guide

## 📋 Overview
This guide explains how to set up app signing for production builds of the Early Learning App.

---

## 🔐 Step 1: Generate the Keystore File (JKS)

### Using keytool (Recommended)

Run this command in your terminal to generate a keystore:

```bash
keytool -genkey -v -keystore android/keystore/app_early_learning.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias app_early_learning_key
```

**What this command does:**
- `-genkey`: Generates a new key
- `-v`: Verbose output
- `-keystore`: Path where the keystore will be saved
- `-keyalg RSA`: Uses RSA algorithm
- `-keysize 2048`: 2048-bit key size (secure)
- `-validity 10000`: Certificate valid for ~27 years
- `-alias`: Unique name for this key

### When prompted, enter:

```
Enter keystore password: (create a strong password)
Re-enter new password: (confirm password)
What is your first and last name?
  [Unknown]: Your Name
What is the name of your organizational unit?
  [Unknown]: App Development
What is the name of your organization?
  [Unknown]: Your Company
What is the name of your City or Locality?
  [Unknown]: City Name
What is the name of your State or Province?
  [Unknown]: State/Province
What is the two-letter country code for this unit?
  [Unknown]: US
Is CN=Your Name, OU=App Development, O=Your Company, L=City Name, ST=State/Province, C=US correct?
  [no]: yes
Enter key password for <app_early_learning_key>: (can be same as keystore password)
```

---

## 📝 Step 2: Configure key.properties

1. Copy the example file:
```bash
cp android/key.properties.example android/key.properties
```

2. Edit `android/key.properties` and add your credentials:
```properties
storeFile=keystore/app_early_learning.jks
storePassword=your_keystore_password_from_step1
keyAlias=app_early_learning_key
keyPassword=your_key_password_from_step1
```

### ⚠️ IMPORTANT: SECURITY

- **Never commit `key.properties` to version control** (already in .gitignore)
- **Never commit the `.jks` file** to version control (already in .gitignore)
- Store passwords securely (consider using a password manager)
- Keep backups of your keystore file in a secure location

---

## 🏗️ Step 3: Build for Production

### Option 1: Release APK
```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Option 2: Release AAB (Google Play)
```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Option 3: Signed APK with Custom Configuration
```bash
flutter build apk --release -v
```

---

## 🔍 Verify Signing

To verify your APK is properly signed:

```bash
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

---

## 📱 Deployment to Google Play

### Prerequisites:
1. Google Play Developer Account
2. Signed release APK or AAB

### Steps:
1. Upload AAB or APK to Google Play Console
2. Set app details (description, screenshots, etc.)
3. Submit for review
4. Once approved, publish to production

---

## 🔑 Managing Multiple Keystores

For different environments (dev, staging, prod):

```bash
# Dev keystore
keytool -genkey -v -keystore android/keystore/app_early_learning_dev.jks ...

# Staging keystore
keytool -genkey -v -keystore android/keystore/app_early_learning_staging.jks ...

# Production keystore (already created)
keytool -genkey -v -keystore android/keystore/app_early_learning.jks ...
```

Then, switch between them by updating `key.properties`.

---

## 🚨 Troubleshooting

### "Keystore file not found"
- Ensure the path in `key.properties` is relative to the `android/` directory
- Create `android/keystore/` directory if it doesn't exist

### "Invalid password"
- Verify passwords in `key.properties` match what you set
- Note: Keystore password and key password might be different

### "jarsigner not found"
- Ensure Java is installed: `java -version`
- Add Java bin to PATH if needed

### Changes not taking effect
```bash
flutter clean
flutter pub get
flutter build apk --release
```

---

## 📚 Additional Resources

- [Flutter Release Documentation](https://flutter.dev/docs/deployment/android)
- [Android App Signing Documentation](https://developer.android.com/studio/publish/app-signing)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)

---

## ✅ Checklist

- [ ] Keystore file created (`android/keystore/app_early_learning.jks`)
- [ ] `key.properties` file created with correct path and passwords
- [ ] `key.properties` added to `.gitignore` (verified)
- [ ] `android/keystore/` added to `.gitignore` (verified)
- [ ] build.gradle.kts updated with signing config (done)
- [ ] Test build succeeds: `flutter build apk --release`
- [ ] Verified signing with jarsigner
- [ ] Backed up keystore file securely
- [ ] Backed up key.properties securely

---

## 🔐 Key Security Notes

1. **Never share your keystore file** - It's your app's signature
2. **Never commit key.properties** - It contains sensitive passwords
3. **Keep multiple backups** - Store in secure locations (e.g., encrypted cloud storage)
4. **Use strong passwords** - Use a mix of upper/lowercase, numbers, symbols
5. **Store backup passwords** - Use a password manager like 1Password, LastPass
6. **Log all keystore operations** - Keep records of when/where keystores were created

---

**Last Updated:** February 21, 2026  
**App:** Early Learning App  
**Android Version:** Supports API 21+
