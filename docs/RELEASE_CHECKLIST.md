# Release checklist

**English** · [Español](RELEASE_CHECKLIST.es.md)

Tick every item before publishing. Commands use FVM (version pinned in `.fvmrc`); without FVM, drop the `fvm` prefix.

## 1. Quality (blocking)

- [ ] `fvm dart format --set-exit-if-changed .` changes nothing
- [ ] `fvm flutter analyze` → *No issues found*
- [ ] `fvm flutter test --coverage` is green; `domain/` and `presentation/viewmodels/` ≥ 80 %
- [ ] `fvm dart run build_runner build --delete-conflicting-outputs` leaves no uncommitted changes
- [ ] `fvm flutter pub outdated`: no discontinued packages; pending updates have been reviewed
- [ ] No ownerless `TODO`/`FIXME` in `lib/`

## 2. Per-environment configuration

`config/prod.json` (git-ignored; start from `config/prod.example.json`):

- [ ] `ENV` = `prod`
- [ ] `API_BASE_URL` points to the real API and is `https://`
- [ ] `USE_MOCK_API` = `false` (it is ignored in release anyway)
- [ ] `PINNING_ENABLED` = `true` and `PINNING_SHA256` holds the fingerprints (base64 SHA-256 of the certificate) **for production and for the backup**
- [ ] `ROOT_POLICY` = `block` (or `warn` if allowing it is a deliberate decision)
- [ ] `PROTECT_SCREENS` = `true` (`false` only for demo builds)
- [ ] The file is **not** in git (`git check-ignore config/prod.json`)
- [ ] The build starts: in release the app throws a `StateError` if `ENV` is missing (or is not `staging`/`prod`) and if `prod` does not enable pinning

> Pinning: the fingerprint is that of the whole certificate, so it changes when the certificate is renewed. Always
> include the next certificate's fingerprint before rotating, or the app will stop connecting.

## 3. Identity and permissions

- [ ] Visible name: `AppConstants.appName`, `lib/l10n/app_*.arb`, `android/app/src/main/res/values/strings.xml`, `ios/Runner/Info.plist`
- [ ] Final icons and splash screen (Android `mipmap-*`, iOS `AppIcon.appiconset`)
- [ ] Id `com.softstark.demo` (or the final one) matches on Android and iOS
- [ ] `version` / build number bumped in `pubspec.yaml`
- [ ] Minimal permissions: Android only `INTERNET` and `USE_BIOMETRIC`; iOS `NSFaceIDUsageDescription` written

## 4. Signing

- [ ] Android: `android/key.properties` (git-ignored) with `keyAlias`, `keyPassword`, `storeFile`, `storePassword`; keystore stored outside the repo and backed up
- [ ] The release build does **not** use debug keys (without `key.properties` the AAB is produced unsigned)
- [ ] iOS: signing team and provisioning profiles configured in Xcode or fastlane

## 5. Build

```bash
fvm flutter build appbundle --release --obfuscate \
  --split-debug-info=debug-info/android --dart-define-from-file=config/prod.json
fvm flutter build ipa --release --obfuscate \
  --split-debug-info=debug-info/ios --dart-define-from-file=config/prod.json
```

- [ ] R8 and resource shrinking are on (already configured in `android/app/build.gradle.kts`)
- [ ] `debug-info/` archived **outside** the repo (it is used to symbolicate crashes)
- [ ] Test on real devices: sign-in, tasks, settings, biometrics, screenshot blocking, airplane mode

## 6. Security verification on the binary

- [ ] No cleartext HTTP: `src/main/res/xml/network_security_config.xml` has no domain with `cleartextTrafficPermitted="true"`
      (only `src/debug/res/xml/` may, for `10.0.2.2`/`localhost`/`127.0.0.1`), and the release APK/AAB merged config confirms it
- [ ] With `PINNING_ENABLED=true` and a certificate different from the pinned one, the app does **not** connect
- [ ] On a rooted/jailbroken device, `ROOT_POLICY` is applied
- [ ] Check the logs of a release build: no tokens or personal data may appear
- [ ] The mock's demo account (`demo@starkshowcase.dev`) does **not** work against the real API

## 7. Stores

- [ ] Privacy policy and data safety form (Play) / *App Privacy* (App Store)
- [ ] Screenshots in ES and EN; description and release notes
- [ ] Upload **only** after explicit confirmation; tag `v<version>+<build>` after publishing

## 8. Blockers before production with a real API

- [ ] **SPKI pinning in the handshake**: pin the public-key hash (not the whole certificate) with ≥ 2 fingerprints (current + backup) and validate it during TLS, not when the response headers arrive
- [ ] **Release build smoke test** with R8 + `--obfuscate` on real Android and iOS devices (the `jailbreak_root_detection` and `screen_protector` plugins may need rules in `proguard-rules.pro`)
- [ ] Decide whether attestation (Play Integrity / App Attest) is needed on top of root detection
- [ ] Review compatibility with `get_it` 9 and `cupertino_icons` 2 (major versions are available) using `fvm flutter pub outdated`

## Known limitations

- Pinning is evaluated when the response headers arrive (a `dio` limitation): the request has already been sent, although the response is discarded.
- Root/jailbreak detection can be bypassed; with `ROOT_POLICY=warn` a detection failure is ignored, and with `block` it is treated as an untrusted device.
- The biometric confirmation setting lives in `shared_preferences` and can be altered on a rooted device.
- Native integrations (biometrics, screen protection, root detection) are tested with *mocks*; they must be validated on real devices.
- No Android/iOS build has been verified in the development environment (no Android SDK or Xcode).
