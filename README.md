# Money Plant 🌱

A Flutter app for tracking expenses, growing savings, and splitting bills — with a playful design and light/dark themes.

## Features

- Income and expense tracking with categories, search, and monthly insights.
- Savings goals, money tasks, and shared bills with partial settlements.
- Cute illustrated Android reminders for expenses, monthly planning, pending splits, and budget limits.
- Animated opening scene, custom plant icon, and accessible motion controls.
- JSON backups, PDF reports, and sharing.

Data stays on your device. No account or bank connection is required. Storage is not encrypted; export backups before clearing app data. Android reminders are optional and can be enabled in **Settings → Cute reminders**.

## Getting started

Use Flutter **3.47.2** / Dart **3.13.2**. Android development also requires Java 17+, the Android SDK, and a device or emulator.

```sh
flutter pub get
flutter run
```

For the browser preview, run `flutter run -d chrome`. Scheduled notifications are Android-only.

## Check and build

```sh
flutter analyze
flutter test
flutter build apk --release
```

Configure `android/key.properties` with your release keystore before distributing an APK. Without it, local release builds use a development signing key. Keep signing files out of Git.

## GitHub releases

Pushes to `main` trigger the Android release workflow. Configure these repository Actions secrets first:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`

The workflow validates the app, increments its version, and publishes a signed APK. Pull requests run validation checks. Android device testing and the first signed release are still pending.

---

Built with 💖 in India by DJ Khatri.
