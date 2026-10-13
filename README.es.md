# Stark Showcase

[English](README.md) · **Español**

Aplicación Flutter (Android e iOS) pensada como portafolio: demuestra Clean Architecture,
Stacked, GoRouter, formularios reactivos, seguridad en red y pruebas unitarias.
Identificador: `com.softstark.demo`. El backend es un mock de Dio hasta que exista una API real.

> Estado: **Fase 5** (revisión final). Plan completo en [`CLAUDE.md`](CLAUDE.md); antes de publicar sigue
> el [checklist de release](docs/RELEASE_CHECKLIST.es.md).

## Requisitos

- [FVM](https://fvm.app) (la versión de Flutter está fijada en [`.fvmrc`](.fvmrc): **3.41.6**, Dart 3.11)
- Android: `minSdk 24` · iOS 15.0+

## Configurar el SDK con FVM

```bash
dart pub global activate fvm   # una sola vez
fvm install                    # descarga la versión indicada en .fvmrc
fvm flutter pub get
```

Todos los comandos del proyecto se ejecutan con el prefijo `fvm` (así todo el equipo y la CI usan el mismo SDK).
Para actualizar la versión: `fvm use <versión>` y commitea el nuevo `.fvmrc`. La carpeta `.fvm/` es local y está ignorada.

- **VS Code**: `.vscode/settings.json` ya apunta a `.fvm/flutter_sdk` (ejecuta `fvm use` una vez para crear el enlace).
- **Android Studio / IntelliJ**: *Settings → Languages & Frameworks → Flutter → Flutter SDK path* = `<proyecto>/.fvm/flutter_sdk`.

## Comandos

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs   # mocks y código generado
fvm flutter gen-l10n                                           # textos localizados (ARB)
fvm dart format .
fvm flutter analyze
fvm flutter test --coverage
```

Ejecutar con configuración de entorno (copia `config/dev.example.json` a `config/dev.json`;
los `config/*.json` reales están ignorados por git):

```bash
fvm flutter run --dart-define-from-file=config/dev.json
```

> Sin FVM también funciona cualquier Flutter 3.41.6 en el `PATH`: quita el prefijo `fvm`.

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
`PINNING_SHA256`, `ROOT_POLICY` (`warn` | `block`), `PROTECT_SCREENS`. Plantillas en `config/*.example.json`.

- `USE_MOCK_API` se ignora en builds release **y profile**, y los backends mock ni se construyen en release.
- Pasar del mock a la API real solo requiere cambiar `API_BASE_URL`.
- Con `PINNING_ENABLED=true` y `PINNING_SHA256` vacío el cliente rechazará todo el tráfico (falla cerrado).
- `PROTECT_SCREENS` (por defecto `true`) oculta toda la app autenticada de capturas y de la vista previa del
  selector de apps. Ponlo en `false` solo para builds de demostración en los que necesites capturas.
- **Un build release no arranca con configuración débil**: `ENV` debe ser `staging` o `prod` (si falta, la app
  lanza un `StateError` al iniciar), `prod` exige `PINNING_ENABLED=true` y un `ROOT_POLICY` desconocido se
  convierte en `block`.

## Autenticación (feature `auth`)

Login y un registro en varios pasos con `reactive_forms`, casos de uso (`Login`, `SendConfirmationCode`,
`VerifyConfirmationCode`, `CheckUsernameAvailability`, `CompleteSignUp`, `UploadAvatar`, `Logout`,
`GetCurrentUser`), repositorios con datasources remoto (Dio) y local (almacenamiento seguro) y DTOs `freezed`.
Las pantallas siguen los patrones de layout de un onboarding moderno (una pregunta por pantalla, botones en píldora,
código de seis casillas) usando solo los tokens de diseño, los textos y la ilustración propios de esta app.

**Flujo de registro** (`/welcome` → `/signup/…`): correo (con sugerencias de dominio) → código de 6 dígitos →
contraseña y «Recordar sesión» → nombre completo → nombre de usuario (comprobado mientras se escribe) → términos →
foto de perfil opcional → bienvenida. La cuenta se crea al aceptar los términos; el paso de la foto ya tiene sesión.

- **Un ViewModel para el flujo**: `SignUpFlowViewModel` guarda un `SignUpState` inmutable, un `FormGroup` por paso
  (`SignUpForms`) y solo llama a casos de uso. `SignUpProgress` + `AuthGuard` rechazan los enlaces que se saltan un
  paso y, una vez creada la cuenta, los pasos anteriores quedan cerrados.
- **Código por correo**: el backend no envía correos. El código es `FIXED_CONFIRMATION_CODE` (`123456` por defecto
  fuera de producción; el mock de la app usa el mismo). Los códigos caducan a los 10 minutos, se descartan tras 5
  fallos y se pueden volver a pedir cada 30 segundos (la pantalla cuenta atrás). Ver `backend/README.es.md`.
- **Recordar sesión**: marcado = tokens y usuario en `flutter_secure_storage`. Desmarcado = **solo en memoria**: no se
  escribe nada en disco, la sesión no se restaura al reabrir la app, los tokens renovados siguen en memoria y Ajustes
  no ofrece la confirmación biométrica (no hay sesión guardada que proteger). Cerrar sesión siempre limpia ambos.
- **Foto de perfil**: galería o cámara (los permisos se piden solo al usarlas, con un mensaje claro si se
  deniegan), recorte circular y recodificación fuera del hilo de la UI a un JPEG de ≤ 512 px y menos de 200 KB. Al
  recodificar se pierden los datos EXIF; se rechazan los orígenes de más de 15 MB o 16 megapíxeles antes de decodificar; el servidor vuelve a validar los bytes. Las fotos viven en la memoria del backend.
- **Qué se olvida y cuándo**: salir del flujo (atrás desde el primer paso, «Ya tengo cuenta») vacía los formularios,
  el token de verificación y la contraseña; también se descartan al crearse la cuenta. Cuando caduca una sesión se
  borra el perfil guardado junto con los tokens. Las respuestas que llegan después de volver atrás se ignoran.
- **Cuenta demo del mock**: `demo@starkshowcase.dev` / `Demo1234!`, usuario `demo` (solo existe en memoria con `USE_MOCK_API=true`).
- **Guard del router**: sin sesión solo se accede a las pantallas de autenticación (los visitantes aterrizan en
  `/welcome`); con sesión redirigen al inicio. `SessionService` notifica al router y se desloguea solo cuando falla
  el refresh del token.
- **Pantallas sensibles**: login y el paso de la contraseña activan `ScreenProtection` (con conteo de referencias).
- **Errores**: mensajes genéricos y localizados (credenciales incorrectas, código erróneo o caducado, correo o
  usuario ya usados, sin conexión...). Nunca se registran códigos, tokens ni contraseñas.
- **Entrada**: validadores en los formularios (`AuthRules` es la única fuente Dart pura de las reglas),
  `InputSanitizer` en los repositorios (la contraseña y el código nunca se modifican).
- **Accesibilidad y movimiento**: áreas de 48 dp, controles etiquetados, regiones *live* para los errores, tokens con
  contraste AA, claro/oscuro, 320×568 con texto 2× y teclado abierto (con tests). Las transiciones y animaciones de
  mensajes salen de `AppMotion` y desaparecen si el sistema pide reducir el movimiento.

## Funcionalidades

La app es un gestor de tareas con tres pestañas (barra de navegación inferior):

| Pestaña | Qué hace |
|---|---|
| **Inicio** (`dashboard`) | Saludo, % completado y estadísticas (total, completadas, vencidas, prioridad alta pendientes). Se recarga sola cuando cambian las tareas en otra pestaña. |
| **Tareas** (`tasks`) | Lista paginada (scroll infinito), búsqueda con *debounce*, filtros por estado y prioridad, completar con el checkbox (optimista, con rollback), borrar con confirmación, crear y editar en un formulario `reactive_forms`. |
| **Ajustes** (`settings`) | Perfil, tema (sistema/claro/oscuro), idioma (sistema/español/inglés), confirmación biométrica (solo con la sesión recordada) y cierre de sesión. |

- **Preferencias**: se guardan en `shared_preferences` (no son secretos) y se aplican al instante vía `AppPreferences`.
- **Confirmación biométrica** (opcional): al activarla se pide huella/rostro/PIN antes de **eliminar tareas** y **cerrar sesión**
  (`SensitiveActionGuard`). Cambiar la opción también exige confirmación. Si el dispositivo no puede autenticar
  (sin bloqueo de pantalla) no se bloquea al usuario.
- **Backend mock**: `MockTasksBackend` simula búsqueda, filtros, paginación, CRUD y estadísticas (23 tareas de ejemplo;
  responde 401 sin token). Prueba los fallos con el header `x-mock-scenario` (ver más abajo).
- **Nombre de la entidad**: `TaskItem` (no `Task`) para no chocar con el tipo `Task` de `fpdart`.

## Red y backend mock

`DioClientFactory` crea el cliente con este orden de interceptores: **HTTPS enforcer → auth → logging → mock**.

- **Auth**: añade el bearer; ante un 401 renueva el token **una sola vez** (varios 401 simultáneos comparten
  una única renovación) y reintenta. Si el servidor **rechaza** el refresh (401/403), borra los tokens y
  `SessionExpiredNotifier` avisa para volver al login. Si el refresh falla por red, timeout o error 5xx,
  la sesión **se conserva** y el usuario ve un error de conexión.
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
- **Transporte**: solo HTTPS (interceptor + `network_security_config` + ATS); la única excepción es HTTP plano a
  `10.0.2.2`, `localhost` y `127.0.0.1` en **builds debug** (backend de desarrollo en el emulador). Certificate pinning configurable
  (`PINNING_ENABLED`, `PINNING_SHA256` con huellas SHA-256 en base64 del certificado); activado sin huellas
  **rechaza todo el tráfico**. Ver *Limitaciones conocidas* más abajo.
- **Integridad del dispositivo**: `ROOT_POLICY=warn|block` (root/jailbreak y depurador) aplicada por `IntegrityGate`.
  Si la detección falla: con `warn` se ignora y con `block` el dispositivo se considera no confiable.
- **Biometría** (`BiometricAuthenticator`, `local_auth`) y **protección de pantalla** (`ScreenProtection`, con
  conteo de referencias): bloquea capturas en Android y difumina la vista previa del selector de apps en todo
  el shell autenticado (configurable con `PROTECT_SCREENS`).
- **Dependencias de los ViewModels**: casos de uso para la lógica de negocio, más servicios de `core`
  (`NavigationService`, `SessionService`, `AppPreferences`, `ScreenProtection`, `BiometricAuthenticator`,
  `SensitiveActionGuard`); nunca repositorios ni datasources.
- **Entrada de usuario**: validadores reutilizables (`AppValidators`) con mensajes localizados y
  `InputSanitizer` antes de enviar al backend.
- **Logs**: `ConsoleAppLogger` redacta tokens/contraseñas y en release solo emite errores.
- **Android**: sin cleartext, `allowBackup=false`, R8 + `shrinkResources` en release. El release **no se firma**
  con claves de debug: define `android/key.properties` (ignorado por git) con `keyAlias`, `keyPassword`,
  `storeFile` y `storePassword`.
- **iOS**: App Transport Security sin excepciones; Keychain con `first_unlock_this_device` (no se copia a otros
  dispositivos ni a copias de seguridad).
- **Release**: `--obfuscate --split-debug-info=debug-info/<plataforma>` (ver `.claude/skills/deploy/`).

## Integración continua

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) se ejecuta en cada *pull request*, en cada push a `master`
y a mano (*workflow_dispatch*). Usa la versión de Flutter de `.fvmrc`.

| Job | Qué comprueba |
|---|---|
| `verify` | `pub get`, que el código generado (`build_runner`, `gen-l10n`) esté al día, `dart format`, `flutter analyze`, `flutter test --coverage` y el umbral de cobertura (`tool/check_coverage.sh`: `domain/` y ViewModels ≥ 80 %). Sube `lcov.info` como artefacto. |
| `dependencies` | `flutter pub outdated` (informativo: nunca bloquea). |
| `android-release-build` | Compila un `appbundle` **sin firmar** con R8 y `--obfuscate` usando `config/prod.example.json`, para detectar pronto roturas de minificación. Sube los símbolos como artefacto. |
| `ios-release-build` | Solo en *push* a `master` y en ejecución manual (los PR no lo lanzan). En un runner **macOS**: `flutter build ios --release --no-codesign --obfuscate` con `config/prod.example.json`, para comprobar que el proyecto iOS, los Pods y la ofuscación compilan sin certificados. Sube los símbolos como artefacto. |

Los jobs de Android e iOS no se pudieron ejecutar en el entorno de desarrollo (sin Android SDK ni Xcode):

- Android: si falla la primera vez por reglas de R8 de algún plugin, añade las reglas `-keep` necesarias a
  `android/app/proguard-rules.pro`.
- iOS: no hay `ios/Podfile` versionado (Flutter lo genera en el build). Tras el primer build en un Mac, commitea
  `ios/Podfile` y `ios/Podfile.lock` para que los Pods sean reproducibles.
- Los runners macOS cuestan más minutos que los Linux: por eso el job de iOS no corre en los PR, solo tras fusionar en
  `master` o al lanzarlo a mano (*Actions → CI → Run workflow*), y siempre después de que `verify` pase.

Para reproducir el *gate* de cobertura en local: `fvm flutter test --coverage && tool/check_coverage.sh`.

## Limitaciones conocidas (revisión de la Fase 5)

- **Pinning**: Dio valida el certificado cuando llegan las cabeceras, así que la petición ya se envió (la respuesta se
  descarta), y se fija el hash del certificado completo, no el de su clave pública (SPKI). Antes de producción con una
  API real: fijar SPKI con al menos dos huellas (actual y de respaldo) y comprobarlo en el *handshake* TLS.
- **Detección de root/jailbreak**: es evitable por naturaleza (herramientas de *hooking*); es una defensa en profundidad,
  no una garantía. Para algo más fuerte hace falta atestación (Play Integrity / App Attest).
- **Ajuste de biometría** en `shared_preferences`: en un dispositivo con root puede modificarse; solo protege contra uso casual.
- **No se pudo compilar en Android/iOS** en el entorno de desarrollo (sin Android SDK ni Xcode): falta una prueba de
  humo de un build release con R8 y ofuscación (ver `docs/RELEASE_CHECKLIST.es.md`).
- Las pruebas de plugins nativos usan *mocks*: valídalas en dispositivos reales.
- **Registro con un backend público**: el código de confirmación es fijo y está documentado, así que cualquiera puede
  registrarse en una instancia pública; los datos viven en memoria (`backend/README.es.md`). Un proveedor real de
  correo es una mejora futura tras `ConfirmationCodeSender`.
- **Las pantallas de foto y registro** solo tienen tests de widgets y un backend mock: la cámara, el selector de la
  galería, los diálogos de permisos y el comportamiento del teclado hay que comprobarlos en dispositivos reales.
