---
name: deploy
description: Build and release the Flutter app for Android (AAB) and iOS (IPA) with obfuscation, split debug info and environment config. Use when the user asks to build, release, package or prepare a store submission.
disable-model-invocation: true
allowed-tools: Bash(flutter:*), Bash(dart:*), Bash(git status:*), Bash(git tag:*), Read, Grep
---

# Deploy skill

Follow `deploy-config.md` for flags, paths and environment values. Never read or print
secret files (`config/*.json`, keystores, `key.properties`).

## Pre-flight (stop on the first failure)
1. `git status` is clean and you are on the intended release branch.
2. `flutter pub get` then `dart run build_runner build --delete-conflicting-outputs`.
3. `dart format --set-exit-if-changed .`
4. `flutter analyze` reports no issues.
5. `flutter test --coverage` passes and domain / viewmodels coverage is >= 80%.
6. `flutter pub outdated` reviewed; no abandoned or vulnerable packages.
7. Confirm `USE_MOCK_API` is `false` and certificate pinning fingerprints are set in `config/prod.json`
   (check only that the keys exist; do not print values).

## Build
- Android: `flutter build appbundle --release --obfuscate --split-debug-info=debug-info/android --dart-define-from-file=config/<env>.json`
- iOS: `flutter build ipa --release --obfuscate --split-debug-info=debug-info/ios --dart-define-from-file=config/<env>.json`

## Post-build
1. Archive `debug-info/` outside the repo (needed to symbolicate obfuscated crashes). It is git-ignored.
2. Report artifact paths and the version from `pubspec.yaml`.
3. Suggest a tag `v<version>+<build>`; create it only if the user confirms.
4. Never upload to a store or push tags without explicit user confirmation.
