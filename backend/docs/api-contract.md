# Contrato de la API — Stark Showcase

Fuente de verdad del backend. Extraído del código de la app Flutter (`lib/core/network`, `lib/features/*/data`, `lib/features/*/domain`) y de los backends simulados `MockAuthBackend` y `MockTasksBackend`, que ya definen el comportamiento que la app espera.

- Base URL: configurable en la app (`API_BASE_URL`, `--dart-define`). Todas las rutas de abajo son relativas a ella, sin prefijo `/api` ni `/v1`.
- Formato: JSON (`Accept: application/json`; los cuerpos con datos van en `application/json`).
- Fechas: ISO 8601 en UTC (`2026-10-13T09:30:00.000Z`).
- Los nombres de campo son `camelCase`.
- La app solo habla HTTPS (ver "Hallazgos" más abajo).
- Autenticación: `Authorization: Bearer <accessToken>`. La app trata los tokens como cadenas opacas (no decodifica el JWT).

## 1. Endpoints consumidos por la app

Settings, Dashboard y About no usan red: Settings es local (preferencias) y Dashboard usa `GET /tasks/stats`.

### Auth (sin bearer; la app marca estas peticiones con `skip_auth`)

#### `POST /auth/login`

Request:

```json
{ "email": "string", "password": "string" }
```

La app envía el email en minúsculas, recortado y limpio de HTML. La contraseña no se modifica.

| Status | Body                                | Cuándo                                                                  |
| ------ | ----------------------------------- | ----------------------------------------------------------------------- |
| 200    | `AuthResponse`                      | Credenciales correctas                                                  |
| 401    | `{ "code": "invalid_credentials" }` | Usuario inexistente o contraseña errónea (mismo mensaje en ambos casos) |
| 422    | `{ "code": "validation_error" }`    | Body inválido                                                           |

#### `POST /auth/register`

Request:

```json
{ "name": "string", "email": "string", "password": "string", "phone": "string | null" }
```

`phone` es opcional: la app lo omite o lo envía como `null` si está vacío; si existe llega solo con dígitos y un `+` inicial (7–15 dígitos). `name` llega recortado, máximo 100 caracteres.

| Status | Body                             | Cuándo                                                     |
| ------ | -------------------------------- | ---------------------------------------------------------- |
| 201    | `AuthResponse`                   | Cuenta creada                                              |
| 409    | `{ "code": "email_taken" }`      | Email ya registrado (la app muestra un mensaje específico) |
| 422    | `{ "code": "validation_error" }` | Campos obligatorios vacíos o inválidos                     |

#### `POST /auth/refresh`

Request: `{ "refreshToken": "string" }`

Response 200 (sin `user`):

```json
{ "accessToken": "string", "refreshToken": "string" }
```

Reglas que la app asume:

- Rotación: cada refresh devuelve un par nuevo y el refresh token anterior queda inválido.
- Refresh token inválido, usado o revocado: **401** (o 403) con `{ "code": "invalid_refresh_token" }`. Es lo único que cierra la sesión en la app.
- Un 5xx, un timeout o la falta de conexión en el refresh **no** cierran la sesión.

### Tasks (requieren bearer; sin token → 401 `{ "code": "unauthorized" }`)

La app llama a estos endpoints con el token y, ante un 401, intenta un refresh y reintenta una sola vez. Si el reintento vuelve a dar 401, expira la sesión.

#### `GET /tasks`

Query params (todos opcionales; la app solo envía `q`, `status` y `priority` cuando tienen valor):

| Param      | Tipo   | Valores / reglas                                                           |
| ---------- | ------ | -------------------------------------------------------------------------- |
| `page`     | int    | 1-based, por defecto 1                                                     |
| `pageSize` | int    | por defecto 10, máximo 100                                                 |
| `q`        | string | búsqueda sin distinguir mayúsculas en `title` y `description` (subcadena)  |
| `status`   | string | `pending` \| `done` (si falta, equivale a `all`; la app nunca envía `all`) |
| `priority` | string | `low` \| `medium` \| `high`                                                |

Orden: `createdAt` descendente. Una página fuera de rango devuelve `items: []` con el `total` real.

Response 200:

```json
{
  "items": [ Task ],
  "page": 1,
  "pageSize": 10,
  "total": 23
}
```

`page` y `pageSize` son los valores efectivos tras aplicar los límites. `total` cuenta los elementos que cumplen los filtros en todas las páginas.

#### `GET /tasks/stats`

Response 200:

