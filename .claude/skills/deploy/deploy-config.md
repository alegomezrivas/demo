# Deploy configuration

## Environments

| Env | Config file | Mock API | Pinning | Root policy |
|---|---|---|---|---|
| dev | `config/dev.json` | allowed (`USE_MOCK_API=true`) | off | `warn` |
| staging | `config/staging.json` | allowed | optional | `warn` |
| prod | `config/prod.json` | **never** | **on, fingerprints required** | `block` |

Real files are git-ignored. Copy `config/dev.example.json` to create them.

## Expected keys (`--dart-define-from-file`)

```json
{
  "ENV": "dev | staging | prod",
  "API_BASE_URL": "https://api.example.com",
  "USE_MOCK_API": "true | false",
  "PINNING_ENABLED": "true | false",
  "PINNING_SHA256": "base64fingerprint1,base64fingerprint2",
  "ROOT_POLICY": "warn | block",
  "PROTECT_SCREENS": "true | false"
}
```

Release builds must ignore `USE_MOCK_API` (the mock is excluded when `kReleaseMode`).
Release and profile builds also refuse to start (a `StateError`) when `ENV` is missing or not
`staging`/`prod`, or when `prod` does not set `PINNING_ENABLED=true`. An unknown `ROOT_POLICY`
resolves to `block` there. Keep `PROTECT_SCREENS=true` except for demo builds.

## Build flags
- Obfuscation: `--obfuscate --split-debug-info=debug-info/<platform>`
- Android: R8/ProGuard enabled in `android/app/build.gradle` (`minifyEnabled true`, `shrinkResources true`).
- Signing: `android/key.properties` + keystore (git-ignored); iOS via Xcode automatic signing or fastlane match.

## Identifiers
- Bundle / application id: `com.softstark.demo`
- Version: `pubspec.yaml` `version: x.y.z+build`
