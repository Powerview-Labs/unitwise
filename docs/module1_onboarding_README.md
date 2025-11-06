# MODULE 1: AUTHENTICATION & ONBOARDING

## 📋 Overview

This module implements the complete user authentication and onboarding flow for UnitWise, including:

- **Phone-based authentication** with OTP verification (Twilio WhatsApp)
- **Secure password creation** and management
- **Location-based setup** (DisCo & Band auto-detection)
- **Welcome email automation** (SendGrid)
- **Auto-login persistence** using Firebase Auth
- **Password reset flow** with OTP verification

---

## 🏗️ Architecture

```
User → Flutter App → Firebase Auth → Cloud Functions → External APIs
                                    ↓
                                Firestore (secure data storage)
```

**Key Components:**
- **Frontend**: Flutter 3.x with Firebase SDK
- **Backend**: Firebase Cloud Functions (Node.js)
- **Authentication**: Firebase Authentication (phone + password)
- **OTP Delivery**: Twilio WhatsApp API (sandbox)
- **Email**: SendGrid API
- **Database**: Cloud Firestore with security rules

---

## 🔐 Security Principles

This module follows **security-first architecture**:

### ✅ Authentication Security
- Passwords hashed via Firebase Auth (never stored plaintext)
- OTP hashed with bcrypt before Firestore storage
- Timing-safe OTP comparison to prevent timing attacks
- Rate limiting on OTP endpoints (max 5 attempts per session)
- OTP expiry enforced (5 minutes)
- Single-use OTP tokens (deleted after verification)

### ✅ Data Protection
- All credentials stored in `.env` (never committed to git)
- Firebase Security Rules enforce uid-based access control
- No PII logged in Cloud Functions or console
- Phone numbers masked in logs (e.g., `+234810****000`)
- HTTPS-only communication with external APIs

### ✅ Session Management
- Firebase Auth persistence handles token lifecycle automatically
- "Remember Me" stored in FlutterSecureStorage (not SharedPreferences)
- No manual JWT/refresh token handling
- Auto-logout on token expiry
- Session validation on app startup

### ✅ Input Validation
- Server-side validation for all user inputs
- Phone number E.164 format enforcement
- Email format validation
- Password strength requirements (min 6 chars)
- Firestore schema validation

---

## 📦 Prerequisites

### Required Tools
- **Flutter SDK**: 3.19.0 or higher
- **Node.js**: 18.x or higher
- **Firebase CLI**: Latest version
- **Git**: For version control

### Required Accounts
- Firebase project (with Blaze plan for Cloud Functions)
- Twilio account (sandbox for WhatsApp OTP)
- SendGrid account (for transactional emails)

---

## ⚙️ Environment Setup

### Step 1: Clone Repository
```bash
git clone <repository-url>
cd unitwise
```

### Step 2: Install Dependencies

**Frontend (Flutter):**
```bash
cd frontend
flutter pub get
```

**Backend (Cloud Functions):**
```bash
cd backend/functions
npm install
```

### Step 3: Configure Environment Variables

1. Copy `.env.example` to `.env` in project root:
```bash
cp .env.example .env
```

2. Fill in actual credentials (see `.env.example` for required variables)

3. **CRITICAL**: Add `.env` to `.gitignore` immediately:
```bash
echo ".env" >> .gitignore
```

### Step 4: Firebase Configuration

1. Install Firebase CLI:
```bash
npm install -g firebase-tools
```

2. Login to Firebase:
```bash
firebase login
```

3. Initialize Firebase in project:
```bash
firebase init
```

Select:
- ✅ Firestore
- ✅ Functions
- ✅ Authentication
- ✅ Emulators (Auth, Firestore, Functions)

4. Deploy Firestore security rules:
```bash
firebase deploy --only firestore:rules
```

### Step 5: Configure Flutter Firebase

1. Add `google-services.json` (Android) to `frontend/android/app/`
2. Add `GoogleService-Info.plist` (iOS) to `frontend/ios/Runner/`
3. Configure `firebase_options.dart`:
```bash
cd frontend
flutterfire configure
```

---

## 🧪 Local Development with Firebase Emulator

### Start Emulator Suite
```bash
cd backend/functions
firebase emulators:start
```

This starts:
- **Authentication Emulator**: `http://localhost:9099`
- **Firestore Emulator**: `http://localhost:8080`
- **Functions Emulator**: `http://localhost:5001`

