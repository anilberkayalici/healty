# Healty — Health & Wellness App (Flutter Prototype)

Healty is a Flutter mobile app prototype for daily health habits and usage awareness.  
**Status:** Under active development (not a final product).

## Features
- **Step counter** (daily activity tracking)
- **Water intake reminder**
- **Screen Time dashboard** (Today / Week usage overview)
- **Posture awareness** (tech-neck angle feedback)
- **Offline-first** (works without a backend)

## Tech Stack
- Flutter / Dart
- Local storage (offline usage)

## Getting Started
```bash
flutter pub get
flutter run
```

lib/
  screens/        UI screens (dashboard, water, screen time, posture, etc.)
  services/       Background tasks / reminders / integrations
  models/         Data models
  utils/          Helpers & constants
assets/           App assets
