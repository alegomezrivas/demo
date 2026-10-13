import { z } from 'zod';
import type { AppConfig } from '../config/env.js';
import {
  authResponseSchema,
  loginRequestSchema,
  logoutRequestSchema,
  refreshRequestSchema,
  registerRequestSchema,
  signUpEmailRequestSchema,
  tokenPairResponseSchema,
  usernameAvailabilityResponseSchema,
  usernameQuerySchema,
  verificationResponseSchema,
  verifyCodeRequestSchema,
} from '../contexts/auth/presentation/http/auth-schemas.js';
import {
  listQuerySchema,
  taskInputSchema,
  taskPageResponseSchema,
  taskResponseSchema,
  taskStatsResponseSchema,
} from '../contexts/tasks/presentation/http/task-schemas.js';
import { errorBodySchema } from '../shared/http/error-schemas.js';
import { MAX_LATENCY_MS } from '../shared/http/mock-simulation.js';

type Json = Record<string, unknown>;

/**
 * Converts a zod schema to an OpenAPI 3.0 schema object. Request schemas use the
 * input side (before transforms), responses the output side.
 */
function toSchema(schema: z.ZodType, io: 'input' | 'output'): Json {
  const converted = z.toJSONSchema(schema, {
    target: 'openapi-3.0',
    io,
    unrepresentable: 'any',
  }) as Json;
  // The `$schema` keyword is not part of an OpenAPI schema object.
  return Object.fromEntries(Object.entries(converted).filter(([key]) => key !== '$schema'));
}

const ref = (name: string): Json => ({ $ref: `#/components/schemas/${name}` });
const refResponse = (name: string): Json => ({ $ref: `#/components/responses/${name}` });
const json = (schemaName: string): Json => ({ 'application/json': { schema: ref(schemaName) } });

const MOCK_PARAMETERS = ['MockLatency', 'MockError', 'MockScenario'].map((name) => ({
  $ref: `#/components/parameters/${name}`,
}));

/** Query parameters of `GET /tasks`, derived from the same schema the route validates with. */
function listParameters(): Json[] {
  const input = toSchema(listQuerySchema, 'input');
  const properties = (input['properties'] ?? {}) as Record<string, Json>;
  return Object.entries(properties).map(([name, schema]) => ({
    name,
    in: 'query',
    required: false,
    schema,
  }));
}

/** Schema of the `username` query parameter, from the same schema the route validates. */
function usernameParameterSchema(): Json {
  const properties = (toSchema(usernameQuerySchema, 'input')['properties'] ?? {}) as Record<
    string,
    Json
  >;
  return properties['username'] ?? { type: 'string' };
}

