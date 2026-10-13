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

#### Alta de cuenta (3 pasos)

El registro confirma primero el email con un código; la cuenta solo se crea con la prueba de esa confirmación. **Cambio incompatible** respecto a la versión anterior de `POST /auth/register` (sin `phone` ni fecha de nacimiento, sin versiones paralelas).

**Paso 1 — `POST /auth/signup/email`** · Request `{ "email": "string" }`

| Status | Body                             | Cuándo                               |
| ------ | -------------------------------- | ------------------------------------ |
| 204    | —                                | Código enviado                       |
| 409    | `{ "code": "email_taken" }`      | Email ya registrado                  |
| 422    | `{ "code": "validation_error" }` | Email inválido o campos desconocidos |
| 429    | `{ "code": "rate_limited" }`     | Límite de peticiones (sección 4.6)   |

**Reenviar — `POST /auth/signup/code/resend`** · mismo request. Sustituye el código anterior (y reinicia los intentos). Mínimo 30 s entre envíos al mismo email: antes → **429 `resend_too_soon`**. Mismas respuestas 204/409/422.

**Paso 2 — `POST /auth/signup/verify`** · Request `{ "email": "string", "code": "123456" }` (`code`: exactamente 6 dígitos)

| Status | Body                                | Cuándo                                                        |
| ------ | ----------------------------------- | ------------------------------------------------------------- |
| 200    | `{ "verificationToken": "string" }` | Código correcto (de un solo uso)                              |
| 422    | `{ "code": "invalid_code" }`        | Código erróneo o email sin código pendiente (misma respuesta) |
| 422    | `{ "code": "code_expired" }`        | Pasaron 10 minutos desde el envío                             |
| 429    | `{ "code": "too_many_attempts" }`   | 5.º fallo: el código se descarta; hay que pedir otro          |

`verificationToken` es una cadena opaca, válida 30 minutos y de un solo uso; el servidor solo guarda su hash.

**`GET /auth/username-available?username=<valor>`** → `200 { "available": true | false }` (sin distinguir mayúsculas). Valor inválido → 422.

**Paso 3 — `POST /auth/register`**

```json
{ "verificationToken": "string", "name": "string", "username": "string", "password": "string" }
```

El email **sale del token**, nunca del cuerpo. El cuerpo es estricto: `phone`, `birthdate`, `email` o cualquier campo desconocido → 422. `name` se recorta (1–100). `username` se pasa a minúsculas: 3–30 caracteres de `a-z 0-9 . _`, sin punto al inicio ni al final.

| Status | Body                                       | Cuándo                                                             |
| ------ | ------------------------------------------ | ------------------------------------------------------------------ |
| 201    | `AuthResponse`                             | Cuenta creada                                                      |
| 409    | `{ "code": "username_taken" }`             | Usuario ocupado (el token **sigue siendo válido** para reintentar) |
| 409    | `{ "code": "email_taken" }`                | El email se registró entretanto                                    |
| 422    | `{ "code": "invalid_verification_token" }` | Token desconocido, caducado o ya usado                             |
| 422    | `{ "code": "validation_error" }`           | Campos inválidos (contraseña: ver 4.2)                             |

### Users (requieren bearer)

La imagen solo la lee su propietario: el id sale siempre del token, no hay ruta con id.

#### `PUT /users/me/avatar`

Cuerpo: bytes JPEG sin procesar, **máximo 200 KB** (`Content-Type: image/jpeg`, aunque el servidor no se fía de él). El formato se valida por su contenido (marcadores JPEG de inicio `FF D8 FF` y fin `FF D9`).

| Status | Body                              | Cuándo                                  |
| ------ | --------------------------------- | --------------------------------------- |
| 204    | —                                 | Imagen guardada (sustituye la anterior) |
| 401    | `{ "code": "unauthorized" }`      | Sin sesión                              |
| 413    | `{ "code": "payload_too_large" }` | Más de 200 KB                           |
| 422    | `{ "code": "invalid_image" }`     | No es un JPEG (o cuerpo vacío)          |

#### `GET /users/me/avatar`

