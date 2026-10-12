# Checklist de release

Marca cada punto antes de publicar. Los comandos usan FVM (versión fijada en `.fvmrc`); sin FVM, quita el prefijo `fvm`.

## 1. Calidad (bloqueante)

- [ ] `fvm dart format --set-exit-if-changed .` no cambia nada
- [ ] `fvm flutter analyze` → *No issues found*
- [ ] `fvm flutter test --coverage` en verde; `domain/` y `presentation/viewmodels/` ≥ 80 %
- [ ] `fvm dart run build_runner build --delete-conflicting-outputs` no deja cambios sin commitear
- [ ] `fvm flutter pub outdated`: ningún paquete descontinuado; las actualizaciones pendientes están revisadas
- [ ] Sin `TODO`/`FIXME` sin dueño en `lib/`

## 2. Configuración por entorno

`config/prod.json` (ignorado por git; parte de `config/prod.example.json`):

- [ ] `ENV` = `prod`
- [ ] `API_BASE_URL` apunta a la API real y es `https://`
- [ ] `USE_MOCK_API` = `false` (en release se ignora de todos modos)
- [ ] `PINNING_ENABLED` = `true` y `PINNING_SHA256` con las huellas (base64 SHA-256 del certificado) **de producción y de respaldo**
- [ ] `ROOT_POLICY` = `block` (o `warn` si se decide permitirlo)
- [ ] `PROTECT_SCREENS` = `true` (solo `false` en builds de demostración)
- [ ] El archivo **no** está en git (`git check-ignore config/prod.json`)
- [ ] El build arranca: en release la app lanza un `StateError` si falta `ENV` (o no es `staging`/`prod`) y si `prod` no activa el pinning

> Pinning: la huella es la del certificado completo, así que cambia al renovarlo. Incluye siempre la del
> certificado siguiente antes de rotar, o la app dejará de conectar.

## 3. Identidad y permisos

- [ ] Nombre visible: `AppConstants.appName`, `lib/l10n/app_*.arb`, `android/app/src/main/res/values/strings.xml`, `ios/Runner/Info.plist`
- [ ] Iconos y *splash* definitivos (Android `mipmap-*`, iOS `AppIcon.appiconset`)
- [ ] Id `com.softstark.demo` (o el definitivo) coincide en Android e iOS
- [ ] `version` / build number incrementados en `pubspec.yaml`
- [ ] Permisos mínimos: Android solo `INTERNET` y `USE_BIOMETRIC`; iOS `NSFaceIDUsageDescription` redactado

## 4. Firma

- [ ] Android: `android/key.properties` (ignorado) con `keyAlias`, `keyPassword`, `storeFile`, `storePassword`; keystore guardado fuera del repo y con copia de seguridad
- [ ] El build release **no** usa claves de debug (sin `key.properties` el AAB sale sin firmar)
- [ ] iOS: equipo de firma y perfiles de aprovisionamiento configurados en Xcode o fastlane

## 5. Build

```bash
fvm flutter build appbundle --release --obfuscate \
  --split-debug-info=debug-info/android --dart-define-from-file=config/prod.json
fvm flutter build ipa --release --obfuscate \
  --split-debug-info=debug-info/ios --dart-define-from-file=config/prod.json
```

- [ ] R8 y reducción de recursos activos (ya configurado en `android/app/build.gradle.kts`)
- [ ] `debug-info/` archivado **fuera** del repo (sirve para simbolizar *crashes*)
- [ ] Probar en dispositivos reales: login, tareas, ajustes, biometría, captura de pantalla bloqueada, modo avión

## 6. Verificación de seguridad en el binario

- [ ] No hay HTTP en claro: `network_security_config.xml` sin dominios con `cleartextTrafficPermitted="true"`
- [ ] Con `PINNING_ENABLED=true` y un certificado distinto al pinneado la app **no** conecta
- [ ] En un dispositivo con root/jailbreak se aplica `ROOT_POLICY`
- [ ] Revisa los logs de un build release: no deben aparecer tokens ni datos personales
- [ ] La cuenta demo del mock (`demo@starkshowcase.dev`) **no** funciona contra la API real

## 7. Tiendas

- [ ] Política de privacidad y formulario de seguridad de datos (Play) / *App Privacy* (App Store)
- [ ] Capturas en ES y EN; descripción y notas de versión
- [ ] Subida **solo** tras confirmación explícita; etiqueta `v<version>+<build>` tras publicar

## 8. Bloqueantes antes de producción con una API real

- [ ] **Pinning SPKI en el *handshake***: fijar el hash de la clave pública (no del certificado completo) con ≥ 2 huellas (actual + respaldo) y validarlo durante el TLS, no al recibir las cabeceras
- [ ] **Prueba de humo del build release** con R8 + `--obfuscate` en Android e iOS reales (los plugins `jailbreak_root_detection` y `screen_protector` pueden necesitar reglas en `proguard-rules.pro`)
- [ ] Decidir si hace falta atestación (Play Integrity / App Attest) además de la detección de root
- [ ] Revisar la compatibilidad de `get_it` 9 y `cupertino_icons` 2 (hay versiones mayores disponibles) con `fvm flutter pub outdated`

## Limitaciones conocidas

- El pinning se evalúa cuando llegan las cabeceras de respuesta (limitación de `dio`): la petición ya se envió, aunque la respuesta se descarta.
- La detección de root/jailbreak es evitable; con `ROOT_POLICY=warn` un fallo de la detección se ignora y con `block` se trata como dispositivo no confiable.
- El ajuste de confirmación biométrica vive en `shared_preferences` y puede alterarse en un dispositivo con root.
- Las integraciones nativas (biometría, protección de pantalla, detección de root) están probadas con *mocks*; hay que validarlas en dispositivos reales.
- No hay build de Android/iOS verificado en el entorno de desarrollo (sin Android SDK ni Xcode).
