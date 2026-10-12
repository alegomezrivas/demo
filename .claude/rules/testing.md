---
paths:
  - "test/**"
  - "**/*_test.dart"
---

# Testing rules

## Scope
- Every feature ships with unit tests: use cases, repositories (datasources mocked),
  datasources (Dio mocked), ViewModels (state, loading, errors, navigation), validators,
  interceptors and security utilities.
- Minimum coverage: **80%** in `domain/` and `presentation/viewmodels/`.
  Check with `flutter test --coverage`.
- A feature is not done until its tests pass.

## Structure
- `test/` mirrors `lib/` exactly: `lib/a/b/c.dart` -> `test/a/b/c_test.dart`.
- Mocks are generated with mockito `@GenerateNiceMocks` / `@GenerateMocks`; run
  `dart run build_runner build --delete-conflicting-outputs`.
- Shared fixtures and builders go in `test/helpers/`.

## Style
- Arrange-Act-Assert, separated by blank lines.
- Descriptive names: `'returns ServerFailure when the datasource throws ServerException'`.
- One behaviour per test; group with `group()` per method.
- Cover the happy path, error paths and edge cases (empty, null-like, boundaries, repeated calls).
- Use `provideDummy` for `Either` values with mockito when needed.
- Tests must be deterministic: no real network, no real clock (inject a clock), no sleeps.
- ViewModel tests verify `isBusy`, `hasError`, state transitions and calls to the mocked `NavigationService`.
- Tests for security code cover both secure and insecure configurations
  (for example certificate pinning enabled with an empty pin list must fail closed).

## Comments
- Test comments and descriptions are in English.
