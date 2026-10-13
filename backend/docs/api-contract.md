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

| Status | Body | Cuándo |
|---|---|---|
| 200 | `AuthResponse` | Credenciales correctas |
| 401 | `{ "code": "invalid_credentials" }` | Usuario inexistente o contraseña errónea (mismo mensaje en ambos casos) |
| 422 | `{ "code": "validation_error" }` | Body inválido |

#### `POST /auth/register`

Request:

```json
{ "name": "string", "email": "string", "password": "string", "phone": "string | null" }
```

`phone` es opcional: la app lo omite o lo envía como `null` si está vacío; si existe llega solo con dígitos y un `+` inicial (7–15 dígitos). `name` llega recortado, máximo 100 caracteres.

| Status | Body | Cuándo |
|---|---|---|
| 201 | `AuthResponse` | Cuenta creada |
| 409 | `{ "code": "email_taken" }` | Email ya registrado (la app muestra un mensaje específico) |
| 422 | `{ "code": "validation_error" }` | Campos obligatorios vacíos o inválidos |

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

| Param | Tipo | Valores / reglas |
|---|---|---|
| `page` | int | 1-based, por defecto 1 |
| `pageSize` | int | por defecto 10, máximo 100 |
| `q` | string | búsqueda sin distinguir mayúsculas en `title` y `description` (subcadena) |
| `status` | string | `pending` \| `done` (si falta, equivale a `all`; la app nunca envía `all`) |
| `priority` | string | `low` \| `medium` \| `high` |

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

| Campo | Tipo | Nulable |
|---|---|---|
| `id` | string | no |
| `title` | string | no |
| `description` | string | no (puede ser `""`) |
| `priority` | `"low" \| "medium" \| "high"` | no |
| `isDone` | boolean | no |
| `createdAt` | string ISO 8601 UTC | no |
| `dueDate` | string ISO 8601 UTC | **sí** (`null` explícito) |

## 3. Errores

Qué lee la app: **solo** el campo `code` (string) del body de la respuesta. Si no existe usa `http_<status>`. Los textos que ve el usuario son genéricos y se resuelven en la app según la clase de fallo, así que el backend nunca debe depender de `message` para el comportamiento.

Formato uniforme propuesto (superconjunto compatible con la app):

```json
{ "code": "validation_error", "message": "texto legible para depuración", "details": [ { "field": "title", "issue": "required" } ] }
```

- `code`: obligatorio, `snake_case`.
- `message`: obligatorio en el backend, la app lo ignora. Genérico, sin datos internos.
- `details`: opcional. Solo en 422, sin eco de valores sensibles.

Cómo clasifica la app cada respuesta:

| Respuesta | Resultado en la app |
|---|---|
| 401 en endpoints protegidos | Refresh + un reintento; si falla, sesión expirada |
| 401 en login | "Credenciales inválidas" |
| 409 `email_taken` | Mensaje "email ya registrado" |
| Cualquier otro 4xx/5xx | Fallo de servidor genérico (usa `code` del body) |
| Timeout / sin conexión | Fallo de red (connect 15 s, receive 30 s) |

Códigos usados: `invalid_credentials`, `email_taken`, `validation_error`, `unauthorized`, `invalid_refresh_token`, `not_found`, `internal_error`.

## 4. Simulación de escenarios del cliente (referencia)

La app ya tiene su propio mock con el header `x-mock-scenario` (`server_error`, `offline`, `unauthorized`, `unauthorized_once`). Es una función del cliente que solo funciona con `USE_MOCK_API=true`; con el backend real el header viaja como cualquier otro y el servidor puede ignorarlo o interpretarlo (ver pregunta 2).

## 5. Hallazgos que afectan al diseño

1. **La app solo acepta HTTPS.** `HttpsEnforcerInterceptor` rechaza cualquier URL `http://` y Android tiene `usesCleartextTraffic="false"` con `network_security_config` sin excepciones. Por tanto `http://10.0.2.2:<puerto>` **no funcionará** tal cual contra el backend local. Opciones en la pregunta 1.
2. **No hay endpoint de logout, de perfil ni de settings.** El logout de la app es local (borra tokens). `restoreSession` lee el usuario guardado en el dispositivo.
3. **Los tokens son opacos para la app.** Se pueden emitir JWT reales sin cambios en Flutter.
4. **El servidor es la fuente del refresh token** y la app guarda ambos tokens en `flutter_secure_storage`.
5. **El mock de la app no valida la fortaleza de la contraseña** (solo no vacía), pero el formulario sí exige 8+ caracteres con mayúscula, minúscula, dígito y símbolo.
6. **El mock de la app comparte las tareas entre todas las cuentas** (lista global). El contrato no dice nada sobre propiedad por usuario.
7. Credenciales semilla del mock actual: `demo@starkshowcase.dev` / `Demo1234!` (se reutilizarán).

## 6. Preguntas abiertas (necesito tu decisión)

1. **HTTPS en local.** Opciones: (a) usar el túnel `cloudflared`/`ngrok` para probar la app (la app no se toca), (b) permitir `http` solo en builds debug de la app (cambio pequeño en `HttpsEnforcerInterceptor` y en un `network_security_config` de debug), (c) HTTPS local con certificado propio (Android no lo confía sin instalarlo). Recomiendo (a) para pruebas y Render para el uso continuo; (b) solo si quieres emulador sin túnel.
2. **Nombres de los headers de simulación.** Tú pides `X-Mock-Latency` y `X-Mock-Error`; la app ya usa `x-mock-scenario`. Propongo soportar `X-Mock-Latency: <ms>` y `X-Mock-Error: 500|401|403|404|422|timeout` y, además, mapear `x-mock-scenario` (`server_error` → 500, `unauthorized` → 401, `offline` → timeout) para compatibilidad.
3. **Token expirado a propósito.** Propongo, además de la expiración real del JWT (TTL configurable por entorno), el valor `X-Mock-Error: 401-once`: la primera petición con un access token concreto recibe 401 y ese token queda quemado, así que la app refresca y el reintento pasa. ¿De acuerdo?
4. **`POST /auth/logout`.** La app no lo llama. Para cumplir "revocación al cerrar sesión" lo añadiría como endpoint extra (body `{ "refreshToken": "..." }`, responde 204, idempotente). Es un campo que la app no usa hoy; ¿lo incluyo?
5. **Tareas por usuario o globales.** El mock actual es global. Propongo tareas por usuario: el usuario demo viene con 23 tareas semilla y las cuentas nuevas empiezan vacías. ¿O prefieres la lista global como el mock?
6. **Política de contraseña en el servidor.** Propongo exigir en `register` la misma regla que el formulario (8+, mayúscula, minúscula, dígito, símbolo) y devolver 422 si no se cumple. En login no se valida la fortaleza. ¿De acuerdo?
7. **Parámetros de query inválidos** (`status=foo`, `page=abc`). El mock los ignora. Propongo 422 `validation_error` para valores no numéricos o enums desconocidos, y límites silenciosos para rangos (`pageSize` > 100 → 100, `page` < 1 → 1). ¿Te vale?
8. **Ubicación del backend.** La ruta de Windows que indicas no existe en esta sesión en la nube: el proyecto Flutter está clonado en `/home/user/demo`. Creo el backend en `backend/` dentro de ese mismo repositorio (`alegomezrivas/demo`), en la rama `claude/intelligent-darwin-cmal86`. ¿Correcto, o prefieres un repositorio aparte?