/** Builds the OpenAPI 3 document served at `/openapi.json` and rendered at `/docs`. */
export function buildOpenApiDocument(config: AppConfig): Json {
  const simulation = config.mockSimulationEnabled ? MOCK_PARAMETERS : [];
  const idParameter = {
    name: 'id',
    in: 'path',
    required: true,
    schema: { type: 'string', minLength: 1, maxLength: 100 },
  };
  const secured = [{ bearerAuth: [] }];

  const paths: Record<string, Json> = {
    '/health': {
      get: {
        tags: ['System'],
        summary: 'Liveness probe',
        responses: {
          '200': {
            description: 'The server is up.',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { status: { type: 'string', enum: ['ok'] } },
                  required: ['status'],
                },
              },
            },
          },
        },
      },
    },
    '/auth/login': {
      post: {
        tags: ['Auth'],
        summary: 'Sign in with e-mail and password',
        parameters: simulation,
        requestBody: { required: true, content: json('LoginRequest') },
        responses: {
          '200': { description: 'Signed in.', content: json('AuthResponse') },
          '401': {
            description:
              'Wrong credentials (`invalid_credentials`), identical for unknown e-mails.',
            content: json('ErrorBody'),
          },
          '422': refResponse('ValidationError'),
          '429': refResponse('TooManyRequests'),
        },
      },
    },
    '/auth/signup/email': {
      post: {
        tags: ['Auth'],
        summary: 'Sign-up step 1: send a confirmation code to an e-mail',
        description:
          'The demo sends no e-mail: the code is the fixed `FIXED_CONFIRMATION_CODE` (`123456` outside production unless configured).',
        parameters: simulation,
        requestBody: { required: true, content: json('SignUpEmailRequest') },
        responses: {
          '204': { description: 'Code sent.' },
          '409': {
            description: 'E-mail already registered (`email_taken`).',
            content: json('ErrorBody'),
          },
          '422': refResponse('ValidationError'),
          '429': refResponse('TooManyRequests'),
        },
      },
    },
    '/auth/signup/code/resend': {
      post: {
        tags: ['Auth'],
        summary: 'Send the confirmation code again',
        description: 'Throttled per e-mail: 30 seconds between sends (`resend_too_soon`).',
        parameters: simulation,
        requestBody: { required: true, content: json('SignUpEmailRequest') },
        responses: {
          '204': { description: 'Code sent again; the previous one stops working.' },
          '409': {
            description: 'E-mail already registered (`email_taken`).',
            content: json('ErrorBody'),
          },
          '422': refResponse('ValidationError'),
          '429': refResponse('TooManyRequests'),
        },
      },
    },
    '/auth/signup/verify': {
      post: {
        tags: ['Auth'],
        summary: 'Sign-up step 2: confirm the code',
        description:
          'Codes last 10 minutes and are discarded after 5 wrong guesses (`too_many_attempts`, 429). On success the response carries the single-use `verificationToken` (valid 30 minutes) that `register` needs.',
        parameters: simulation,
        requestBody: { required: true, content: json('VerifyCodeRequest') },
        responses: {
          '200': { description: 'E-mail confirmed.', content: json('VerificationResponse') },
          '422': {
            description: 'Wrong code (`invalid_code`) or expired code (`code_expired`).',
            content: json('ErrorBody'),
          },
          '429': refResponse('TooManyRequests'),
        },
      },
    },
    '/auth/username-available': {
      get: {
        tags: ['Auth'],
        summary: 'Tell whether a username is free',
        parameters: [
          ...simulation,
          { name: 'username', in: 'query', required: true, schema: usernameParameterSchema() },
        ],
        responses: {
          '200': { description: 'Availability.', content: json('UsernameAvailability') },
          '422': refResponse('ValidationError'),
          '429': refResponse('TooManyRequests'),
        },
      },
    },
    '/auth/register': {
      post: {
        tags: ['Auth'],
        summary: 'Sign-up final step: create the account',
        description:
          'Needs the `verificationToken` from `/auth/signup/verify`; the e-mail comes from it. The password must have 8-128 characters with upper case, lower case, a digit and a symbol. The username is lower-cased and must be 3-30 characters of `a-z 0-9 . _`.',
        parameters: simulation,
        requestBody: { required: true, content: json('RegisterRequest') },
        responses: {
          '201': { description: 'Account created.', content: json('AuthResponse') },
          '409': {
            description:
              'E-mail already registered (`email_taken`) or username taken (`username_taken`).',
            content: json('ErrorBody'),
          },
          '422': {
            description:
              'Invalid input, or an unknown/expired token (`invalid_verification_token`).',
            content: json('ErrorBody'),
          },
          '429': refResponse('TooManyRequests'),
        },
      },
    },
    '/auth/refresh': {
      post: {
        tags: ['Auth'],
        summary: 'Exchange a refresh token for a new pair (rotation)',
        description:
          'Each refresh token works once. Presenting an already used one revokes the whole session family.',
        parameters: simulation,
        requestBody: { required: true, content: json('RefreshRequest') },
        responses: {
          '200': { description: 'New token pair.', content: json('TokenPair') },
          '401': {
            description: 'Unknown, expired, revoked or reused token (`invalid_refresh_token`).',
            content: json('ErrorBody'),
          },
          '422': refResponse('ValidationError'),
          '429': refResponse('TooManyRequests'),
        },
      },
    },
    '/auth/logout': {
      post: {
        tags: ['Auth'],
        summary: 'Revoke a session (called by the app on sign-out)',
        description: 'Idempotent: always 204 for a well-formed body, even for unknown tokens.',
        parameters: simulation,
        requestBody: { required: true, content: json('LogoutRequest') },
        responses: {
          '204': { description: 'Session revoked (or there was nothing to revoke).' },
          '422': refResponse('ValidationError'),
          '429': refResponse('TooManyRequests'),
        },
      },
    },
    '/users/me/avatar': {
      put: {
        tags: ['Users'],
        summary: 'Replace the profile picture',
        description:
          'Raw JPEG bytes, at most 200 KB. The format is checked by its content, never by the declared Content-Type.',
        security: secured,
        parameters: simulation,
        requestBody: {
          required: true,
          content: { 'image/jpeg': { schema: { type: 'string', format: 'binary' } } },
        },
        responses: {
          '204': { description: 'Picture stored.' },
          '401': refResponse('Unauthorized'),
          '413': {
            description: 'Body larger than 200 KB (`payload_too_large`).',
            content: json('ErrorBody'),
          },
          '422': {
            description: 'Not a JPEG (`invalid_image`).',
            content: json('ErrorBody'),
          },
          '429': refResponse('TooManyRequests'),
        },
      },
      get: {
        tags: ['Users'],
        summary: 'Download your own profile picture',
        description:
          'Only the owner can read it. Served as `image/jpeg` with `X-Content-Type-Options: nosniff` and `Cache-Control: private, no-store`.',
        security: secured,
        parameters: simulation,
        responses: {
          '200': {
            description: 'The picture.',
            content: { 'image/jpeg': { schema: { type: 'string', format: 'binary' } } },
          },
          '401': refResponse('Unauthorized'),
          '404': {
            description: 'No picture yet (`avatar_not_found`).',
            content: json('ErrorBody'),
          },
          '429': refResponse('TooManyRequests'),
        },
      },
    },
    '/tasks': {
      get: {
        tags: ['Tasks'],
        summary: "List the caller's tasks (search, filters, pagination)",
        description:
          'Newest first. `page` below 1 becomes 1 and `pageSize` is clamped to 1-100; non-numeric values and unknown enum values are 422.',
        security: secured,
        parameters: [...listParameters(), ...simulation],
        responses: {
          '200': { description: 'One page.', content: json('TaskPage') },
          '401': refResponse('Unauthorized'),
          '422': refResponse('ValidationError'),
          '429': refResponse('TooManyRequests'),
        },
      },
      post: {
        tags: ['Tasks'],
        summary: 'Create a task',
        security: secured,
        parameters: simulation,
        requestBody: { required: true, content: json('TaskInput') },
        responses: {
          '201': { description: 'Created.', content: json('Task') },
          '401': refResponse('Unauthorized'),
          '422': refResponse('ValidationError'),
          '429': refResponse('TooManyRequests'),
        },
      },
    },
    '/tasks/stats': {
      get: {
        tags: ['Tasks'],
        summary: "Aggregated statistics of the caller's tasks",
        security: secured,
        parameters: simulation,
        responses: {
          '200': { description: 'Statistics.', content: json('TaskStats') },
          '401': refResponse('Unauthorized'),
          '429': refResponse('TooManyRequests'),
        },
      },
    },
    '/tasks/{id}': {
      get: {
        tags: ['Tasks'],
        summary: 'Get one task',
        security: secured,
        parameters: [idParameter, ...simulation],
        responses: {
          '200': { description: 'The task.', content: json('Task') },
          '401': refResponse('Unauthorized'),
          '404': refResponse('NotFound'),
          '429': refResponse('TooManyRequests'),
        },
      },
      put: {
        tags: ['Tasks'],
        summary: 'Replace a task',
        security: secured,
        parameters: [idParameter, ...simulation],
        requestBody: { required: true, content: json('TaskInput') },
        responses: {
          '200': { description: 'The updated task.', content: json('Task') },
          '401': refResponse('Unauthorized'),
          '404': refResponse('NotFound'),
          '422': refResponse('ValidationError'),
          '429': refResponse('TooManyRequests'),
        },
      },
      delete: {
        tags: ['Tasks'],
        summary: 'Delete a task',
        security: secured,
        parameters: [idParameter, ...simulation],
        responses: {
          '204': { description: 'Deleted.' },
          '401': refResponse('Unauthorized'),
          '404': refResponse('NotFound'),
          '429': refResponse('TooManyRequests'),
        },
      },
    },
  };

  if (config.resetEndpointEnabled) {
    paths['/__reset'] = {
      post: {
        tags: ['System'],
        summary: 'Restore the seed data (not available in production)',
        responses: { '204': { description: 'Seed data restored; every session is invalidated.' } },
      },
    };
  }

  const parameters: Record<string, Json> = config.mockSimulationEnabled
    ? {
        MockLatency: {
          name: 'X-Mock-Latency',
          in: 'header',
          required: false,
          description: `Delay the response by this many milliseconds (max ${String(MAX_LATENCY_MS)}). Development/staging only.`,
          schema: { type: 'integer', minimum: 0, maximum: MAX_LATENCY_MS },
        },
        MockError: {
          name: 'X-Mock-Error',
          in: 'header',
          required: false,
          description:
            'Force an error. `401-once` answers 401 once to the first request that uses a login-issued access token (protected routes); tokens obtained through a refresh always pass. `timeout` holds the connection until the client gives up. Development/staging only.',
          schema: {
            type: 'string',
            enum: ['500', '401', '403', '404', '422', '401-once', 'timeout'],
          },
        },
        MockScenario: {
          name: 'x-mock-scenario',
          in: 'header',
          required: false,
          description:
            "Header of the Flutter app's own mock, mapped to the same scenarios: `server_error`=500, `offline`=timeout, `unauthorized`=401, `unauthorized_once`=401-once. `X-Mock-Error` wins when both are sent.",
          schema: {
            type: 'string',
            enum: ['server_error', 'offline', 'unauthorized', 'unauthorized_once'],
          },
        },
      }
    : {};

  return {
    openapi: '3.0.3',
    info: {
      title: 'Stark Showcase API',
      version: '1.0.0',
      description:
        'Mock-data backend for the Stark Showcase Flutter app. Every success body matches the models of the app; every error body is `{ code, message, details? }`.',
    },
    tags: [{ name: 'System' }, { name: 'Auth' }, { name: 'Users' }, { name: 'Tasks' }],
    paths,
    components: {
      securitySchemes: {
        bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
      },
      parameters,
      schemas: {
        ErrorBody: toSchema(errorBodySchema, 'output'),
        LoginRequest: toSchema(loginRequestSchema, 'input'),
        SignUpEmailRequest: toSchema(signUpEmailRequestSchema, 'input'),
        VerifyCodeRequest: toSchema(verifyCodeRequestSchema, 'input'),
        VerificationResponse: toSchema(verificationResponseSchema, 'output'),
        UsernameAvailability: toSchema(usernameAvailabilityResponseSchema, 'output'),
        RegisterRequest: toSchema(registerRequestSchema, 'input'),
        RefreshRequest: toSchema(refreshRequestSchema, 'input'),
        LogoutRequest: toSchema(logoutRequestSchema, 'input'),
        AuthResponse: toSchema(authResponseSchema, 'output'),
        TokenPair: toSchema(tokenPairResponseSchema, 'output'),
        TaskInput: toSchema(taskInputSchema, 'input'),
        Task: toSchema(taskResponseSchema, 'output'),
        TaskPage: toSchema(taskPageResponseSchema, 'output'),
        TaskStats: toSchema(taskStatsResponseSchema, 'output'),
      },
      responses: {
        Unauthorized: {
          description:
            'Missing, malformed, invalid (`unauthorized`) or expired (`token_expired`) access token.',
          content: json('ErrorBody'),
        },
        NotFound: {
          description:
            'Unknown id, or a task owned by someone else (indistinguishable on purpose).',
          content: json('ErrorBody'),
        },
        ValidationError: {
          description: 'Invalid input (`validation_error`) with per-field `details`.',
          content: json('ErrorBody'),
        },
        TooManyRequests: {
          description: 'Rate limit exceeded (`rate_limited`); see the Retry-After header.',
          content: json('ErrorBody'),
        },
      },
    },
  };
}
