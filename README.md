# Stark Showcase

Aplicación Flutter (Android e iOS) pensada como portafolio: demuestra Clean Architecture,
Stacked, GoRouter, formularios reactivos, seguridad en red y pruebas unitarias.
Identificador: `com.softstark.demo`. El backend es un mock de Dio hasta que exista una API real.

> Estado: **Fase 3** (autenticación de punta a punta sobre la capa core). Ver el plan completo en [`CLAUDE.md`](CLAUDE.md).

## Requisitos

- Flutter estable (probado con 3.47.7, Dart 3.13)
- Android: `minSdk 24` · iOS 15.0+

## Comandos

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # mocks y código generado
flutter gen-l10n                                           # textos localizados (ARB)
dart format .
flutter analyze
flutter test --coverage
```

Ejecutar con configuración de entorno (copia `config/dev.example.json` a `config/dev.json`;
los `config/*.json` reales están ignorados por git):

```bash
flutter run --dart-define-from-file=config/dev.json
```

## Arquitectura

```
lib/
├── app/        App, locator (GetIt) y router (GoRouter)
├── core/       tema (design tokens), config, servicios, seguridad, widgets
├── features/   <feature>/{data,domain,presentation}
└── l10n/       ARB (español por defecto + inglés)
test/           espeja lib/
```

Dependencias hacia adentro (`presentation → domain ← data`). Los ViewModels solo llaman a
casos de uso y navegan a través de `NavigationService`. Reglas completas en [`AGENTS.md`](AGENTS.md).

## Cómo cambiar el diseño (design tokens)

Todo el aspecto visual vive en `lib/core/theme/`. Los widgets nunca llevan colores, tamaños,
paddings ni radios literales: usan `context.colors`, `context.text` y `context.spacing`.

| Quiero cambiar… | Edito solo… |
|---|---|
| Paleta de colores (claro / oscuro) | `lib/core/theme/app_colors.dart` (`AppColors.light` y `AppColors.dark`) |
| Fuente | `AppTypography.fontFamily` en `app_typography.dart` + `fonts:` en `pubspec.yaml` (archivos en `assets/fonts/`) |
| Tamaños y pesos de texto | `AppTypography.build` en `app_typography.dart` |
| Escala de espacios, radios, elevaciones | `lib/core/theme/app_spacing.dart` |
| Cómo se aplican a los componentes de Material | `lib/core/theme/app_theme.dart` |

Notas:

- **Modo claro/oscuro**: automático según el sistema (`ThemeMode.system`).
- **Escalado de texto**: respeta el del sistema con un tope (`AppConstants.maxTextScaleFactor`).
- **Fuente**: Inter se empaqueta en `assets/fonts/inter/` (licencia OFL incluida); la app no descarga fuentes.
- **Nombre de la app**: `AppConstants.appName`, `appName` en `lib/l10n/app_*.arb`, `android/app/src/main/res/values/strings.xml` y `CFBundleDisplayName` en `ios/Runner/Info.plist`.

## Configuración por entorno

Claves (`--dart-define-from-file`): `ENV`, `API_BASE_URL`, `USE_MOCK_API`, `PINNING_ENABLED`,
`PINNING_SHA256`, `ROOT_POLICY` (`warn` | `block`). Plantillas en `config/*.example.json`.

- `USE_MOCK_API` se ignora en builds release.
- Pasar del mock a la API real solo requiere cambiar `API_BASE_URL`.
- Con `PINNING_ENABLED=true` y `PINNING_SHA256` vacío el cliente rechazará todo el tráfico (falla cerrado).

## Autenticación (feature `auth`)

Login y registro completos con `reactive_forms`, casos de uso (`Login`, `Register`, `Logout`,
`GetCurrentUser`), repositorio con datasources remoto (Dio) y local (almacenamiento seguro) y DTOs `freezed`.

- **Cuenta demo del mock**: `demo@starkshowcase.dev` / `Demo1234!` (solo existe en memoria con `USE_MOCK_API=true`).
- **Guard del router**: sin sesión solo se accede a `/login` y `/register`; con sesión, `/login` redirige al inicio.
  `SessionService` notifica al router y se desloguea solo cuando falla el refresh del token.
- **Sesión persistente**: al abrir la app se restaura el usuario guardado (tokens en Keystore/Keychain).
- **Pantallas sensibles**: login y registro activan `ScreenProtection` (con conteo de referencias).
- **Errores**: mensajes genéricos y localizados (credenciales incorrectas, correo ya registrado, sin conexión...).
- **Entrada**: validadores en los formularios y `InputSanitizer` en el repositorio (la contraseña nunca se modifica).

## Red y backend mock

`DioClientFactory` crea el cliente con este orden de interceptores: **HTTPS enforcer → auth → logging → mock**.

- **Auth**: añade el bearer; ante un 401 renueva el token **una sola vez** (varios 401 simultáneos comparten
  una única renovación) y reintenta. Si el refresh falla, borra los tokens y `SessionExpiredNotifier` avisa
  para volver al login.
- **Mock** (`MockApiInterceptor`): solo con `USE_MOCK_API=true` y nunca en release. Simula latencia y
  puede forzarse por petición con el header `x-mock-scenario`:

| Valor | Efecto |
|---|---|
| `server_error` | responde 500 |
| `offline` | falla como sin conexión |
| `unauthorized` | responde 401 siempre |
| `unauthorized_once` | responde 401 una vez; tras el refresh funciona |

  Las features registran sus endpoints con `MockRoute` mediante `setupLocator(mockRoutes: ...)`.
  Para pasar a la API real solo cambia `API_BASE_URL` (y `USE_MOCK_API=false`).
- **Errores**: los datasources convierten `DioException` con `DioExceptionMapper`; los repositorios los
  mapean a `Failure` (`FailureMapper`) y la UI muestra mensajes genéricos localizados.

## Seguridad

- **Almacenamiento**: tokens solo en `flutter_secure_storage` (`SecureTokenStorage`).
- **Transporte**: solo HTTPS (interceptor + `network_security_config` + ATS). Certificate pinning configurable
  (`PINNING_ENABLED`, `PINNING_SHA256` con huellas SHA-256 en base64 del certificado); activado sin huellas
  **rechaza todo el tráfico**. Limitación conocida: Dio valida el certificado al recibir las cabeceras, por lo
  que la petición ya se envió (la respuesta se descarta); se revisará en la Fase 5.
- **Integridad del dispositivo**: `ROOT_POLICY=warn|block` (root/jailbreak y depurador) aplicada por `IntegrityGate`.
  Si el plugin falla se trata como "sin problemas" para no bloquear la app.
- **Biometría** (`BiometricAuthenticator`, `local_auth`) y **protección de pantalla** (`ScreenProtection`:
  bloquea capturas en Android y difumina la vista previa del app switcher).
- **Entrada de usuario**: validadores reutilizables (`AppValidators`) con mensajes localizados y
  `InputSanitizer` antes de enviar al backend.
- **Logs**: `ConsoleAppLogger` redacta tokens/contraseñas y en release solo emite errores.
- **Android**: sin cleartext, `allowBackup=false`, R8 + `shrinkResources` en release. El release **no se firma**
  con claves de debug: define `android/key.properties` (ignorado por git) con `keyAlias`, `keyPassword`,
  `storeFile` y `storePassword`.
- **iOS**: App Transport Security sin excepciones.
- **Release**: `--obfuscate --split-debug-info=debug-info/<plataforma>` (ver `.claude/skills/deploy/`).
