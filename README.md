# App Early Learning

An interactive Flutter-based early learning platform for students featuring student management, quiz evaluations, and text-to-speech accessibility features.

## Quick Start

```bash
# Development build
flutter run

# Production APK build
flutter build apk --release

# Production AAB (Google Play)
flutter build appbundle --release
```

## Production Build (Android Signing)

See [QUICK_START_SIGNING.md](QUICK_START_SIGNING.md) for 2-minute setup.

For detailed setup guide: [ANDROID_SIGNING_GUIDE.md](ANDROID_SIGNING_GUIDE.md)

**Quick steps:**
1. Run: `chmod +x setup_keystore.sh && ./setup_keystore.sh`
2. Build: `flutter build apk --release`

---

# Technical Documentation




## EDU Schema setting in Supabase

-- 1. Grant schema usage
GRANT USAGE ON SCHEMA edu TO anon, authenticated;

-- 2. Grant execute on all existing functions in edu
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA edu TO anon, authenticated;

-- 3. Grant execute on future functions automatically
ALTER DEFAULT PRIVILEGES IN SCHEMA edu
    GRANT EXECUTE ON FUNCTIONS TO anon, authenticated;

-- 4. If your functions also SELECT from edu tables directly
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA edu TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA edu
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;