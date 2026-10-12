---
paths:
  - "lib/**/data/**"
  - "lib/core/network/**"
  - "lib/core/error/**"
---

# Data layer and API conventions

## Layers
- `datasources/` talk to Dio or local storage and throw typed `Exception`s only.
- `repositories/` (implementations) catch exceptions and map them to `Failure`s,
  returning `Either<Failure, T>`. Exceptions never cross the repository boundary.
- `models/` are DTOs (freezed + json_serializable) with `toEntity()` / `fromEntity()` mappers.
  Domain entities never contain JSON code.

## Errors
- Exceptions: `ServerException`, `NetworkException`, `UnauthorizedException`, `CacheException`, `ValidationException`.
- Failures (sealed): `ServerFailure`, `NetworkFailure`, `UnauthorizedFailure`, `CacheFailure`, `ValidationFailure`, `UnexpectedFailure`.
- Failures carry a machine-readable code, not user text. The presentation layer maps
  failures to localized, generic messages. Never surface stack traces, URLs or server bodies.

## Networking
- One configured `Dio` instance created in `core/network/`; base URL and flags come from `AppConfig`
  (`--dart-define-from-file`). Switching from the mock to a real API changes only the base URL.
- HTTPS only. Certificate pinning is configurable; with pinning enabled and an empty fingerprint
  list the client must reject all connections (fail closed).
- Interceptors, in order: mock (dev/staging only, behind `USE_MOCK_API`, never in release),
  auth (adds bearer token, refreshes on 401 and retries ONCE, signs out if refresh fails),
  logging (redacts `Authorization`, passwords and tokens; silent in release).
- Set explicit connect/receive timeouts.

## Input handling
- Validate and sanitize user input in form validators AND again before building a request body.
- Never concatenate user input into URLs; use `queryParameters` / path builders.

## Storage
- Secrets (access/refresh tokens, PII) go to `flutter_secure_storage` only, never SharedPreferences.

## Pagination and lists
- Paginated endpoints return a `Page<T>` value with items, page, pageSize and `hasMore`.
