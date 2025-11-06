# UnitWise Flutter App

Module 1: Authentication & Onboarding

---

## 🚀 Quick Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit with your credentials
nano .env
```

### 3. Configure Firebase

**Android:**
1. Download `google-services.json` from Firebase Console
2. Place in `android/app/google-services.json`

**iOS:**
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place in `ios/Runner/GoogleService-Info.plist`

### 4. Run the App

```bash
# Run on connected device/emulator
flutter run

# Run with Firebase Emulator
flutter run --dart-define=USE_EMULATOR=true
```

---

## 📦 Dependencies

- **firebase_core**: Firebase initialization
- **firebase_auth**: Authentication
- **cloud_firestore**: Database
- **flutter_secure_storage**: Secure token storage
- **pinput**: OTP input UI
- **intl_phone_number_input**: Phone number formatting
- **dio**: HTTP client for backend API calls

---

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # MaterialApp configuration
├── env_config.dart              # Environment variable loader
├── theme/
│   ├── app_theme.dart           # Theme configuration
│   └── colors.dart              # Color constants
├── models/
│   └── user_model.dart          # User data model
├── services/
│   ├── auth_service.dart        # Firebase Auth wrapper
│   ├── local_storage.dart       # Secure storage
│   └── api_service.dart         # Backend API client
├── screens/
│   └── auth/
│       ├── splash_screen.dart
│       ├── welcome_screen.dart
│       ├── signup_screen.dart
│       ├── otp_verification_screen.dart
│       ├── password_setup_screen.dart
│       ├── login_screen.dart
│       ├── forgot_password_screen.dart
│       └── location_setup_screen.dart
└── utils/
    └── validators.dart          # Input validation
```

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/auth_service_test.dart
```

---

## 🔒 Security Notes

- Never commit `.env` file
- Never commit Firebase config files
- Store sensitive data in `flutter_secure_storage`
- Use Firebase Auth for session management
- Validate all inputs on both client and server

---

## 📱 Build Commands

### Android

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS

```bash
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release
```

---

## 🐛 Troubleshooting

### Issue: "pubspec.yaml has no lower-bound SDK constraint"

**Fix**: Ensure `pubspec.yaml` has:
```yaml
environment:
  sdk: '>=3.0.0 <4.0.0'
```

### Issue: "Firebase configuration not found"

**Fix**: 
1. Download config files from Firebase Console
2. Place in correct directories (see setup above)
3. Run `flutterfire configure`

### Issue: "Pod install failed" (iOS)

**Fix**:
```bash
cd ios
pod install --repo-update
cd ..
flutter run
```

---

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Flutter Setup](https://firebase.google.com/docs/flutter/setup)
- [UnitWise PRD](../docs/module1_onboarding_README.md)
