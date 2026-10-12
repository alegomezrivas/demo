# AGENTS.md

Shared context for any AI coding agent (Claude Code, Codex, Cursor, Copilot).

## Project

**Stark Showcase** (`com.softstark.demo`) is a Flutter portfolio app (Android + iOS)
that demonstrates production-grade Flutter engineering: Clean Architecture,
Stacked state management, secure networking and thorough unit tests.
The backend is mocked with a Dio `MockInterceptor` until a real API exists.

The visible app name lives in ONE place: `AppConstants.appName` and the ARB files.

## Stack

- Flutter (stable) + Dart with strict null-safety
- Clean Architecture, organised by feature
- State: Stacked (`BaseViewModel`, `ViewModelBuilder`), DI: GetIt
- Navigation: GoRouter, wrapped by an abstract `NavigationService`
- Forms: `reactive_forms` only (FormGroup lives in the ViewModel)
- HTTP: Dio with interceptors (auth/refresh, logging, mock)
- Models: `freezed` + `json_serializable`
- Functional errors: `fpdart` (`Either<Failure, T>`)
- Secure storage: `flutter_secure_storage`; biometrics: `local_auth`
- Tests: `flutter_test` + `mockito`

## Layout

```
lib/app/        app shell, locator (GetIt), router
lib/core/       theme (design tokens), network, security, error, services, utils, widgets
lib/features/<feature>/{data,domain,presentation}
test/           mirrors lib/ exactly
```

## Architecture rules

1. Dependencies point inward: presentation -> domain <- data.
2. `domain` must not import Flutter, Dio or Stacked.
3. ViewModels call use cases only, never repositories or datasources.
4. Use cases return `Either<Failure, T>`.
5. Everything is injected through constructors and registered in `locator.dart`;
   depend on abstractions.
6. One file = one responsibility. No "god" classes.
7. ViewModels navigate through the abstract `NavigationService`.

## Design tokens

All visuals come from `lib/core/theme/` (`app_colors`, `app_typography`,
`app_spacing`, `app_theme`). Widgets must NOT hardcode colors, font sizes,
paddings or radii. Use `context.colors`, `context.text`, `context.spacing`.

## Code rules

- Code comments and doc comments (`///`) are ALWAYS in English.
- UI strings are Spanish (default) and English, via ARB files; never hardcode them.
- No `dynamic` and no `!` without a justification comment.
- Prefer `const`, immutability and small functions.
- Conventional commits: `feat:`, `fix:`, `test:`, `refactor:`, `chore:`, `docs:`.

## Security rules

- No secrets in code. Environment config comes from `--dart-define-from-file`.
- Tokens and sensitive data only in `flutter_secure_storage`, never SharedPreferences.
- HTTPS only. Certificate pinning is configurable; enabled with an empty pin list it must fail closed.
- Never log tokens, passwords or PII. Show generic error messages to users.
- The mock interceptor is enabled only via a dart-define and must never be active in release builds.

## Commands

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm dart format .
fvm flutter analyze
fvm flutter test --coverage
fvm flutter run --dart-define-from-file=config/dev.json
```

The Flutter version is pinned in `.fvmrc` (FVM): run `fvm install` once and prefix every Flutter/Dart
command with `fvm`. Without FVM, any Flutter on the `PATH` with the same version works (drop the prefix).

A feature is not done until `dart format .`, `flutter analyze` and `flutter test` pass.
