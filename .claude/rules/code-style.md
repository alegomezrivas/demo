---
paths:
  - "lib/**/*.dart"
---

# Dart / Flutter code style

## Language
- Code comments and doc comments are ALWAYS in English.
- UI strings are never hardcoded: use the generated `AppLocalizations` (ARB files, Spanish default + English).
- Identifiers are in English.

## Naming
- Files: `snake_case.dart`, one public type per file, named after the type.
- Types: `UpperCamelCase`; members and variables: `lowerCamelCase`; constants: `lowerCamelCase`.
- Suffixes by role: `*ViewModel`, `*View`, `*UseCase`, `*Repository` (contract) / `*RepositoryImpl`,
  `*RemoteDataSource` / `*LocalDataSource`, `*Dto` or `*Model` (data layer), `*Failure`, `*Exception`.
- Booleans read as questions: `isLoading`, `hasError`, `canSubmit`.

## Language features
- Prefer `const` constructors and `final` fields; models are immutable (freezed).
- No `dynamic`. No `!` (bang) unless a preceding comment justifies why null is impossible.
- Avoid `late` unless initialisation is guaranteed; prefer constructor injection.
- Keep functions small (about 20 lines) and with a single purpose.
- Use sealed classes / exhaustive `switch` for states and failures.

## Documentation
- `///` doc comment on every public class and public method; explain the *why*, not the *what*.
- Do not leave commented-out code or untracked TODOs.

## Design tokens (no hardcoded visuals)
- Never write literal colors, font sizes, paddings, margins, radii or elevations in widgets.
- Use `context.colors`, `context.text`, `context.spacing` (from `core/theme/`).
- Reusable widgets live in `core/widgets/` and consume tokens only.

## Architecture
- `domain` must not import `flutter`, `dio` or `stacked`.
- ViewModels depend on use cases only; navigation goes through `NavigationService`.
- Register dependencies in `app/locator.dart`; never call `GetIt` from domain code.

## Security
- Never log tokens, passwords or PII. Use the app logger, which is reduced in release.
- Show generic error messages to users; keep technical details out of the UI.
