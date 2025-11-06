# 🚀 UNITWISE - QUICK START GUIDE

## Module 1: Authentication & Onboarding

Get your development environment running in **under 10 minutes**.

---

## ⚡ Prerequisites

Install these before starting:

```bash
# Check versions
flutter --version  # Need 3.19.0+
node --version     # Need 18.x+
firebase --version # Need latest
```

Don't have them? Install:
- **Flutter**: https://docs.flutter.dev/get-started/install
- **Node.js**: https://nodejs.org/
- **Firebase CLI**: `npm install -g firebase-tools`

---

## 📦 Step 1: Clone & Install (2 minutes)

```bash
# Clone repository
git clone <repo-url>
cd unitwise

# Install Flutter dependencies
cd frontend
flutter pub get
cd ..

# Install Node dependencies
cd backend/functions
npm install
cd ../..
```

---

## 🔐 Step 2: Configure Environment (3 minutes)

```bash
# Create environment file
cp .env.example .env

# Edit .env with your credentials
nano .env  # or use your preferred editor
```

**Required Credentials:**
1. **Firebase**: Get from [Firebase Console](https://console.firebase.google.com/)
2. **Twilio**: Get from [Twilio Console](https://console.twilio.com/)
3. **SendGrid**: Get from [SendGrid Dashboard](https://app.sendgrid.com/)

---

## 🔥 Step 3: Initialize Firebase (2 minutes)

```bash
# Login to Firebase
firebase login

# Initialize project
firebase init

# Select:
# ✅ Firestore
# ✅ Functions
# ✅ Authentication
# ✅ Emulators

# Deploy security rules
firebase deploy --only firestore:rules
```

---

## 🧪 Step 4: Start Development (2 minutes)

### Option A: Full Stack (Emulators + Flutter)

**Terminal 1 - Start Firebase Emulators:**
```bash
cd backend/functions
firebase emulators:start
```

**Terminal 2 - Run Flutter App:**
```bash
cd frontend
flutter run
```

### Option B: Backend Only (Test Cloud Functions)

```bash
cd backend/functions
firebase emulators:start
```

Test endpoints at `http://localhost:5001`

---

## ✅ Step 5: Verify Setup (1 minute)

### Test Backend Functions

**Send OTP:**
```bash
curl -X POST http://localhost:5001/<project-id>/us-central1/sendOtp \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+2348100000000",
    "name": "Test User"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "sessionId": "otp_sess_...",
  "messageSid": "SM..."
}
```

### Test Flutter App

1. Open app on emulator/device
2. Navigate to signup screen
3. Enter test phone number
4. Verify OTP received (check Twilio sandbox)

---

## 🐛 Common Issues

### Issue: "Firebase project not found"
**Fix**: Run `firebase use <project-id>`

### Issue: "OTP not received"
**Fix**: 
1. Join Twilio sandbox (send "join <code>" to Twilio number)
2. Verify phone number in Twilio console
3. Check Cloud Functions logs: `firebase functions:log`

### Issue: "Firestore permission denied"
**Fix**: Deploy security rules: `firebase deploy --only firestore:rules`

### Issue: "Flutter build failed"
**Fix**: 
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📚 Next Steps

- [ ] Read full documentation: `docs/module1_onboarding_README.md`
- [ ] Review security rules: `firestore.rules`
- [ ] Run tests: `npm test` (backend) and `flutter test` (frontend)
- [ ] Configure production environment variables
- [ ] Set up CI/CD pipeline

---

## 🆘 Need Help?

- **Documentation**: `/docs/module1_onboarding_README.md`
- **Security Guide**: See "Security Principles" in README
- **API Reference**: See "API Endpoints" in README
- **Troubleshooting**: See "Troubleshooting" section in README

---

## 🎯 Development Workflow

```
1. Create feature branch
   git checkout -b feature/your-feature

2. Make changes
   - Edit code
   - Test locally with emulators
   - Run tests

3. Commit with convention
   git commit -m "feat(auth): add feature description"

4. Push and create PR
   git push origin feature/your-feature

5. Deploy after approval
   firebase deploy
```

---

**Ready to build! 🚀**

For detailed information, see `docs/module1_onboarding_README.md`