```json
{ "total": 23, "done": 6, "overdue": 4, "highPriorityPending": 5 }
```

- `done`: tareas con `isDone = true`.
- `overdue`: tareas abiertas con `dueDate` anterior a "ahora".
- `highPriorityPending`: tareas abiertas con `priority = "high"`.
- Esta ruta debe resolverse antes que `/tasks/:id`.

#### `GET /tasks/:id`

200 → `Task`. 404 → `{ "code": "not_found" }`.

#### `POST /tasks`

Request (`TaskInput`):

```json
{
  "title": "string",
  "description": "string",
  "priority": "low | medium | high",
  "isDone": false,
  "dueDate": "ISO-8601 UTC | null"
}
```

Validación (la misma que el mock): `title` es string no vacío tras recortar y de máximo 120 caracteres; `description` es string obligatorio (puede ser `""`, máximo 1000); `priority` es uno de los tres valores; `isDone` es booleano; `dueDate` es opcional/nulo o una fecha ISO válida.

201 → `Task` (con `id` y `createdAt` asignados por el servidor). 422 → `{ "code": "validation_error" }`.

#### `PUT /tasks/:id`

Reemplazo completo con el mismo `TaskInput`. 200 → `Task`. 404 → `not_found`. 422 → `validation_error`. `id` y `createdAt` no cambian.

#### `DELETE /tasks/:id`

204 sin cuerpo. 404 → `{ "code": "not_found" }`.

## 2. Modelos

### `AuthResponse` (login y register)

```json
{
  "user": { "id": "string", "name": "string", "email": "string", "phone": "string | null" },
  "accessToken": "string",
  "refreshToken": "string"
}
```

`user.phone` se envía siempre; es `null` cuando no existe. No se devuelve nunca la contraseña ni su hash.

### `Task`

| Campo         | Tipo                          | Nulable                   |
| ------------- | ----------------------------- | ------------------------- |
| `id`          | string                        | no                        |
| `title`       | string                        | no                        |
| `description` | string                        | no (puede ser `""`)       |
| `priority`    | `"low" \| "medium" \| "high"` | no                        |
| `isDone`      | boolean                       | no                        |
| `createdAt`   | string ISO 8601 UTC           | no                        |
| `dueDate`     | string ISO 8601 UTC           | **sí** (`null` explícito) |

## 3. Errores

Qué lee la app: **solo** el campo `code` (string) del body de la respuesta. Si no existe usa `http_<status>`. Los textos que ve el usuario son genéricos y se resuelven en la app según la clase de fallo, así que el backend nunca debe depender de `message` para el comportamiento.

Formato uniforme propuesto (superconjunto compatible con la app):

```json
{
  "code": "validation_error",
  "message": "texto legible para depuración",
  "details": [{ "field": "title", "issue": "required" }]
}
```

- `code`: obligatorio, `snake_case`.
- `message`: obligatorio en el backend, la app lo ignora. Genérico, sin datos internos.
- `details`: opcional. Solo en 422, sin eco de valores sensibles.

Cómo clasifica la app cada respuesta:

| Respuesta                   | Resultado en la app                               |
| --------------------------- | ------------------------------------------------- |
| 401 en endpoints protegidos | Refresh + un reintento; si falla, sesión expirada |
| 401 en login                | "Credenciales inválidas"                          |
| 409 `email_taken`           | Mensaje "email ya registrado"                     |
| Cualquier otro 4xx/5xx      | Fallo de servidor genérico (usa `code` del body)  |
| Timeout / sin conexión      | Fallo de red (connect 15 s, receive 30 s)         |

Códigos usados: `invalid_credentials`, `email_taken`, `validation_error`, `unauthorized`, `invalid_refresh_token`, `not_found`, `internal_error`.

## 4. Simulación de escenarios (solo desarrollo y staging)

Los tres headers se **ignoran en producción** (`MOCK_SIMULATION_ENABLED` se fuerza a `false` y el servidor no arranca si se activa).

| Header                  | Valores                                                        | Efecto                                                                                                                                 |
| ----------------------- | -------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `X-Mock-Latency`        | milisegundos (entero ≥ 0, con tope)                            | Retrasa la respuesta                                                                                                                   |
| `X-Mock-Error`          | `500`, `401`, `403`, `404`, `422`, `timeout`                   | Fuerza ese error en la petición                                                                                                        |
| `X-Mock-Error`          | `401-once`                                                     | La primera petición protegida con **ese access token** recibe 401 y el token queda quemado; con el token nuevo (tras el refresh) pasan |
| `x-mock-scenario` (app) | `server_error`, `offline`, `unauthorized`, `unauthorized_once` | Equivale a los escenarios internos de la tabla siguiente                                                                               |

