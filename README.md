# Money Plant 🌱

A Flutter app for tracking expenses, growing savings, and splitting bills — with a playful design and light/dark themes.

**Website:** <https://moneyplantbydev.pages.dev/> — showcase, downloads, release history and install guide (source in [`site/`](site/README.md)).

## Features

- Five offline theme packs with light/dark/auto modes, bundled fonts, and a fast animated launch.
- Income/expense tracking, ledger search, recurring entries with catch-up, and monthly category budgets.
- Editable, duplicable shared bills; itemised splitting with tax, tip, and discount; payment removal and undo.
- Person history with task balances, rename/merge/delete, text/PDF statements, UPI QR codes, settle-all, and editable nudges.
- Groups and trips with member balances, suggested payments, group statements, and archiving.
- On-device CSV/XLSX and supported text-PDF statement import, review, duplicate detection, split selection, and payment matching.
- CSV exports and versioned JSON backups with file or paste restore, including original v1 backups.
- Device authentication lock with an animated vault and Android Recents protection.
- Optional Android reminders, category-budget warnings, haptics, and reduced-motion support.
- Silent launch update checks, daily Android background checks, release notifications, and direct universal APK download links.

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

The workflow validates and publishes a signed universal APK. An explicitly updated, untagged version is released as written; otherwise the workflow increments the version and Android build number. This release is **v2.0.0 (build 3)**. Pull requests run validation checks. Android device testing is separate from automated checks.

---

Built with 💖 in India by DJ Khatri.

## Import and dependency notes

Statement imports show a review screen before saving. CSV and XLSX column mappings can be selected manually. PDF extraction requires readable text and identifiable table columns; scanned or unrecognised PDF layouts should be exported as CSV/XLSX instead. Passwords are used in memory only.

See [third-party notices](THIRD_PARTY_NOTICES.md) for bundled font licenses and Syncfusion PDF licensing. The PDF and file-picker versions are pinned/constrained for compatibility with the existing dependency graph.

## App updates and website link

The app checks the public GitHub releases API after launch and on resume (debounced for one minute to avoid repeated checks around system prompts). Only newer stable versions trigger a dismissible update dialog. Offline, timeout, rate-limit and missing-release responses are silent. Financial data is never sent; the only network request is for public release metadata.

Android registers one unique daily WorkManager job with a connected-network constraint. Timing is best effort (battery restrictions and force-stop can delay it). In Settings, allow update notifications; daily checks can also be disabled there independently of financial reminders. Each release produces at most one notification. Tapping it opens the same dialog, including from a cold start, with a cached release fallback when offline. Installed versions are checked again to avoid stale update offers.

The Update button and Settings → More info open **https://moneyplantbydev.pages.dev**. The website provides release history, downloads and installation instructions. GitHub remains the source of version metadata. The dialog also links directly to the GitHub release notes.

Android downloads must be opened and installed by the user. Keep the same application ID and signing key for every release to preserve installed app data. No silent installer is included.

The production website is the default in `lib/core/app_updates.dart`. It can be overridden for another deployment:

```sh
flutter build apk --release --dart-define=MONEY_PLANT_WEBSITE_URL=https://moneyplantbydev.pages.dev
```

Background update notifications target Android. Local planning docs, agent/skill files, credentials, build outputs, dependency directories and deployment caches are excluded from Git. App/site source, tests, workflow files, package lockfiles and license notices are included.

### Android Kotlin compatibility

AGP 9.1 currently runs with `android.builtInKotlin=false` because some bundled plugins still use KGP. `file_picker` 11 assumes built-in Kotlin whenever AGP is 9+, so the root Android build explicitly applies KGP and JVM 17 to that module. This ensures `FilePickerPlugin.kt` is compiled and available to Flutter’s generated plugin registrant. Remove this compatibility block when the dependency set is migrated together to built-in Kotlin.