### Connect Flutter App to Emulator

In `frontend/lib/main.dart`, add:
```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // ONLY for local development
  if (kDebugMode) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
  
  runApp(MyApp());
}
```

---

## 🔌 API Endpoints

### 1. **Send OTP** (`/sendOtp`)

**Purpose**: Generate and send OTP via Twilio WhatsApp

**Method**: POST  
**URL**: `https://<region>-<project>.cloudfunctions.net/sendOtp`

**Request Body**:
```json
{
  "phone": "+2348100000000",
  "name": "Ifeanyi",
  "email": "ifeanyi@email.com"
}
```

**Response (Success)**:
```json
{
  "success": true,
  "sessionId": "otp_sess_abc123xyz",
  "messageSid": "SMxxxxxxxxxxxxxxxx",
  "message": "OTP sent via WhatsApp"
}
```

**Response (Error)**:
```json
{
  "success": false,
  "code": "RATE_LIMIT_EXCEEDED",
  "message": "Too many OTP requests. Please wait 5 minutes."
}
```

**Security Notes**:
- Rate limited to 3 requests per phone per 15 minutes
- OTP never returned in response (only sent via WhatsApp)
- Session ID used for verification (not the OTP itself)

**cURL Example**:
```bash
curl -X POST https://<region>-<project>.cloudfunctions.net/sendOtp \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+2348100000000",
    "name": "Ifeanyi"
  }'
```

---

### 2. **Verify OTP** (`/verifyOtp`)

**Purpose**: Verify user-submitted OTP and create/authenticate user

**Method**: POST  
**URL**: `https://<region>-<project>.cloudfunctions.net/verifyOtp`

**Request Body**:
```json
{
  "sessionId": "otp_sess_abc123xyz",
  "otp": "123456",
  "phone": "+2348100000000"
}
```

**Response (Success - New User)**:
```json
{
  "success": true,
  "newUser": true,
  "uid": "firebase_uid_123",
  "customToken": "firebase_custom_token_xyz",
  "message": "OTP verified. Please create a password."
}
```

**Response (Success - Existing User)**:
```json
{
  "success": true,
  "newUser": false,
  "uid": "firebase_uid_123",
  "message": "OTP verified. User authenticated."
}
```

**Response (Error)**:
```json
{
  "success": false,
  "code": "INVALID_OTP",
  "message": "Incorrect OTP. 2 attempts remaining.",
  "attemptsRemaining": 2
}
```

**Error Codes**:
- `INVALID_OTP`: Wrong OTP entered
- `EXPIRED_OTP`: OTP expired (>5 minutes)
- `MAX_ATTEMPTS_EXCEEDED`: Too many failed attempts (blocked)
- `SESSION_NOT_FOUND`: Invalid session ID

**Security Notes**:
- Bcrypt timing-safe comparison prevents timing attacks
- Max 5 attempts per session before lockout
- Session deleted after successful verification
- Attempts counter incremented on each failure

---

### 3. **Create User Profile** (`/createUserProfile`)

**Purpose**: Create complete user profile in Firestore after password setup

**Method**: POST  
**URL**: `https://<region>-<project>.cloudfunctions.net/createUserProfile`

**Request Body**:
```json
{
  "uid": "firebase_uid_123",
  "name": "Ifeanyi Okafor",
  "email": "ifeanyi@email.com",
  "phone": "+2348100000000",
  "disco": "Ikeja Electric",
  "band": "C",
  "location": "Yaba, Lagos"
}
```

**Response (Success)**:
```json
{
  "success": true,
  "message": "User profile created successfully",
  "welcomeEmailSent": true
}
```

**Security Notes**:
- Server-side validation of all fields
- Duplicate phone number check
- Welcome email triggered automatically
- Firestore security rules enforce uid-based access

---

### 4. **Reset Password** (`/resetPassword`)

**Purpose**: Initiate password reset with OTP verification

**Method**: POST  
**URL**: `https://<region>-<project>.cloudfunctions.net/resetPassword`

**Request Body (Step 1 - Request OTP)**:
```json
{
  "phone": "+2348100000000",
  "action": "request_otp"
}
```

**Request Body (Step 2 - Verify and Reset)**:
```json
{
  "sessionId": "otp_sess_abc123xyz",
  "otp": "123456",
  "phone": "+2348100000000",
  "newPassword": "newSecurePassword123",
  "action": "reset_password"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Password reset successfully"
}
```

