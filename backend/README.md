# Stark Showcase Backend

[English](README.md) · [Español](README.es.md)

Mock-data backend for the **Stark Showcase** Flutter app. It implements exactly the endpoints the
app consumes, with realistic seed data, JWT authentication with refresh-token rotation, per-user
tasks, error/latency simulation for testing the app, and OpenAPI documentation. Data lives in
memory (no database needed) behind repository interfaces, so a real database can replace it later.

- Node.js 22 LTS, strict TypeScript, Express 5, zod
- Domain-driven design with two bounded contexts (`auth`, `tasks`)
- 274 tests (vitest + supertest), ~98 % line coverage, `npm audit` clean
- The single source of truth for the API is [`docs/api-contract.md`](docs/api-contract.md)
  (in Spanish), extracted from the Flutter app's own models and mock backends.

## Contents

1. [Quick start](#quick-start)
2. [Test accounts](#test-accounts)
3. [Endpoints](#endpoints)
4. [Sign-up and the confirmation code](#sign-up-and-the-confirmation-code)
5. [Connecting the Flutter app](#connecting-the-flutter-app)
6. [Run locally and expose it over HTTPS](#run-locally-and-expose-it-over-https)
7. [Deploy for free on Render](#deploy-for-free-on-render)
8. [Alternatives: Koyeb and Fly.io](#alternatives-koyeb-and-flyio)
9. [Configuration reference](#configuration-reference)
10. [Testing the app with simulated scenarios](#testing-the-app-with-simulated-scenarios)
11. [Security notes](#security-notes)
12. [Architecture](#architecture)
13. [Scripts](#scripts)
14. [Troubleshooting](#troubleshooting)

## Quick start

Requires Node.js 22 or newer.

```bash
cd backend
npm ci
cp .env.example .env       # PowerShell: Copy-Item .env.example .env
# Generate a secret and paste it as JWT_ACCESS_SECRET in .env:
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"
npm run dev
```

The server listens on **http://localhost:5556** (override with `PORT`).

- Health: <http://localhost:5556/health>
- Interactive docs (Swagger UI): <http://localhost:5556/docs>
- OpenAPI document: <http://localhost:5556/openapi.json>

> `.env` is ignored by git; `.env.example` is the committed template and never holds real secrets.

## Test accounts

| User      | E-mail                   | Username | Password    | Seed data                       |
| --------- | ------------------------ | -------- | ----------- | ------------------------------- |
| Demo User | `demo@starkshowcase.dev` | `demo`   | `Demo1234!` | 23 tasks (`task-0` … `task-22`) |
| Ana Gómez | `ana@starkshowcase.dev`  | `ana`    | `Ana12345!` | 5 tasks (`task-23` … `task-27`) |

New accounts start with no tasks. Every user only sees and
changes their own tasks (someone else's task id answers `404`, exactly like a missing one).

These are fixtures, not secrets. They are re-created on every start and by `POST /__reset`.

## Endpoints

| Method | Path                       | Auth   | Purpose                                                              |
| ------ | -------------------------- | ------ | -------------------------------------------------------------------- |
| GET    | `/health`                  | no     | Liveness probe (`{"status":"ok"}`)                                   |
| POST   | `/auth/login`              | no     | E-mail + password → user and token pair                              |
| POST   | `/auth/signup/email`       | no     | Sign-up step 1: send the confirmation code → `204`                   |
| POST   | `/auth/signup/code/resend` | no     | Send the code again (30 s between sends) → `204`                     |
| POST   | `/auth/signup/verify`      | no     | Step 2: e-mail + code → `verificationToken`                          |
| GET    | `/auth/username-available` | no     | `?username=` → `{ "available": true }`                               |
| POST   | `/auth/register`           | no     | Step 3: `verificationToken`, name, username, password → `201`        |
| POST   | `/auth/refresh`            | no     | Rotate the refresh token → new token pair                            |
| POST   | `/auth/logout`             | no     | Revoke the session (idempotent `204`). Called by the app on sign-out |
| PUT    | `/users/me/avatar`         | bearer | Replace your profile picture (raw JPEG, ≤ 200 KB) → `204`            |
| GET    | `/users/me/avatar`         | bearer | Download your own picture (`image/jpeg`)                             |
| GET    | `/tasks`                   | bearer | List with `page`, `pageSize`, `q`, `status`, `priority`              |
| POST   | `/tasks`                   | bearer | Create → `201`                                                       |
| GET    | `/tasks/stats`             | bearer | `total`, `done`, `overdue`, `highPriorityPending`                    |
| GET    | `/tasks/:id`               | bearer | One task                                                             |
| PUT    | `/tasks/:id`               | bearer | Replace a task                                                       |
| DELETE | `/tasks/:id`               | bearer | Delete → `204`                                                       |
| POST   | `/__reset`                 | no     | Restore seed data. **Not available in production**                   |

Every error has the same body: `{ "code": "...", "message": "...", "details": [...]? }`. The Flutter
app only reads `code`. Common codes: `invalid_credentials`, `email_taken`, `validation_error`,
`unauthorized`, `token_expired`, `invalid_refresh_token`, `not_found`, `rate_limited`,
`internal_error`.

Access tokens last 15 minutes; refresh tokens 30 days and work once (rotation). Presenting a used
refresh token revokes the whole session as a theft precaution.

## Sign-up and the confirmation code

Creating an account has three steps: `POST /auth/signup/email` sends a 6-digit code,
`POST /auth/signup/verify` exchanges e-mail + code for a single-use `verificationToken`, and
`POST /auth/register` creates the account from that token (the e-mail comes from the token, never
from the body). Codes last 10 minutes, are discarded after 5 wrong guesses and can be re-sent
every 30 seconds.

This backend **sends no e-mail**. Every address accepts the same code, `FIXED_CONFIRMATION_CODE`:

- Outside production it defaults to `123456`.
- In production it exists **only if you set it on purpose** (`render.yaml` declares it with a demo
  value). Without it codes are random and nobody can register. When it is set in production the
  server logs a startup warning (never the code itself).
- Sending real e-mails is a future improvement: implement the `ConfirmationCodeSender` port and
  nothing else changes.

> **Public instance warning.** While a fixed code is configured, anyone who knows it (it is in this
> README) can register on your public instance. Data lives in memory and disappears on restart.
> `POST /__reset` is never available in production.

## Connecting the Flutter app

The app builds its HTTP client from `API_BASE_URL`; switching to this backend only needs the
base URL (no path prefix) and the mock turned off.

| `--dart-define` | Value for this backend                                          |
| --------------- | --------------------------------------------------------------- |
| `API_BASE_URL`  | `https://<your-host>` (no trailing slash, no `/api`)            |
| `USE_MOCK_API`  | `false` (the in-app mock must be off)                           |
| `ENV`           | `dev` while developing; release builds need `staging` or `prod` |

From the Flutter project root:

```bash
fvm flutter run \
  --dart-define=API_BASE_URL=https://abc-123.trycloudflare.com \
  --dart-define=USE_MOCK_API=false
```

Or put the same keys in your `config/dev.json` and keep using
`--dart-define-from-file=config/dev.json`.

Things worth knowing:

- **HTTPS everywhere, with one debug-only exception.** The app's `HttpsEnforcerInterceptor` rejects
  `http://`, and Android blocks cleartext traffic. **Debug builds** make an exception for exactly
  three hosts: `10.0.2.2` (Android emulator → your machine), `localhost` and `127.0.0.1`. So on the
  emulator `--dart-define=API_BASE_URL=http://10.0.2.2:5556` works with `npm run dev`. Profile and
  release builds, any other host (for example a LAN IP such as `http://192.168.1.20:5556`) and iOS
  still require HTTPS: use the tunnel below. For a physical Android phone over USB run
  `adb reverse tcp:5556 tcp:5556` and use `http://localhost:5556`.
- **Release builds** refuse to start without `ENV=staging` or `ENV=prod`, and `prod` additionally
  requires `PINNING_ENABLED=true` with the server certificate fingerprint in `PINNING_SHA256`.
  Render certificates rotate, so for demo builds against Render use `ENV=staging`.
- The app's timeouts are 15 s to connect and 30 s to receive. A free Render service that is asleep
  can take longer to wake up: open `/health` in a browser first (see below).

## Run locally and expose it over HTTPS

### Local only

`npm run dev` restarts on every change. For a production-like run:

```bash
npm run build
NODE_ENV=staging JWT_ACCESS_SECRET=... npm start      # PowerShell: $env:NODE_ENV="staging"; ...
```

Reachable addresses over HTTP (the app accepts only the ones marked ✅, in debug builds):

| Client                       | URL                         |
| ---------------------------- | --------------------------- |
| Same machine                 | `http://localhost:5556`     |
| Android emulator             | `http://10.0.2.2:5556`      |
| iOS simulator                | `http://localhost:5556`     |
| Physical device (same Wi-Fi) | `http://<your-LAN-IP>:5556` |

### Free HTTPS tunnel with cloudflared (recommended for the app)

A tunnel gives your local server a public HTTPS URL, so the app (emulator or real phone) can use
it with no code changes.

1. Install: `winget install --id Cloudflare.cloudflared` (Windows), `brew install cloudflared`
   (macOS) or the package from <https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/>.
2. Start the backend with `TRUST_PROXY=true` in `.env` (the tunnel is a proxy; otherwise the rate
   limiter sees every client as one IP).
3. In another terminal: `cloudflared tunnel --url http://localhost:5556`
4. Copy the `https://<random>.trycloudflare.com` URL it prints and use it as `API_BASE_URL`.

The URL changes every time you restart the tunnel, and anyone who knows it can reach your local
server while it runs. `ngrok http 5556` works the same way (free account required).

## Deploy for free on Render

[`render.yaml`](../render.yaml) at the repository root describes the service (it is a Blueprint;
Render only reads it from the root). It builds from `backend/` with `rootDir`, uses the free plan,
checks `/health`, generates `JWT_ACCESS_SECRET` for you and sets `TRUST_PROXY=true`.

1. Push the repository to GitHub.
2. Sign up at <https://render.com> (GitHub login works); the free plan does not normally ask for a card.
3. **New + → Blueprint**, pick the repository and branch, then **Apply**.
4. Wait for the first deploy, then open `https://stark-showcase-backend.onrender.com/health`
   (your service name may get a suffix; the real URL is shown in the dashboard).
5. Use that URL as `API_BASE_URL` in the Flutter app.

Without the Blueprint: **New + → Web Service**, root directory `backend`, runtime Node, build
command `npm ci --include=dev && npm run build`, start command `npm start`, health check path
`/health`, and set the variables below.

`PORT` is injected by Render and read from the environment; do not set it.

### Free plan limitations

- The service **sleeps after ~15 minutes without traffic**; the first request afterwards takes
  roughly 30–60 s while it wakes up. Open `/health` before demos.
- Memory is wiped on every sleep/restart/deploy: users and tasks return to the seed data.
- A monthly cap of free instance hours and shared CPU. Fine for a portfolio, not for production.
  Plans and requirements change: check the platform's current terms.

### Production variables

| Variable                  | Value on Render            | Notes                                               |
| ------------------------- | -------------------------- | --------------------------------------------------- |
| `NODE_ENV`                | `production`               | Disables `/__reset` and every `X-Mock-*` header     |
| `JWT_ACCESS_SECRET`       | generated by the Blueprint | ≥ 32 chars, never in the repository                 |
| `TRUST_PROXY`             | `true`                     | Needed for correct per-IP rate limiting             |
| `LOG_LEVEL`               | `info`                     |                                                     |
| `CORS_ALLOWED_ORIGINS`    | empty                      | Only needed for browser clients                     |
| `MOCK_SIMULATION_ENABLED` | unset                      | The server refuses to start if `true` in production |

### Production or staging?

`NODE_ENV=production` is the safe default: no simulation, no reset. If you want to demo the error
scenarios or reset the data from the public URL, set `NODE_ENV=staging` — but then **anyone who
knows the URL can call `POST /__reset` and the `X-Mock-*` headers**. Treat a staging instance as
disposable and do not share the URL widely.

## Alternatives: Koyeb and Fly.io

If you cannot sign up for Render, the `Dockerfile` (multi-stage, non-root, `/health` healthcheck)
works anywhere. These steps follow each platform's standard flow and have not been run from this
repository.

**Koyeb** (free web service): _Create service → GitHub_, pick the repository, builder
**Dockerfile**, set the Dockerfile location to `backend/Dockerfile` and the work directory to
`backend`, expose the port from `PORT` (Koyeb injects it; the server reads it), health check path
`/health`, and add the environment variables above (`NODE_ENV`, `TRUST_PROXY=true`,
`JWT_ACCESS_SECRET` as a secret).

**Fly.io**:

```bash
cd backend
fly launch --no-deploy            # detects the Dockerfile; accept or edit fly.toml
fly secrets set JWT_ACCESS_SECRET="$(node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))")"
fly deploy
```

In the generated `fly.toml` set `internal_port` to the port the container uses (5556 by default, or
set the `PORT` variable), add `[env] NODE_ENV = "production"` and `TRUST_PROXY = "true"`, and an
HTTP check on `/health`. Fly asks for a payment method even on its free allowance.

Any container host works the same way: build `backend/Dockerfile`, inject `PORT`,
`JWT_ACCESS_SECRET`, `NODE_ENV`, `TRUST_PROXY=true`.

## Configuration reference

All settings are environment variables, validated with zod at startup (the server exits with a
clear message, never printing values, if something is wrong).

| Variable                    | Default                     | Description                                                                     |
| --------------------------- | --------------------------- | ------------------------------------------------------------------------------- |
| `NODE_ENV`                  | `development`               | `development`, `test`, `staging` or `production`                                |
| `PORT`                      | `5556`                      | Listening port (platforms inject it)                                            |
| `LOG_LEVEL`                 | `info`                      | `fatal` … `trace`, or `silent`                                                  |
| `JWT_ACCESS_SECRET`         | **required**                | ≥ 32 characters                                                                 |
| `ACCESS_TOKEN_TTL_SECONDS`  | `900`                       | Access token lifetime                                                           |
| `REFRESH_TOKEN_TTL_SECONDS` | `2592000`                   | Refresh token lifetime (30 days)                                                |
| `CORS_ALLOWED_ORIGINS`      | empty                       | Comma-separated browser origins; empty = none (native apps need none)           |
| `BODY_LIMIT`                | `10kb`                      | Maximum JSON body (`10kb`, `1mb`…)                                              |
| `TRUST_PROXY`               | `false`                     | `true` behind Render, Fly, Koyeb or a tunnel                                    |
| `MOCK_SIMULATION_ENABLED`   | `true` outside production   | Enables the `X-Mock-*` headers                                                  |
| `FIXED_CONFIRMATION_CODE`   | `123456` outside production | 6-digit code every e-mail accepts at sign-up (see below)                        |
| `RATE_LIMIT_WINDOW_SECONDS` | `60`                        | Rate-limit window                                                               |
| `RATE_LIMIT_MAX`            | `300`                       | Requests per IP and window (all routes except `/health`, `/docs`)               |
| `RATE_LIMIT_AUTH_MAX`       | `10`                        | Login, register and sign-up (send / resend / verify) attempts per IP and window |
| `RATE_LIMIT_REFRESH_MAX`    | `20`                        | Refresh attempts per IP and window                                              |

## Testing the app with simulated scenarios

Available when `NODE_ENV` is not `production` (ignored there). They apply to `/auth/*`, `/users/*` and `/tasks/*`.

| Header                     | Effect                                                                                                                      |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `X-Mock-Latency: 1500`     | Delay the response by that many milliseconds (max 60 000)                                                                   |
| `X-Mock-Error: 500`        | Force `500`, `401`, `403`, `404` or `422` with the uniform error body                                                       |
| `X-Mock-Error: timeout`    | Hold the connection past the app's 30 s receive timeout, then drop it                                                       |
| `X-Mock-Error: 401-once`   | `/tasks` only: the first request with a login-issued token gets `401 token_expired`; after the app refreshes, requests pass |
| `x-mock-scenario: <value>` | The app's own header: `server_error`=500, `offline`=timeout, `unauthorized`=401, `unauthorized_once`=401-once               |

`X-Mock-Error` wins over `x-mock-scenario`. Besides the headers, real expiry works too: set
`ACCESS_TOKEN_TTL_SECONDS=10` to see the app refresh by itself.

```bash
curl -H "Authorization: Bearer $TOKEN" -H "X-Mock-Error: 401-once" https://<host>/tasks   # 401
curl -H "Authorization: Bearer $TOKEN" -H "X-Mock-Error: 401-once" https://<host>/tasks   # 200
curl -X POST https://<host>/__reset                                                         # 204
```

## Security notes

- `helmet`, a CORS allow-list (closed by default), strict body size limit, strict input validation
  (unknown fields are rejected) and generic error bodies: no stack traces or internals.
- Passwords hashed with argon2id; login does the same work for unknown e-mails and answers
  identically, so accounts cannot be enumerated.
- JWT secret only from the environment. Refresh tokens are random, stored only as SHA-256 hashes,
  rotated on every use, revoked on logout, with reuse detection.
- Rate limiting per IP, stricter on login, register, sign-up and refresh.
- Sign-up codes expire after 10 minutes, are discarded after 5 wrong guesses and are stored only as
  hashes; the verification token is single-use. Avatars are validated by their bytes (JPEG only,
  ≤ 200 KB) and served only to their owner with `nosniff`.
- Logs (pino) redact passwords, tokens, sign-up codes and the `Authorization` header; request logs contain only
  method, path, status and timing (never query strings or bodies).
- `Cache-Control: no-store` on `/auth/*`. `npm audit` is part of CI.
- Remember this is a **mock-data** backend: in-memory storage, public seed credentials. Do not put
  real personal data in it.

## Architecture

Domain-driven design with two bounded contexts and a thin shared kernel. Dependencies point
inwards (presentation → application → domain; infrastructure implements domain ports).

```
src/
├── app.ts               Express app, no listen (testable)
├── server.ts            Start-up, graceful shutdown
├── composition.ts       The only place that knows the concrete adapters
├── config/              Environment validated with zod
├── contexts/
│   ├── auth/            domain (ports) · application (use cases) · infrastructure · presentation/http
│   └── tasks/           domain · application · infrastructure (in memory) · presentation/http
├── docs/                OpenAPI generated from the zod schemas, Swagger UI
├── seed/                Seed users and tasks
└── shared/              Errors, clock, logger, HTTP middlewares (errors, rate limit, simulation…)
tests/                   Mirrors src/
docs/api-contract.md     API contract (source of truth)
```

To use a real database, implement `UserRepository`, `RefreshTokenRepository` and `TaskRepository`
and wire them in `composition.ts`; nothing else changes.

## Scripts

| Command                 | Purpose                               |
| ----------------------- | ------------------------------------- |
| `npm run dev`           | Development server with reload        |
| `npm run build`         | Compile to `dist/`                    |
| `npm start`             | Run the compiled server (production)  |
| `npm run lint`          | ESLint (strict, type-aware, no `any`) |
| `npm run typecheck`     | `tsc --noEmit`                        |
| `npm test`              | Run the tests                         |
| `npm run test:coverage` | Tests with coverage (≥ 80 % enforced) |
| `npm run format`        | Prettier                              |

GitHub Actions (`.github/workflows/backend-ci.yml`) runs lint, format check, typecheck, tests with
coverage, build and `npm audit` on every push or pull request that touches `backend/`.

### Docker

```bash
docker build -t stark-showcase-backend ./backend
docker run --rm -p 5556:5556 -e JWT_ACCESS_SECRET=<32+ chars> -e NODE_ENV=staging stark-showcase-backend
```

## Troubleshooting

| Symptom                                                | Cause and fix                                                                        |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------ |
| App shows a connection error against `http://10.0.2.2` | The app only accepts HTTPS. Use the tunnel or Render.                                |
| Server exits with `Invalid configuration`              | A variable is missing or wrong; the message names it (never its value).              |
| `429 rate_limited` right away behind a proxy           | `TRUST_PROXY` is not `true`, so all clients look like one IP.                        |
| Every request is `401 token_expired`                   | The device clock or `ACCESS_TOKEN_TTL_SECONDS` is too short; the app should refresh. |
| `POST /__reset` returns 404                            | `NODE_ENV=production`. Use `staging`.                                                |
| First request on Render takes a minute                 | The free service was asleep. Open `/health` first.                                   |
| Data disappeared                                       | Memory is wiped on restart or sleep; the seed data is restored.                      |
