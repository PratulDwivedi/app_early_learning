#!/bin/bash
# Quick setup script for Android app signing
# Run: bash setup_keystore.sh

set -e

echo "================================"
echo "App Early Learning - Keystore Setup"
echo "================================"
echo ""

# Create keystore directory
mkdir -p android/keystore

# Check if keystore already exists
if [ -f "android/keystore/app_early_learning.jks" ]; then
    echo "⚠️  Keystore file already exists!"
    read -p "Do you want to create a new one? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping keystore creation."
        exit 0
    fi
fi

echo "📝 Please enter the following information:"
echo ""

read -p "Keystore password (strong password recommended): " -s KEYSTORE_PASS
echo
read -p "Confirm keystore password: " -s KEYSTORE_PASS_CONFIRM
echo

if [ "$KEYSTORE_PASS" != "$KEYSTORE_PASS_CONFIRM" ]; then
    echo "❌ Passwords don't match!"
    exit 1
fi

read -p "Key password (can be same as keystore password): " -s KEY_PASS
echo ""

read -p "Your name: " USER_NAME
read -p "Organization unit (e.g., App Development): " ORG_UNIT
read -p "Organization name (e.g., Your Company): " ORG_NAME
read -p "City: " CITY
read -p "State/Province: " STATE
read -p "Country code (e.g., US): " COUNTRY

echo ""
echo "🔐 Generating keystore..."
echo ""

# Generate keystore
keytool -genkey -v -keystore android/keystore/app_early_learning.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias app_early_learning_key \
  -dname "CN=$USER_NAME, OU=$ORG_UNIT, O=$ORG_NAME, L=$CITY, ST=$STATE, C=$COUNTRY" \
  -storepass "$KEYSTORE_PASS" \
  -keypass "$KEY_PASS"

echo ""
echo "✅ Keystore created successfully!"
echo ""
echo "📝 Creating key.properties file..."

# Create key.properties
cat > android/key.properties << EOF
# Keystore configuration for production build
# IMPORTANT: Never commit this file to version control!
# Added to .gitignore for safety

storeFile=keystore/app_early_learning.jks
storePassword=$KEYSTORE_PASS
keyAlias=app_early_learning_key
keyPassword=$KEY_PASS
EOF

echo ""
echo "✅ key.properties created successfully!"
echo ""
echo "📦 Ready to build for production:"
echo ""
echo "  1. APK: flutter build apk --release"
echo "  2. AAB: flutter build appbundle --release"
echo ""
echo "🔍 Verify signing with:"
echo "  jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "⚠️  SECURITY REMINDERS:"
echo "  • Keep android/key.properties and android/keystore/ directory private"
echo "  • Make secure backups of the .jks file"
echo "  • Never commit signing files to version control"
echo ""