---

## 📊 Firestore Data Schema

### Collection: `users`

**Document ID**: Firebase UID (string)

**Fields**:
```typescript
{
  uid: string,              // Firebase Authentication UID
  name: string,             // User's preferred name
  email: string,            // Email for communications (optional)
  phone: string,            // E.164 formatted phone number (unique)
  disco: string,            // Distribution Company (e.g., "Ikeja Electric")
  band: string,             // Tariff Band (A, B, C, D, E)
  location: string,         // User's area/estate
  meter_number: string?,    // Optional meter number
  theme: string,            // "light" or "dark"
  created_at: Timestamp,    // Account creation timestamp
  last_login: Timestamp,    // Last successful login
  remember_me: boolean      // Auto-login preference
}
```

**Security Rules**:
- Read/Write: Only authenticated user with matching UID
- Phone number indexed for uniqueness check
- No public access

---

### Collection: `otp_sessions`

**Document ID**: Auto-generated session ID (string)

**Fields**:
```typescript
{
  phone: string,            // E.164 formatted phone number
  otpHash: string,          // bcrypt hash of the OTP
  createdAt: Timestamp,     // Session creation time
  expiresAt: Timestamp,     // Expiry time (createdAt + 5 minutes)
  attempts: number,         // Failed verification attempts (max 5)
  messageSid: string,       // Twilio message SID for traceability
  source: string,           // "whatsapp" or "sms"
  used: boolean             // True after successful verification
}
```

**Security Rules**:
- Write: Backend only (via Cloud Functions)
- Read: Backend only (no client access)
- Auto-delete after 24 hours (TTL policy)

---

## 🧪 Testing Guide

### Unit Tests (Backend)

Run backend function tests:
```bash
cd backend/functions
npm test
```

Test coverage includes:
- OTP generation (crypto-secure randomness)
- Bcrypt hashing and verification
- OTP expiry logic
- Rate limiting enforcement
- User profile creation validation

### Integration Tests

Test complete auth flow:
```bash
cd backend/functions
npm run test:integration
```

Scenarios tested:
1. New user signup → OTP → password → profile creation
2. Existing user login → OTP verification
3. Password reset flow
4. Rate limiting and expiry handling
5. Error cases (invalid OTP, expired session, etc.)

### Widget Tests (Frontend)

Run Flutter widget tests:
```bash
cd frontend
flutter test
```

Test coverage includes:
- OTP input field validation
- Resend timer countdown
- Password strength indicator
- Form validation and error states
- Navigation flows

### Manual Testing Checklist

#### Signup Flow
- [ ] Enter phone number → Receives WhatsApp OTP
- [ ] Submit correct OTP → Proceeds to password setup
- [ ] Submit incorrect OTP → Shows error, allows retry
- [ ] Wait >5 minutes → OTP expires, must resend
- [ ] Submit weak password → Shows strength warning
- [ ] Complete location setup → Profile created
- [ ] Welcome email received at provided email address

#### Login Flow
- [ ] Enter correct credentials → Redirects to dashboard
- [ ] Enter incorrect password → Shows error
- [ ] Enable "Remember Me" → Auto-login on next app open
- [ ] Disable "Remember Me" → Must re-login

#### Password Reset Flow
- [ ] Request OTP → Receives WhatsApp message
- [ ] Verify OTP → Allowed to set new password
- [ ] Login with new password → Success

#### Edge Cases
- [ ] Internet disconnects mid-signup → Shows retry option
- [ ] App crashes during OTP entry → Session recoverable
- [ ] Try to create account with existing phone → Error message
- [ ] Exceed 5 OTP attempts → Account temporarily locked

---

## 🐛 Troubleshooting

### Issue: "OTP not received"

**Possible Causes**:
1. Phone number not joined to Twilio sandbox
2. Twilio ContentSID misconfigured
3. Network/firewall blocking Twilio requests

**Solution**:
1. Verify phone joined sandbox: Send "join <sandbox-code>" to Twilio number
2. Check Cloud Functions logs: `firebase functions:log`
3. Test Twilio API directly with cURL:
```bash
curl -X POST "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID/Messages.json" \
  --data-urlencode "To=whatsapp:+2348100000000" \
  --data-urlencode "From=$TWILIO_WHATSAPP_NUMBER" \
  --data-urlencode "ContentSid=$TWILIO_CONTENT_SID" \
  --data-urlencode "ContentVariables={\"1\":\"123456\"}" \
  -u $TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN
```

