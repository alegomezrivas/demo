# Stark Showcase Backend

[English](README.md) · [Español](README.es.md)

Backend con datos de prueba para la app Flutter **Stark Showcase**. Implementa exactamente los
endpoints que consume la app, con datos semilla realistas, autenticación JWT con rotación de refresh
tokens, tareas por usuario, simulación de errores y latencia para probar la app, y documentación
OpenAPI. Los datos viven en memoria (no hace falta base de datos) detrás de interfaces de
repositorio, así que más adelante se pueden cambiar por una base de datos real.

- Node.js 22 LTS, TypeScript estricto, Express 5, zod
- Diseño guiado por el dominio (DDD) con dos contextos delimitados (`auth`, `tasks`)
- 274 tests (vitest + supertest), ~98 % de cobertura de líneas, `npm audit` limpio
- La única fuente de verdad de la API es [`docs/api-contract.md`](docs/api-contract.md), extraído de
  los modelos y de los backends simulados de la propia app Flutter.

## Contenido

1. [Inicio rápido](#inicio-rápido)
2. [Cuentas de prueba](#cuentas-de-prueba)
3. [Endpoints](#endpoints)
4. [Conectar la app Flutter](#conectar-la-app-flutter)
5. [Ejecutar en local y exponerlo con HTTPS](#ejecutar-en-local-y-exponerlo-con-https)
6. [Desplegar gratis en Render](#desplegar-gratis-en-render)
7. [Alternativas: Koyeb y Fly.io](#alternativas-koyeb-y-flyio)
8. [Referencia de configuración](#referencia-de-configuración)
9. [Probar la app con escenarios simulados](#probar-la-app-con-escenarios-simulados)
10. [Notas de seguridad](#notas-de-seguridad)
11. [Arquitectura](#arquitectura)
12. [Scripts](#scripts)
13. [Solución de problemas](#solución-de-problemas)

## Inicio rápido

Requiere Node.js 22 o superior.

```bash
cd backend
npm ci
cp .env.example .env       # PowerShell: Copy-Item .env.example .env
# Genera un secreto y pégalo como JWT_ACCESS_SECRET en .env:
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"
npm run dev
```

El servidor escucha en **http://localhost:5556** (cámbialo con `PORT`).

- Salud: <http://localhost:5556/health>
- Documentación interactiva (Swagger UI): <http://localhost:5556/docs>
- Documento OpenAPI: <http://localhost:5556/openapi.json>

> `.env` está ignorado por git; `.env.example` es la plantilla versionada y nunca contiene secretos reales.

## Cuentas de prueba

| Usuario   | Correo                   | Contraseña  | Datos semilla                    |
| --------- | ------------------------ | ----------- | -------------------------------- |
| Demo User | `demo@starkshowcase.dev` | `Demo1234!` | 23 tareas (`task-0` … `task-22`) |
| Ana Gómez | `ana@starkshowcase.dev`  | `Ana12345!` | 5 tareas (`task-23` … `task-27`) |

Las cuentas nuevas creadas con `POST /auth/register` empiezan sin tareas. Cada usuario solo ve y
modifica las suyas (el id de una tarea ajena responde `404`, igual que uno inexistente).

Son datos de prueba, no secretos. Se recrean en cada arranque y con `POST /__reset`.

## Endpoints

| Método | Ruta             | Auth   | Para qué sirve                                                          |
| ------ | ---------------- | ------ | ----------------------------------------------------------------------- |
| GET    | `/health`        | no     | Comprobación de vida (`{"status":"ok"}`)                                |
| POST   | `/auth/login`    | no     | Correo + contraseña → usuario y par de tokens                           |
| POST   | `/auth/register` | no     | Crear cuenta → `201`, usuario y par de tokens                           |
| POST   | `/auth/refresh`  | no     | Rotar el refresh token → nuevo par de tokens                            |
| POST   | `/auth/logout`   | no     | Revocar la sesión (`204` idempotente). La app lo llama al cerrar sesión |
| GET    | `/tasks`         | bearer | Lista con `page`, `pageSize`, `q`, `status`, `priority`                 |
| POST   | `/tasks`         | bearer | Crear → `201`                                                           |
| GET    | `/tasks/stats`   | bearer | `total`, `done`, `overdue`, `highPriorityPending`                       |
| GET    | `/tasks/:id`     | bearer | Una tarea                                                               |
| PUT    | `/tasks/:id`     | bearer | Reemplazar una tarea                                                    |
| DELETE | `/tasks/:id`     | bearer | Borrar → `204`                                                          |
| POST   | `/__reset`       | no     | Restaurar los datos semilla. **No existe en producción**                |

Todos los errores tienen el mismo cuerpo: `{ "code": "...", "message": "...", "details": [...]? }`.
La app Flutter solo lee `code`. Códigos habituales: `invalid_credentials`, `email_taken`,
`validation_error`, `unauthorized`, `token_expired`, `invalid_refresh_token`, `not_found`,
`rate_limited`, `internal_error`.

Los access tokens duran 15 minutos y los refresh tokens 30 días y se usan una sola vez (rotación).
Presentar un refresh token ya usado revoca toda la sesión, como medida contra robo.

## Conectar la app Flutter

La app construye su cliente HTTP a partir de `API_BASE_URL`; para usar este backend solo hace falta
la URL base (sin prefijo de ruta) y desactivar el mock interno.

| `--dart-define` | Valor para este backend                                                  |
| --------------- | ------------------------------------------------------------------------ |
| `API_BASE_URL`  | `https://<tu-host>` (sin barra final y sin `/api`)                       |
| `USE_MOCK_API`  | `false` (el mock interno de la app debe estar apagado)                   |
| `ENV`           | `dev` mientras desarrollas; los builds release exigen `staging` o `prod` |

Desde la raíz del proyecto Flutter:

```bash
fvm flutter run \
  --dart-define=API_BASE_URL=https://abc-123.trycloudflare.com \
  --dart-define=USE_MOCK_API=false
```

O pon esas mismas claves en tu `config/dev.json` y sigue usando
`--dart-define-from-file=config/dev.json`.

Conviene saber:

- **HTTPS siempre, con una excepción solo para debug.** El `HttpsEnforcerInterceptor` de la app
  rechaza `http://` y Android bloquea el tráfico en claro. Los **builds debug** hacen una excepción
  para exactamente tres hosts: `10.0.2.2` (emulador Android → tu equipo), `localhost` y `127.0.0.1`.
  Así, en el emulador `--dart-define=API_BASE_URL=http://10.0.2.2:5556` funciona con `npm run dev`.
  Los builds profile y release, cualquier otro host (por ejemplo una IP de red local como
  `http://192.168.1.20:5556`) e iOS siguen exigiendo HTTPS: usa el túnel de abajo. Para un móvil
  Android físico por USB ejecuta `adb reverse tcp:5556 tcp:5556` y usa `http://localhost:5556`.
- **Los builds release** no arrancan sin `ENV=staging` o `ENV=prod`, y `prod` además exige
  `PINNING_ENABLED=true` con la huella del certificado del servidor en `PINNING_SHA256`. Los
  certificados de Render rotan, así que para builds de demo contra Render usa `ENV=staging`.
- Los timeouts de la app son 15 s para conectar y 30 s para recibir. Un servicio gratuito de Render
  dormido puede tardar más en despertar: abre antes `/health` en el navegador (ver más abajo).

## Ejecutar en local y exponerlo con HTTPS

### Solo local

`npm run dev` se reinicia en cada cambio. Para una ejecución parecida a producción:

```bash
npm run build
NODE_ENV=staging JWT_ACCESS_SECRET=... npm start      # PowerShell: $env:NODE_ENV="staging"; ...
```

Direcciones alcanzables por HTTP (la app solo acepta las marcadas con ✅, en builds debug):

| Cliente                                | URL                                                                                |
| -------------------------------------- | ---------------------------------------------------------------------------------- |
| Mismo equipo (ejecución de escritorio) | `http://localhost:5556` ✅                                                         |
| Emulador Android                       | `http://10.0.2.2:5556` ✅                                                          |
| Simulador iOS                          | `http://localhost:5556`                                                            |
| Dispositivo físico (misma Wi-Fi)       | `http://<IP-de-tu-red-local>:5556` (solo navegador/curl; la app necesita el túnel) |

### Túnel HTTPS gratuito con cloudflared (recomendado para la app)

Un túnel da a tu servidor local una URL pública con HTTPS, de modo que la app (emulador o móvil
real) puede usarlo sin cambiar código.

1. Instala: `winget install --id Cloudflare.cloudflared` (Windows), `brew install cloudflared`
   (macOS) o el paquete de <https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/>.
2. Arranca el backend con `TRUST_PROXY=true` en `.env` (el túnel es un proxy; si no, el limitador de
   peticiones ve a todos los clientes como una sola IP).
3. En otra terminal: `cloudflared tunnel --url http://localhost:5556`
4. Copia la URL `https://<aleatorio>.trycloudflare.com` que imprime y úsala como `API_BASE_URL`.

La URL cambia cada vez que reinicias el túnel, y cualquiera que la conozca puede llegar a tu
servidor local mientras esté activo. `ngrok http 5556` funciona igual (requiere cuenta gratuita).

## Desplegar gratis en Render

[`render.yaml`](../render.yaml), en la raíz del repositorio, describe el servicio (es un Blueprint;
Render solo lo lee desde la raíz). Compila desde `backend/` con `rootDir`, usa el plan gratuito,
comprueba `/health`, genera `JWT_ACCESS_SECRET` por ti y pone `TRUST_PROXY=true`.

1. Sube el repositorio a GitHub.
2. Regístrate en <https://render.com> (vale el acceso con GitHub); el plan gratuito no suele pedir tarjeta.
3. **New + → Blueprint**, elige el repositorio y la rama y pulsa **Apply**.
4. Espera al primer despliegue y abre `https://stark-showcase-backend.onrender.com/health`
   (el nombre puede llevar un sufijo; la URL real aparece en el panel).
5. Usa esa URL como `API_BASE_URL` en la app Flutter.

Sin Blueprint: **New + → Web Service**, directorio raíz `backend`, entorno Node, comando de build
`npm ci --include=dev && npm run build`, comando de inicio `npm start`, ruta de health check
`/health`, y define las variables de abajo.

`PORT` lo inyecta Render y el servidor lo lee del entorno; no lo definas.

### Limitaciones del plan gratuito

- El servicio **se duerme tras ~15 minutos sin tráfico**; la primera petición después tarda del
  orden de 30–60 s mientras despierta. Abre `/health` antes de las demos.
- La memoria se borra en cada reposo, reinicio o despliegue: usuarios y tareas vuelven a la semilla.
- Hay un límite mensual de horas de instancia y CPU compartida. Sirve para un portfolio, no para
  producción. Los planes y requisitos cambian: revisa las condiciones actuales de la plataforma.

### Variables de producción

| Variable                  | Valor en Render           | Notas                                               |
| ------------------------- | ------------------------- | --------------------------------------------------- |
| `NODE_ENV`                | `production`              | Desactiva `/__reset` y todos los headers `X-Mock-*` |
| `JWT_ACCESS_SECRET`       | generado por el Blueprint | ≥ 32 caracteres, nunca en el repositorio            |
| `TRUST_PROXY`             | `true`                    | Necesario para limitar bien por IP                  |
| `LOG_LEVEL`               | `info`                    |                                                     |
| `CORS_ALLOWED_ORIGINS`    | vacío                     | Solo para clientes de navegador                     |
| `MOCK_SIMULATION_ENABLED` | sin definir               | El servidor no arranca si es `true` en producción   |

### ¿Producción o staging?

`NODE_ENV=production` es la opción segura: sin simulación y sin reset. Si quieres enseñar los
escenarios de error o restaurar los datos desde la URL pública, usa `NODE_ENV=staging`, pero
entonces **cualquiera que conozca la URL puede llamar a `POST /__reset` y usar los headers
`X-Mock-*`**. Trata una instancia de staging como desechable y no compartas la URL.

## Alternativas: Koyeb y Fly.io

Si no puedes registrarte en Render, el `Dockerfile` (multi-stage, usuario no root, healthcheck en
`/health`) funciona en cualquier sitio. Estos pasos siguen el flujo estándar de cada plataforma y no
se han ejecutado desde este repositorio.

**Koyeb** (servicio web gratuito): _Create service → GitHub_, elige el repositorio, constructor
**Dockerfile**, ubicación del Dockerfile `backend/Dockerfile` y directorio de trabajo `backend`,
expón el puerto de `PORT` (Koyeb lo inyecta y el servidor lo lee), ruta de health check `/health`
y añade las variables de arriba (`NODE_ENV`, `TRUST_PROXY=true`, `JWT_ACCESS_SECRET` como secreto).

**Fly.io**:

```bash
cd backend
fly launch --no-deploy            # detecta el Dockerfile; acepta o edita fly.toml
fly secrets set JWT_ACCESS_SECRET="$(node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))")"
fly deploy
```

En el `fly.toml` generado pon `internal_port` con el puerto del contenedor (5556 por defecto, o
define la variable `PORT`), añade `[env] NODE_ENV = "production"` y `TRUST_PROXY = "true"`, y un
chequeo HTTP en `/health`. Fly pide un método de pago incluso para su capa gratuita.

Cualquier host de contenedores sirve igual: construye `backend/Dockerfile` e inyecta `PORT`,
`JWT_ACCESS_SECRET`, `NODE_ENV` y `TRUST_PROXY=true`.

## Referencia de configuración

Todo se configura con variables de entorno, validadas con zod al arrancar (si algo falla, el
servidor termina con un mensaje claro que nunca imprime valores).

| Variable                    | Por defecto                | Descripción                                                            |
| --------------------------- | -------------------------- | ---------------------------------------------------------------------- |
| `NODE_ENV`                  | `development`              | `development`, `test`, `staging` o `production`                        |
| `PORT`                      | `5556`                     | Puerto de escucha (las plataformas lo inyectan)                        |
| `LOG_LEVEL`                 | `info`                     | `fatal` … `trace`, o `silent`                                          |
| `JWT_ACCESS_SECRET`         | **obligatoria**            | ≥ 32 caracteres                                                        |
| `ACCESS_TOKEN_TTL_SECONDS`  | `900`                      | Vida del access token                                                  |
| `REFRESH_TOKEN_TTL_SECONDS` | `2592000`                  | Vida del refresh token (30 días)                                       |
| `CORS_ALLOWED_ORIGINS`      | vacío                      | Orígenes de navegador separados por comas; vacío = ninguno             |
| `BODY_LIMIT`                | `10kb`                     | Tamaño máximo del JSON (`10kb`, `1mb`…)                                |
| `TRUST_PROXY`               | `false`                    | `true` detrás de Render, Fly, Koyeb o un túnel                         |
| `MOCK_SIMULATION_ENABLED`   | `true` fuera de producción | Activa los headers `X-Mock-*`                                          |
| `RATE_LIMIT_WINDOW_SECONDS` | `60`                       | Ventana del limitador                                                  |
| `RATE_LIMIT_MAX`            | `300`                      | Peticiones por IP y ventana (todas las rutas salvo `/health`, `/docs`) |
| `RATE_LIMIT_AUTH_MAX`       | `10`                       | Intentos de login + registro por IP y ventana                          |
| `RATE_LIMIT_REFRESH_MAX`    | `20`                       | Intentos de refresh por IP y ventana                                   |

## Probar la app con escenarios simulados

Disponibles cuando `NODE_ENV` no es `production` (allí se ignoran). Se aplican a `/auth/*` y `/tasks/*`.

| Header                     | Efecto                                                                                                                                        |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `X-Mock-Latency: 1500`     | Retrasa la respuesta esos milisegundos (máx. 60 000)                                                                                          |
| `X-Mock-Error: 500`        | Fuerza `500`, `401`, `403`, `404` o `422` con el cuerpo de error uniforme                                                                     |
| `X-Mock-Error: timeout`    | Mantiene la conexión más allá del timeout de 30 s de la app y la corta                                                                        |
| `X-Mock-Error: 401-once`   | Solo `/tasks`: la primera petición con un token emitido por login recibe `401 token_expired`; tras el refresh de la app, las peticiones pasan |
| `x-mock-scenario: <valor>` | El header de la propia app: `server_error`=500, `offline`=timeout, `unauthorized`=401, `unauthorized_once`=401-once                           |

`X-Mock-Error` tiene prioridad sobre `x-mock-scenario`. Además de los headers, la caducidad real
también funciona: pon `ACCESS_TOKEN_TTL_SECONDS=10` para ver cómo la app se refresca sola.

```bash
curl -H "Authorization: Bearer $TOKEN" -H "X-Mock-Error: 401-once" https://<host>/tasks   # 401
curl -H "Authorization: Bearer $TOKEN" -H "X-Mock-Error: 401-once" https://<host>/tasks   # 200
curl -X POST https://<host>/__reset                                                         # 204
```

## Notas de seguridad

- `helmet`, lista de orígenes CORS (cerrada por defecto), límite estricto del tamaño del body,
  validación estricta de entrada (los campos desconocidos se rechazan) y errores genéricos: sin
  trazas ni detalles internos.
- Contraseñas con argon2id; el login hace el mismo trabajo para correos desconocidos y responde igual,
  así que no se pueden enumerar cuentas.
- El secreto JWT solo viene del entorno. Los refresh tokens son aleatorios, se guardan solo como hash
  SHA-256, rotan en cada uso, se revocan al cerrar sesión y tienen detección de reutilización.
- Limitación de peticiones por IP, más estricta en login/registro y refresh.
- Los logs (pino) ocultan contraseñas, tokens y la cabecera `Authorization`; los logs de petición solo
  contienen método, ruta, estado y duración (nunca query strings ni bodies).
- `Cache-Control: no-store` en `/auth/*`. `npm audit` forma parte del CI.
- Recuerda que es un backend **con datos de prueba**: almacenamiento en memoria y credenciales semilla
  públicas. No guardes datos personales reales.

## Arquitectura

Diseño guiado por el dominio con dos contextos delimitados y un núcleo compartido mínimo. Las
dependencias apuntan hacia dentro (presentación → aplicación → dominio; la infraestructura implementa
los puertos del dominio).

```
src/
├── app.ts               App Express sin listen (testeable)
├── server.ts            Arranque y apagado ordenado
├── composition.ts       El único sitio que conoce los adaptadores concretos
├── config/              Entorno validado con zod
├── contexts/
│   ├── auth/            domain (puertos) · application (casos de uso) · infrastructure · presentation/http
│   └── tasks/           domain · application · infrastructure (en memoria) · presentation/http
├── docs/                OpenAPI generado desde los esquemas zod, Swagger UI
├── seed/                Usuarios y tareas semilla
└── shared/              Errores, reloj, logger, middlewares HTTP (errores, límites, simulación…)
tests/                   Espeja src/
docs/api-contract.md     Contrato de la API (fuente de verdad)
```

Para usar una base de datos real, implementa `UserRepository`, `RefreshTokenRepository` y
`TaskRepository` y cablea las implementaciones en `composition.ts`; nada más cambia.

## Scripts

| Comando                 | Para qué sirve                              |
| ----------------------- | ------------------------------------------- |
| `npm run dev`           | Servidor de desarrollo con recarga          |
| `npm run build`         | Compilar a `dist/`                          |
| `npm start`             | Ejecutar el servidor compilado (producción) |
| `npm run lint`          | ESLint (estricto, con tipos, sin `any`)     |
| `npm run typecheck`     | `tsc --noEmit`                              |
| `npm test`              | Ejecutar los tests                          |
| `npm run test:coverage` | Tests con cobertura (mínimo 80 % exigido)   |
| `npm run format`        | Prettier                                    |

GitHub Actions (`.github/workflows/backend-ci.yml`) ejecuta lint, comprobación de formato,
typecheck, tests con cobertura, build y `npm audit` en cada push o pull request que toque `backend/`.

### Docker

```bash
docker build -t stark-showcase-backend ./backend
docker run --rm -p 5556:5556 -e JWT_ACCESS_SECRET=<32+ caracteres> -e NODE_ENV=staging stark-showcase-backend
```

## Solución de problemas

| Síntoma                                              | Causa y solución                                                                                    |
| ---------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| La app da error de conexión contra `http://10.0.2.2` | La app solo acepta HTTPS. Usa el túnel o Render.                                                    |
| El servidor termina con `Invalid configuration`      | Falta una variable o es incorrecta; el mensaje la nombra (nunca su valor).                          |
| `429 rate_limited` enseguida detrás de un proxy      | `TRUST_PROXY` no es `true`, así que todos los clientes parecen una sola IP.                         |
| Todas las peticiones dan `401 token_expired`         | El reloj del dispositivo o `ACCESS_TOKEN_TTL_SECONDS` es demasiado corto; la app debería refrescar. |
| `POST /__reset` devuelve 404                         | `NODE_ENV=production`. Usa `staging`.                                                               |
| La primera petición en Render tarda un minuto        | El servicio gratuito estaba dormido. Abre `/health` antes.                                          |
| Los datos han desaparecido                           | La memoria se borra al reiniciar o dormir; se restauran los datos semilla.                          |
