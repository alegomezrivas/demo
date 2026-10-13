# Stark Showcase

**English** · [Español](README.es.md)

Flutter app (Android and iOS) built as a portfolio piece. It demonstrates Clean Architecture, Stacked,
GoRouter, reactive forms, network security and thorough unit testing.
Identifier: `com.softstark.demo`. The backend is a Dio mock until a real API exists.

> Status: **Phase 5** (final review). Full plan in [`CLAUDE.md`](CLAUDE.md); before publishing, follow the
> [release checklist](docs/RELEASE_CHECKLIST.md).

## Requirements

- [FVM](https://fvm.app) (the Flutter version is pinned in [`.fvmrc`](.fvmrc): **3.41.6**, Dart 3.11)
- Android: `minSdk 24` · iOS 15.0+

## Setting up the SDK with FVM

```bash
dart pub global activate fvm   # once
fvm install                    # downloads the version listed in .fvmrc
fvm flutter pub get
```

Every project command is run with the `fvm` prefix, so the whole team and CI use the same SDK.
To change the version: `fvm use <version>` and commit the new `.fvmrc`. The `.fvm/` folder is local and git-ignored.

- **VS Code**: `.vscode/settings.json` already points to `.fvm/flutter_sdk` (run `fvm use` once to create the link).
- **Android Studio / IntelliJ**: *Settings → Languages & Frameworks → Flutter → Flutter SDK path* = `<project>/.fvm/flutter_sdk`.

## Commands

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs   # mocks and generated code
fvm flutter gen-l10n                                           # localized strings (ARB)
fvm dart format .
fvm flutter analyze
fvm flutter test --coverage
```

Run with an environment configuration (copy `config/dev.example.json` to `config/dev.json`;
the real `config/*.json` files are git-ignored):

```bash
fvm flutter run --dart-define-from-file=config/dev.json
```

> Without FVM, any Flutter 3.41.6 on the `PATH` also works: drop the `fvm` prefix.

## Architecture

```
lib/
├── app/        App, locator (GetIt) and router (GoRouter)
├── core/       theme (design tokens), config, services, security, widgets
├── features/   <feature>/{data,domain,presentation}
└── l10n/       ARB files (Spanish by default + English)
test/           mirrors lib/
```

Dependencies point inward (`presentation → domain ← data`). ViewModels only call use cases and navigate
through `NavigationService`. Full rules in [`AGENTS.md`](AGENTS.md).

## How to change the design (design tokens)

All visuals live in `lib/core/theme/`. Widgets never contain literal colors, sizes, paddings or radii:
they use `context.colors`, `context.text` and `context.spacing`.

| I want to change… | I only edit… |
|---|---|
| Color palette (light / dark) | `lib/core/theme/app_colors.dart` (`AppColors.light` and `AppColors.dark`) |
| Font | `AppTypography.fontFamily` in `app_typography.dart` + `fonts:` in `pubspec.yaml` (files in `assets/fonts/`) |
| Text sizes and weights | `AppTypography.build` in `app_typography.dart` |
| Spacing, radius and elevation scale | `lib/core/theme/app_spacing.dart` |
| How they apply to Material components | `lib/core/theme/app_theme.dart` |

Notes:

- **Light/dark mode**: automatic, following the system (`ThemeMode.system`).
- **Text scaling**: follows the system setting up to a cap (`AppConstants.maxTextScaleFactor`).
- **Font**: Inter is bundled in `assets/fonts/inter/` (OFL license included); the app never downloads fonts.
- **App name**: `AppConstants.appName`, `appName` in `lib/l10n/app_*.arb`, `android/app/src/main/res/values/strings.xml` and `CFBundleDisplayName` in `ios/Runner/Info.plist`.

## Per-environment configuration

Keys (`--dart-define-from-file`): `ENV`, `API_BASE_URL`, `USE_MOCK_API`, `PINNING_ENABLED`,
`PINNING_SHA256`, `ROOT_POLICY` (`warn` | `block`), `PROTECT_SCREENS`. Templates in `config/*.example.json`.

- `USE_MOCK_API` is ignored in **release and profile** builds, and the mock backends are not even built in release.
- Moving from the mock to the real API only requires changing `API_BASE_URL`.
- With `PINNING_ENABLED=true` and an empty `PINNING_SHA256`, the client rejects all traffic (fails closed).
- `PROTECT_SCREENS` (default `true`) hides the whole authenticated app from screenshots and from the app-switcher
  preview. Set it to `false` only for demo builds where you need screenshots.
- **A release build refuses to start with a weak configuration**: `ENV` must be `staging` or `prod` (if it is
  missing, the app throws a `StateError` at startup), `prod` requires `PINNING_ENABLED=true`, and an unknown
  `ROOT_POLICY` becomes `block`.

## Authentication (`auth` feature)

Complete sign-in and sign-up with `reactive_forms`, use cases (`Login`, `Register`, `Logout`,
`GetCurrentUser`), a repository with remote (Dio) and local (secure storage) datasources, and `freezed` DTOs.

- **Mock demo account**: `demo@starkshowcase.dev` / `Demo1234!` (exists only in memory with `USE_MOCK_API=true`).
- **Router guard**: without a session only `/login` and `/register` are reachable; with a session, `/login`
  redirects to the home screen. `SessionService` notifies the router and signs the user out when the token
  refresh is rejected.
- **Persistent session**: on launch the stored user is restored (tokens live in the Keystore/Keychain).
- **Sensitive screens**: sign-in and sign-up enable `ScreenProtection` (reference counted).
- **Errors**: generic, localized messages (wrong credentials, e-mail already registered, no connection...).
- **Input**: validators in the forms and `InputSanitizer` in the repository (passwords are never modified).

## Features

The app is a task manager with three tabs (bottom navigation bar):

| Tab | What it does |
|---|---|
| **Home** (`dashboard`) | Greeting, completion percentage and statistics (total, completed, overdue, open high-priority). It reloads by itself when tasks change in another tab. |
| **Tasks** (`tasks`) | Paginated list (infinite scroll), debounced search, status and priority filters, completing with the checkbox (optimistic, with rollback), deleting with confirmation, and a `reactive_forms` form to create and edit. |
| **Settings** (`settings`) | Profile, theme (system/light/dark), language (system/Spanish/English), biometric confirmation and sign-out. |

- **Preferences**: stored in `shared_preferences` (they are not secrets) and applied instantly through `AppPreferences`.
- **Biometric confirmation** (optional): when on, fingerprint/face/PIN is requested before **deleting tasks** and
  **signing out** (`SensitiveActionGuard`). Changing the option also requires confirmation. If the device cannot
  authenticate (no screen lock), the user is not locked out.
- **Mock backend**: `MockTasksBackend` simulates search, filters, pagination, CRUD and statistics (23 sample tasks;
  it answers 401 without a token). Try failures with the `x-mock-scenario` header (see below).
- **Entity name**: `TaskItem` (not `Task`) to avoid clashing with `fpdart`'s `Task` type.

## Networking and mock backend

`DioClientFactory` builds the client with this interceptor order: **HTTPS enforcer → auth → logging → mock**.

- **Auth**: adds the bearer token; on a 401 it renews the token **only once** (several simultaneous 401s share a
  single renewal) and retries. If the server **rejects** the refresh (401/403), it clears the tokens and
  `SessionExpiredNotifier` sends the user back to sign-in. If the refresh fails because of the network, a timeout
  or a 5xx, the session **is kept** and the user sees a connection error.
- **Mock** (`MockApiInterceptor`): only with `USE_MOCK_API=true` and never in release. It simulates latency and can
  be forced per request with the `x-mock-scenario` header:

| Value | Effect |
|---|---|
| `server_error` | answers 500 |
| `offline` | fails as if there were no connection |
| `unauthorized` | always answers 401 |
| `unauthorized_once` | answers 401 once; works after the refresh |

  Features register their endpoints as `MockRoute`s through `setupLocator(mockRoutes: ...)`.
  To use the real API, only change `API_BASE_URL` (and set `USE_MOCK_API=false`).
- **Errors**: datasources convert `DioException` with `DioExceptionMapper`; repositories map them to
  `Failure` (`FailureMapper`) and the UI shows generic, localized messages.

## Security

- **Storage**: tokens only in `flutter_secure_storage` (`SecureTokenStorage`).
- **Transport**: HTTPS only (interceptor + `network_security_config` + ATS); the single exception is plain HTTP to
  `10.0.2.2`, `localhost` and `127.0.0.1` in **debug builds** (dev backend on the emulator). Configurable certificate pinning
  (`PINNING_ENABLED`, `PINNING_SHA256` with base64 SHA-256 fingerprints of the certificate); enabled without
  fingerprints it **rejects all traffic**. See *Known limitations* below.
- **Device integrity**: `ROOT_POLICY=warn|block` (root/jailbreak and debugger) applied by `IntegrityGate`.
  If detection fails: with `warn` it is ignored, with `block` the device is treated as untrusted.
- **Biometrics** (`BiometricAuthenticator`, `local_auth`) and **screen protection** (`ScreenProtection`, reference
  counted): blocks screenshots on Android and blurs the app-switcher preview across the whole authenticated
  shell (configurable with `PROTECT_SCREENS`).
- **ViewModel dependencies**: use cases for business logic, plus `core` services (`NavigationService`,
  `SessionService`, `AppPreferences`, `ScreenProtection`, `BiometricAuthenticator`, `SensitiveActionGuard`);
  never repositories or datasources.
- **User input**: reusable validators (`AppValidators`) with localized messages, and `InputSanitizer` before
  sending to the backend.
- **Logs**: `ConsoleAppLogger` redacts tokens/passwords and only emits errors in release.
- **Android**: no cleartext traffic, `allowBackup=false`, R8 + `shrinkResources` in release. The release build is
  **not signed** with debug keys: define `android/key.properties` (git-ignored) with `keyAlias`, `keyPassword`,
  `storeFile` and `storePassword`.
- **iOS**: App Transport Security with no exceptions; Keychain items use `first_unlock_this_device` (not copied to
  other devices or backups).
- **Release**: `--obfuscate --split-debug-info=debug-info/<platform>` (see `.claude/skills/deploy/`).

## Continuous integration

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs on every pull request, on every push to `master`
and manually (*workflow_dispatch*). It uses the Flutter version from `.fvmrc`.

| Job | What it checks |
|---|---|
| `verify` | `pub get`, that generated code (`build_runner`, `gen-l10n`) is up to date, `dart format`, `flutter analyze`, `flutter test --coverage` and the coverage threshold (`tool/check_coverage.sh`: `domain/` and ViewModels ≥ 80 %). Uploads `lcov.info` as an artifact. |
| `dependencies` | `flutter pub outdated` (informational: never blocks). |
| `android-release-build` | Builds an **unsigned** `appbundle` with R8 and `--obfuscate` using `config/prod.example.json`, to catch minification breakage early. Uploads the symbols as an artifact. |
| `ios-release-build` | Only on pushes to `master` and manual runs (pull requests do not start it). On a **macOS** runner: `flutter build ios --release --no-codesign --obfuscate` with `config/prod.example.json`, to check that the iOS project, the Pods and obfuscation build without certificates. Uploads the symbols as an artifact. |

The Android and iOS jobs could not be run in the development environment (no Android SDK or Xcode):

- Android: if it fails the first time because of some plugin's R8 rules, add the required `-keep` rules to
  `android/app/proguard-rules.pro`.
- iOS: there is no versioned `ios/Podfile` (Flutter generates it during the build). After the first build on a Mac,
  commit `ios/Podfile` and `ios/Podfile.lock` so the Pods are reproducible.
- macOS runners cost more minutes than Linux ones: that is why the iOS job does not run on pull requests, only after
  merging into `master` or when started by hand (*Actions → CI → Run workflow*), and always after `verify` passes.

To reproduce the coverage gate locally: `fvm flutter test --coverage && tool/check_coverage.sh`.

## Known limitations (phase 5 review)

- **Pinning**: Dio validates the certificate when the response headers arrive, so the request has already been sent
  (the response is discarded), and the hash of the whole certificate is pinned, not that of its public key (SPKI).
  Before production with a real API: pin the SPKI with at least two fingerprints (current and backup) and check it
  during the TLS handshake.
- **Root/jailbreak detection**: it can be bypassed by nature (hooking tools); it is defense in depth, not a
  guarantee. Anything stronger needs attestation (Play Integrity / App Attest).
- **Biometric setting** in `shared_preferences`: it can be modified on a rooted device; it only protects against
  casual use.
- **Android/iOS builds could not be compiled** in the development environment (no Android SDK or Xcode): a smoke
  test of a release build with R8 and obfuscation is still missing (see `docs/RELEASE_CHECKLIST.md`).
- Native plugin tests use *mocks*: validate them on real devices.