---

### Issue: "Firebase Auth Error: User not found"

**Possible Causes**:
1. User account not created properly
2. Firebase Auth and Firestore out of sync

**Solution**:
1. Check Firestore for user document
2. Verify Firebase Auth user exists in console
3. Re-run createUserProfile function manually

---

### Issue: "Firestore permission denied"

**Possible Causes**:
1. Security rules not deployed
2. User not authenticated
3. Trying to access another user's data

**Solution**:
1. Deploy rules: `firebase deploy --only firestore:rules`
2. Check authentication status in app
3. Verify UID matches document ID

---

## 📝 Commit Convention

Follow this pattern for all commits in Module 1:

```
<type>(scope): <description>

[optional body]
[optional footer]
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Adding/updating tests
- `refactor`: Code refactoring
- `style`: Formatting changes
- `chore`: Build/config changes

**Examples**:
```
feat(auth): add sendOtp cloud function with Twilio integration

- Generate crypto-secure 6-digit OTP
- Hash with bcrypt before Firestore storage
- Send via Twilio WhatsApp ContentSID template
- Implement rate limiting (3 requests per 15min)
- Add comprehensive error handling

Closes #12
```

```
fix(auth): prevent timing attack in OTP verification

- Replace string comparison with bcrypt.compare()
- Ensures constant-time comparison
- Mitigates timing-based OTP guessing

Security fix for OWASP A07:2021
```

```
test(auth): add integration tests for complete signup flow

- New user signup → OTP → password → profile
- Edge cases: expired OTP, max attempts, rate limiting
- Mock Twilio and SendGrid API calls
```

---

## 🚀 Deployment

### Deploy to Firebase

**Deploy Functions**:
```bash
cd backend/functions
firebase deploy --only functions
```

**Deploy Firestore Rules**:
```bash
firebase deploy --only firestore:rules
```

**Deploy All**:
```bash
firebase deploy
```

### Flutter App Deployment

**Android**:
```bash
cd frontend
flutter build apk --release
```

**iOS**:
```bash
cd frontend
flutter build ios --release
```

---

## 🎯 Acceptance Criteria

Module 1 is complete when all criteria are met:

### Authentication Flow
- [x] New users can sign up with phone + email + name
- [x] OTP sent via Twilio WhatsApp (sandbox)
- [x] OTP verification works with bcrypt hashing
- [x] Password creation enforced after OTP verification
- [x] Login works with phone + password
- [x] "Remember Me" persists session securely
- [x] Forgot password flow uses OTP verification

### Location Setup
- [x] Location screen suggests DisCo & Band based on area
- [x] Manual override allowed for DisCo & Band
- [x] User profile saved to Firestore with all required fields

### Email & Notifications
- [x] Welcome email sent automatically after signup
- [x] Email template uses dynamic placeholders
- [x] No PII logged in email operations

### Security
- [x] All credentials in environment variables
- [x] Passwords never stored in plaintext
- [x] OTP hashed with bcrypt in Firestore
- [x] Rate limiting prevents brute force attacks
- [x] Firestore security rules enforce uid-based access
- [x] No tokens stored in insecure local storage
- [x] Auto-login uses Firebase Auth persistence

### Testing
- [x] Unit tests for OTP generation & verification
- [x] Integration tests for complete signup flow
- [x] Widget tests for OTP input & validation
- [x] Manual QA completed for all user flows

### Documentation
- [x] README with setup instructions
- [x] API documentation with examples
- [x] Testing guide with manual checklist
- [x] Troubleshooting section

---

## 📞 Support

**Technical Issues**: Open an issue on GitHub  
**Security Concerns**: Email security@unitwise.app  
**General Questions**: Contact dev@unitwise.app

---

## 📚 Additional Resources

- [Firebase Authentication Docs](https://firebase.google.com/docs/auth)
- [Twilio WhatsApp API](https://www.twilio.com/docs/whatsapp)
- [SendGrid API Docs](https://docs.sendgrid.com/)
- [Flutter Security Best Practices](https://flutter.dev/docs/deployment/security)
- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)

---

**Document Version**: 1.0  
**Last Updated**: November 2025  
**Maintained By**: PowerView Labs Development Team