Equivalencias del header de la app:

| `x-mock-scenario`   | Escenario interno equivalente |
| ------------------- | ----------------------------- |
| `server_error`      | `X-Mock-Error: 500`           |
| `offline`           | `X-Mock-Error: timeout`       |
| `unauthorized`      | `X-Mock-Error: 401`           |
| `unauthorized_once` | `X-Mock-Error: 401-once`      |

Si llegan ambos headers, `X-Mock-Error` tiene prioridad. Un valor desconocido se ignora.

## 4.1 Endpoints solo de backend

- `POST /auth/logout` — **solo backend, la app aún no lo llama.** Body `{ "refreshToken": "string" }`. Responde siempre **204**, aunque el token ya esté revocado, no exista o sea inválido (idempotente). Revoca la familia de refresh tokens. Para usarlo, la app solo tendría que llamarlo al cerrar sesión.
- `POST /__reset` — restaura los datos semilla. Solo fuera de producción (en producción no existe: 404).
- `GET /health` — `200 {"status":"ok"}`, sin información sensible.

## 4.2 Reglas decididas

- **Tareas por usuario.** Cada usuario solo ve y modifica las suyas. Acceder a una tarea ajena responde **404 `not_found`** (nunca 403), para no revelar que existe. El usuario demo arranca con 23 tareas semilla; las cuentas nuevas, vacías.
- **Contraseña.** `register` exige 8+ caracteres con mayúscula, minúscula, dígito y símbolo (definido una sola vez en el esquema zod); si falla, 422 con `details` por campo. `login` no exige la política.
- **Query de `GET /tasks`.**
  - Valores no numéricos en `page`/`pageSize` o enums desconocidos en `status`/`priority`: **422 `validation_error`**.
  - Rangos: `page` < 1 → 1; `pageSize` < 1 → 1 y > 100 → 100 (límites silenciosos). Los valores efectivos se devuelven en `page` y `pageSize`.
- **Errores genéricos del servidor.** JSON mal formado → 400 `invalid_json`; cuerpo demasiado grande → 413 `payload_too_large`; ruta desconocida → 404 `not_found`; error inesperado → 500 `internal_error` (sin detalles internos).
- **Usuario semilla:** `demo@starkshowcase.dev` / `Demo1234!`.

## 5. Hallazgos que afectan al diseño

1. **La app solo acepta HTTPS.** `HttpsEnforcerInterceptor` rechaza cualquier URL `http://` y Android tiene `usesCleartextTraffic="false"` con `network_security_config` sin excepciones. Por tanto `http://10.0.2.2:<puerto>` **no funcionará** tal cual contra el backend local. Decisión en la sección 6.
2. **No hay endpoint de logout, de perfil ni de settings.** El logout de la app es local (borra tokens). `restoreSession` lee el usuario guardado en el dispositivo.
3. **Los tokens son opacos para la app.** Se pueden emitir JWT reales sin cambios en Flutter.
4. **El servidor es la fuente del refresh token** y la app guarda ambos tokens en `flutter_secure_storage`.
5. **El mock de la app no valida la fortaleza de la contraseña** (solo no vacía), pero el formulario sí exige 8+ caracteres con mayúscula, minúscula, dígito y símbolo.
6. **El mock de la app comparte las tareas entre todas las cuentas** (lista global). El contrato no dice nada sobre propiedad por usuario.
7. Credenciales semilla del mock actual: `demo@starkshowcase.dev` / `Demo1234!` (se reutilizarán).

## 6. Decisiones tomadas

1. **HTTPS en local:** túnel `cloudflared`. Para probar rápido en emulador se puede permitir `http` solo en el build debug de la app (config de red en el source set `debug`), nunca en release. Sin certificado propio.
2. **Headers:** `X-Mock-Latency`, `X-Mock-Error` y mapeo de `x-mock-scenario` (sección 4).
3. **`401-once`** por access token (sección 4).
4. **`POST /auth/logout`** idempotente, marcado como solo backend (sección 4.1).
5. **Tareas por usuario**, con 404 para recursos ajenos (sección 4.2).
6. **Política de contraseña** en `register` (sección 4.2).
7. **Query inválida:** 422 para tipos/enums y límites silenciosos para rangos (sección 4.2).
8. **Ubicación:** `backend/` dentro de este repositorio; `render.yaml` usará `rootDir: backend`.
