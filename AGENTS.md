# Flutter Devs Kenya — Agent Instructions

## Cursor Cloud specific instructions

### Project overview

This is a Flutter mobile app (community chat platform) located in `/workspace/mobile/`. The backend is fully managed by Supabase (no custom server). See `mobile/README.md` for the full stack description and getting-started guide.

### Prerequisites (already installed in the VM snapshot)

- **Flutter SDK (beta channel)** at `/opt/flutter` — required because the project depends on `riverpod` features only available on beta.
- **Android SDK** at `$HOME/android-sdk` — includes platform-tools, build-tools, NDK, and CMake (auto-installed by Gradle on first build).
- **Java 21** (system default) — compatible with the project's Java 17 source/target compatibility.

### Key dev commands (run from `/workspace/mobile/`)

| Task | Command |
|------|---------|
| Install deps | `flutter pub get` |
| Code generation | `dart run build_runner build --delete-conflicting-outputs` |
| Lint / analyze | `flutter analyze` |
| Run tests | `flutter test` |
| Build debug APK | `flutter build apk --debug` |
| Build release bundle | `flutter build appbundle` |

### Non-obvious caveats

- **`.env` file required**: The app loads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from `mobile/.env` (gitignored). A placeholder file is created by the update script. For real Supabase connectivity, replace with valid credentials.
- **Generated code is checked in**: Files like `*.g.dart`, `*.gr.dart`, and `*.freezed.dart` are committed. If you modify annotated source files (models, providers, routes), re-run `dart run build_runner build --delete-conflicting-outputs`.
- **Beta channel only**: The CI and README both specify Flutter beta. Do not switch to stable — it may lack required SDK features.
- **No emulator in headless VM**: `flutter run` requires a connected device or emulator. In this VM, use `flutter build apk --debug` to verify builds. Tests run headlessly via `flutter test`.
- **`riverpod_lint` analyzer warning**: You may see a warning about SDK language version being newer than `analyzer` language version. This is benign and does not affect builds or tests.