200 con los bytes, `Content-Type: image/jpeg`, `X-Content-Type-Options: nosniff` y `Cache-Control: private, no-store`. 404 `avatar_not_found` si no hay imagen; 401 sin sesión. La imagen vive en memoria y se pierde al reiniciar.

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
  "user": {
    "id": "string",
    "name": "string",
    "email": "string",
    "username": "string",
    "hasAvatar": false
  },
  "accessToken": "string",
  "refreshToken": "string"
}
```

`user.hasAvatar` indica si hay imagen descargable en `GET /users/me/avatar`. Ya no existe `phone`. No se devuelve nunca la contraseña ni su hash.

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

- `POST /auth/logout` — **la app lo llama al cerrar sesión** (sin bearer, con el refresh token guardado; si falla o tarda más de 5 s, la sesión local se borra igualmente). Body `{ "refreshToken": "string" }`. Responde siempre **204**, aunque el token ya esté revocado, no exista o sea inválido (idempotente). Revoca la familia de refresh tokens.
- `POST /__reset` — restaura los datos semilla. Solo fuera de producción (en producción no existe: 404).
- `GET /health` — `200 {"status":"ok"}`, sin información sensible.

## 4.3 Detalles de autenticación implementados

- **Access token:** JWT HS256 (`iss` `stark-showcase-backend`, `aud` `stark-showcase-app`, `sub` = id de usuario), TTL `ACCESS_TOKEN_TTL_SECONDS` (900 s por defecto). El secreto solo viene de `JWT_ACCESS_SECRET`.
- **Refresh token:** cadena opaca de 384 bits, guardada solo como hash SHA-256, TTL `REFRESH_TOKEN_TTL_SECONDS` (30 días por defecto). Rotación en cada `POST /auth/refresh`.
- **Detección de reutilización:** si se presenta un refresh token ya consumido, se revoca toda su familia (también el token legítimo más reciente) y responde 401 `invalid_refresh_token`.
- **401 en rutas protegidas:** `unauthorized` (cabecera ausente, mal formada o token inválido) y `token_expired` (JWT caducado). La app trata ambos igual: refresh y un reintento.
- **Contraseñas:** argon2id. En `login` se verifica siempre un hash (aunque el usuario no exista) para igualar tiempos.
- **Códigos de error de `register`** (`details` del 422 `validation_error`): `details` por campo con `issue` entre `too_small`, `too_big`, `invalid_format`, `invalid_type`, `unrecognized_keys`, `missing_uppercase`, `missing_lowercase`, `missing_digit`, `missing_symbol`.

## 4.4 Detalles de tareas implementados

- **Aislamiento:** todas las operaciones de `/tasks` se filtran por el usuario del token; el propietario nunca se acepta del cliente ni se devuelve.
- **Semilla:** `user-0` (demo) tiene 23 tareas (`task-0`…`task-22`, igual que el mock de la app) y `user-1` (Ana) tiene 5 (`task-23`…`task-27`). Las cuentas nuevas empiezan vacías.
- **Consulta de `GET /tasks`:** `status=all` también se acepta (equivale a omitirlo); parámetros desconocidos se ignoran; `q` admite hasta 100 caracteres (más → 422); `page`/`pageSize` solo admiten enteros de hasta 9 dígitos (si no → 422) y se recortan a `page ≥ 1`, `1 ≤ pageSize ≤ 100`.
- **Orden:** `createdAt` descendente y, si empatan, `id` descendente, para que la paginación sea estable.
- **Cuerpo de crear/actualizar:** estricto; `id`, `createdAt` y propietario no se pueden enviar. `dueDate` acepta cualquier instante ISO 8601 (la app envía UTC con hasta microsegundos) y se devuelve normalizado a milisegundos (`...123Z`). `title` se recorta; `description` no.
- **`POST /__reset`:** responde 204 sin cuerpo y restaura usuarios y tareas semilla, descarta imágenes de perfil y códigos pendientes e invalida todas las sesiones. No requiere autenticación y no existe en producción (404).

## 4.5 Simulación implementada (solo desarrollo y staging)

- Se aplica a `/auth/*`, `/users/*` y `/tasks/*`. `/health`, `/openapi.json`, `/docs` y `/__reset` quedan fuera.
- `X-Mock-Latency`: entero de 0 a 60 000 ms (más se recorta; valores no numéricos se ignoran). Se aplica antes que el error.
- `X-Mock-Error: 500|401|403|404|422` responde con `{ code, message }` (`internal_error`, `unauthorized`, `forbidden`, `not_found`, `validation_error`) sin tocar datos.
- `X-Mock-Error: timeout` mantiene la conexión abierta 60 s (más que el `receiveTimeout` de 30 s de la app) y la corta sin responder.
- `X-Mock-Error: 401-once` solo actúa en `/tasks/*` y `/users/*`: la primera petición con un access token **emitido por login o registro** recibe 401 `token_expired`; ese token queda marcado y las siguientes pasan. Los tokens **emitidos por un refresh** (claim `rfr`) siempre pasan, de modo que la app puede conservar la cabecera en el reintento tras el refresh sin entrar en bucle. Un nuevo login vuelve a activar el 401 una vez.
- En producción (`MOCK_SIMULATION_ENABLED` forzado a `false`) los tres headers se ignoran y no aparecen en `/docs`.

## 4.6 Límites de peticiones

Por IP y ventana (`RATE_LIMIT_WINDOW_SECONDS`, 60 s por defecto): 300 en general, 10 compartidas entre `POST /auth/login`, `/auth/register` y `/auth/signup/*` (enviar, reenviar y verificar), 20 en `POST /auth/refresh`. Al superarlos: **429** `{ "code": "rate_limited", "message": ... }` con `Retry-After` y `RateLimit-*`. `/health` y `/docs` no cuentan. Detrás de un proxy hay que activar `TRUST_PROXY=true` o todas las peticiones compartirán IP.

## 4.7 Documentación

`GET /docs` (Swagger UI) y `GET /openapi.json` (OpenAPI 3.0.3), generados desde los mismos esquemas zod que validan las peticiones. Las respuestas de `/auth/*` llevan `Cache-Control: no-store`.

## 4.2 Reglas decididas

- **Tareas por usuario.** Cada usuario solo ve y modifica las suyas. Acceder a una tarea ajena responde **404 `not_found`** (nunca 403), para no revelar que existe. El usuario demo arranca con 23 tareas semilla; las cuentas nuevas, vacías.
- **Contraseña.** `register` exige 8+ caracteres con mayúscula, minúscula, dígito y símbolo (definido una sola vez en el esquema zod); si falla, 422 con `details` por campo. `login` no exige la política.
- **Query de `GET /tasks`.**
  - Valores no numéricos en `page`/`pageSize` o enums desconocidos en `status`/`priority`: **422 `validation_error`**.
  - Rangos: `page` < 1 → 1; `pageSize` < 1 → 1 y > 100 → 100 (límites silenciosos). Los valores efectivos se devuelven en `page` y `pageSize`.
- **Errores genéricos del servidor.** JSON mal formado → 400 `invalid_json`; cuerpo demasiado grande → 413 `payload_too_large`; ruta desconocida → 404 `not_found`; error inesperado → 500 `internal_error` (sin detalles internos).
- **Usuarios semilla:** `demo@starkshowcase.dev` / `Demo1234!` (usuario `demo`) y `ana@starkshowcase.dev` / `Ana12345!` (usuario `ana`).
- **Código de confirmación.** El backend no envía correos. `FIXED_CONFIRMATION_CODE` (6 dígitos) es el código que acepta cualquier email: fuera de producción vale `123456` por defecto; en producción solo existe si se define a propósito (sin él los códigos son aleatorios y nadie puede registrarse). Con un código fijo en producción se registra un aviso al arrancar (sin imprimir el código). Enviar correos reales es una mejora futura: basta implementar el puerto `ConfirmationCodeSender`.
- **Intentos.** Un código dura 10 minutos y se descarta tras 5 fallos; el reenvío tiene 30 s de espera por email. Los límites por IP de la sección 4.6 siguen aplicando a los tres endpoints.
- **Aviso de la instancia pública.** Con el código conocido, cualquiera puede registrarse en una instancia pública; los datos viven en memoria y se pierden al reiniciar. Es una demo.

## 5. Hallazgos que afectan al diseño

1. **La app solo acepta HTTPS.** `HttpsEnforcerInterceptor` rechaza cualquier URL `http://` y Android tiene `usesCleartextTraffic="false"` con `network_security_config` sin excepciones. Por tanto `http://10.0.2.2:<puerto>` **no funcionará** tal cual contra el backend local. Decisión en la sección 6.
2. **No hay endpoint de perfil ni de settings** (solo la imagen en `/users/me/avatar`). `restoreSession` lee el usuario guardado en el dispositivo.
3. **Los tokens son opacos para la app.** Se pueden emitir JWT reales sin cambios en Flutter.
4. **El servidor es la fuente del refresh token** y la app guarda ambos tokens en `flutter_secure_storage`.
5. **El mock de la app no valida la fortaleza de la contraseña** (solo no vacía), pero el formulario sí exige 8+ caracteres con mayúscula, minúscula, dígito y símbolo.
6. **El mock de la app comparte las tareas entre todas las cuentas** (lista global). El contrato no dice nada sobre propiedad por usuario.
7. Credenciales semilla del mock actual: `demo@starkshowcase.dev` / `Demo1234!` (se reutilizarán).

## 6. Decisiones tomadas

1. **HTTPS en local:** túnel `cloudflared`. Para probar rápido en emulador se puede permitir `http` solo en el build debug de la app (config de red en el source set `debug`), nunca en release. Sin certificado propio.
2. **Headers:** `X-Mock-Latency`, `X-Mock-Error` y mapeo de `x-mock-scenario` (sección 4).
3. **`401-once`** por access token (sección 4).
4. **`POST /auth/logout`** idempotente (sección 4.1); la app ya lo llama al cerrar sesión.
5. **Tareas por usuario**, con 404 para recursos ajenos (sección 4.2).
6. **Política de contraseña** en `register` (sección 4.2).
7. **Alta en tres pasos** con código de confirmación, sin teléfono ni fecha de nacimiento, e imagen de perfil en memoria (solo JPEG ≤ 200 KB).
8. **Query inválida:** 422 para tipos/enums y límites silenciosos para rangos (sección 4.2).
9. **Ubicación:** `backend/` dentro de este repositorio; `render.yaml` usará `rootDir: backend`.
