# Stark Showcase

Aplicación Flutter (Android e iOS) pensada como portafolio: demuestra Clean Architecture,
Stacked, GoRouter, formularios reactivos, seguridad en red y pruebas unitarias.
Identificador: `com.softstark.demo`. El backend es un mock de Dio hasta que exista una API real.

> Estado: **Fase 1** (base del proyecto). Ver el plan completo en [`CLAUDE.md`](CLAUDE.md).

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

## Seguridad (base de la Fase 1)

- Android: `network_security_config.xml` sin tráfico cleartext, `allowBackup=false`, R8 + `shrinkResources` en release.
  El release **no se firma** con claves de debug: define `android/key.properties` (ignorado por git) con
  `keyAlias`, `keyPassword`, `storeFile` y `storePassword`.
- iOS: App Transport Security sin excepciones (`NSAllowsArbitraryLoads = false`).
- Builds de release: `--obfuscate --split-debug-info=debug-info/<plataforma>` (ver `.claude/skills/deploy/`).
