# ⚡ UnitWise by PowerView Labs

### Smart Electricity Unit Tracking for Nigerian Households

UnitWise helps users track their prepaid electricity usage, estimate how long their remaining units will last, and receive smart recommendations to extend their unit life.

---

## 🧩 Tech Stack
- **Frontend:** Flutter (Android, iOS)
- **Backend:** Firebase (Auth, Firestore, Cloud Functions)
- **Messaging:** Twilio WhatsApp API
- **Email:** SendGrid
- **Hosting:** Firebase Hosting

---

## 🚀 Features
- OTP-based authentication via WhatsApp
- Auto-login persistence
- Location-based DisCo and Band detection
- Real-time unit tracking and estimation
- Appliance estimator and budget planner

---

## 🧰 Folder Structure
unitwise/
│
├── backend/
│ └── functions/
│
├── frontend/
│ └── lib/
│
└── docs/
└── module1_onboarding_README.md


---

## 👩🏾‍💻 Setup Instructions
1. Clone repo and install dependencies
2. Copy `.env.example` → `.env` and fill in credentials
3. Deploy Firebase rules and functions
4. Run Flutter app locally

---

## 🔒 Security Highlights
- No plaintext passwords or OTPs stored
- Bcrypt hashing and rate limiting on OTP
- Firebase Auth handles token lifecycle
- Firestore uses UID-based access control
- `.env` never committed to git

---

**Maintained by PowerView Labs**  
`https://powerviewlabs.com` (coming soon)
