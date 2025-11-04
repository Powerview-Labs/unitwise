🧭 PowerView Labs Contribution Guidelines

Welcome to the UnitWise repository! 🎉
We’re building Nigeria’s smartest electricity tracker — and every contribution helps.
Please read these guidelines before you make changes.

🧱 1. Development Setup

Clone the repo via SSH:
git clone git@github.com:Powerview-Labs/unitwise.git

Run flutter pub get in frontend/

Run npm install in backend/functions/

Start Firebase Emulator: firebase emulators:start

🔐 2. Security & Compliance

Never commit secrets or .env files.

Follow Firebase Security Rules strictly.

Use secure coding (no plaintext passwords or tokens).

Always mask PII in logs.

🧩 3. Commit Convention

We use Conventional Commits:

<type>(scope): <description>


Examples:

feat(auth): implement Twilio OTP verification flow
fix(dashboard): correct estimated unit display rounding
docs(readme): update setup guide for macOS users


Common types:

feat: new feature

fix: bug fix

docs: documentation

chore: minor task or config

test: new or updated tests

refactor: internal cleanup

🧪 4. Testing Before Push

Run all tests before pushing:

npm test      # backend
flutter test  # frontend

🧱 5. Pull Requests

Create a feature branch: git checkout -b feature/<your-feature>

Ensure your branch is up-to-date with main

Open a Pull Request (PR) — GitHub will run automated checks

Include screenshots or test results if it’s a UI update

🔍 6. Code Review

At least one reviewer (core team or Claude AI code review workflow) must approve before merging.

💬 7. Issues

When creating a GitHub Issue:

Describe the bug or feature clearly.

Include steps to reproduce (for bugs).

Assign appropriate labels (bug, feature, UI, security, etc.)

💡 8. Contact

If you’re unsure about a contribution:

Security concerns → security@powerviewlabs.com

Development help → dev@powerviewlabs.com

✅ Summary
Follow secure, consistent, and test-driven development practices.
Together, we build technology that empowers energy users. ⚡