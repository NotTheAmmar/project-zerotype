# Contributing to BazaarSetu (Project ZeroType)

Thank you for contributing to **BazaarSetu** (बाज़ारसेतु)! Our mission is to bridge Indian traditional craft artisans and local sellers directly into the Open Network for Digital Commerce (ONDC) using voice, computer vision, and tactile zero-typing mobile interfaces.

---

## 🛡️ Branching Model & Protected Main

To ensure high quality, stability, and continuous integration:
1. **Direct pushes to `main` are restricted.**
2. All changes must be developed on a dedicated feature, fix, or chore branch.
3. Every change must be submitted as a **Pull Request (PR)** against `main`.
4. Automated CI (`flutter analyze`, `flutter test`, `backend-ci`) must pass before a PR can be merged.

### Branch Naming Conventions
- `feature/<short-description>`: New screens, multimodal capabilities, or features (e.g. `feature/audio-readback`)
- `fix/<issue-description>`: Bug fixes or error resolution (e.g. `fix/voice-timer-leak`)
- `chore/<task-name>`: Upgrades, tooling, CI/CD, or documentation (e.g. `chore/pubspec-upgrade`)

---

## 🚀 Development Workflow

### 1. Create a Branch
```bash
git checkout main
git pull origin main
git checkout -b feature/your-feature-name
```

### 2. Make & Test Your Changes Locally
Before committing, ensure that Flutter analysis and tests pass cleanly:

```bash
# Verify static analysis (must report 0 issues)
flutter analyze

# Run unit, controller, and widget tests (33+ tests must pass)
flutter test

# If modifying the Python backend:
cd backend
python -m py_compile main.py generate_keys.py
pytest tests/
```

### 3. Commit with Clear Conventional Messages
```bash
git add -A
git commit -m "feat(voice): add Gujarati spoken category anchor"
```

### 4. Push Branch & Open a Pull Request
```bash
git push -u origin feature/your-feature-name
```
Then navigate to GitHub and open a Pull Request using the provided PR template.

---

## 🔒 Security & Sensitive Data
- **Never commit `.env` or sensitive API keys.**
- Keep secrets in GitHub Repository Secrets (`Settings -> Secrets and variables -> Actions`).
- Use `.env.example` as a template for team members.
