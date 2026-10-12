# CLAUDE.md

@AGENTS.md

## Claude Code specifics

- Personal overrides go in `CLAUDE.local.md` (git-ignored).
- Path-scoped rules live in `.claude/rules/` (code-style, testing, api-conventions).
- Use the `code-reviewer` subagent after finishing a feature and `security-auditor`
  before any release. Use the `deploy` skill for builds and releases.
- A hook runs `dart format` after every `.dart` edit; another blocks dangerous Bash
  commands (`.claude/hooks/validate-bash.sh`).

## Workflow

1. Work phase by phase (see the delivery plan below); do not start a phase before the
   previous one is green.
2. After each phase run `dart format .`, `flutter analyze`, `flutter test`.
3. Commit with conventional commits and push to the designated branch. Do not open a
   pull request unless the user asks.
4. Never edit generated files (`*.g.dart`, `*.freezed.dart`); regenerate with
   `dart run build_runner build --delete-conflicting-outputs`.

## Delivery plan

| Phase | Scope |
|---|---|
| 0 | Claude Code structure, `.gitignore` |
| 1 | Base project, dependencies, locator, design tokens, router, NavigationService |
| 2 | Core: network, errors, security, with tests |
| 3 | Auth feature (login/register with reactive_forms), end to end, with tests |
| 4 | Tasks (CRUD, search, filters, pagination), Profile/Settings (theme, language, biometrics), Dashboard |
| 5 | Final review with subagents, README, release checklist |

## Product decisions already made

- Domain for the portfolio: **tasks**. Backend: Dio `MockInterceptor` simulating
  latency, 500 errors, no connection and 401 (to exercise token refresh). Enabled only
  via `--dart-define=USE_MOCK_API=true` in dev/staging, never in release. Switching to a
  real API must only require changing the base URL.
- Languages: Spanish (default) and English from day one.
- Font: Inter, bundled in assets (no runtime download). Defined only in `app_typography.dart`
  and `pubspec.yaml`.
- Palette: blue/teal, light and dark, defined only in `app_colors.dart`.
- Certificate pinning: implemented, configurable, disabled until a real API exists.
  If enabled with an empty fingerprint list it must fail closed (reject traffic). Tested both ways.
- Root/jailbreak policy: enum `SecurityPolicy { warn, block }` configured per environment.
  Default `warn`; `block` for production.

## Gotchas

- `pubspec.lock` is committed (this is an app); the generic `*.lock` ignore is overridden.
- Never read or print `config/*.json`, `.env*`, keystores or `google-services.json`.
- The Flutter version is pinned with FVM (`.fvmrc`); use `fvm flutter` / `fvm dart`. If neither
  `fvm` nor `flutter` is available, say so instead of
  pretending checks passed.
