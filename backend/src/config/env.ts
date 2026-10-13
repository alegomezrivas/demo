import { z } from 'zod';

const ENVIRONMENTS = ['development', 'test', 'staging', 'production'] as const;

/** Raw environment variables as validated at startup. */
const envSchema = z.object({
  NODE_ENV: z.enum(ENVIRONMENTS).default('development'),
  PORT: z.coerce.number().int().min(1).max(65535).default(5556),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
  CORS_ALLOWED_ORIGINS: z.string().default(''),
  BODY_LIMIT: z
    .string()
    .regex(/^\d+(kb|mb)$/i)
    .default('10kb'),
  TRUST_PROXY: z.stringbool().default(false),
  JWT_ACCESS_SECRET: z.string().min(32, 'must have at least 32 characters'),
  ACCESS_TOKEN_TTL_SECONDS: z.coerce.number().int().min(1).default(900),
  REFRESH_TOKEN_TTL_SECONDS: z.coerce.number().int().min(1).default(2_592_000),
  MOCK_SIMULATION_ENABLED: z.stringbool().optional(),
  RATE_LIMIT_WINDOW_SECONDS: z.coerce.number().int().min(1).default(60),
  RATE_LIMIT_MAX: z.coerce.number().int().min(1).default(300),
  RATE_LIMIT_AUTH_MAX: z.coerce.number().int().min(1).default(10),
  RATE_LIMIT_REFRESH_MAX: z.coerce.number().int().min(1).default(20),
});

/** Typed, immutable runtime configuration. */
export interface AppConfig {
  readonly env: (typeof ENVIRONMENTS)[number];
  readonly isProduction: boolean;
  readonly port: number;
  readonly logLevel: z.infer<typeof envSchema>['LOG_LEVEL'];
  readonly corsAllowedOrigins: readonly string[];
  readonly bodyLimit: string;
  readonly trustProxy: boolean;
  readonly jwt: {
    readonly accessSecret: string;
    readonly accessTtlSeconds: number;
    readonly refreshTtlSeconds: number;
  };
  /** Requests allowed per IP and window; login/register and refresh are stricter. */
  readonly rateLimit: {
    readonly windowSeconds: number;
    readonly max: number;
    readonly authMax: number;
    readonly refreshMax: number;
  };
  /** Enables the X-Mock-* headers; never true in production. */
  readonly mockSimulationEnabled: boolean;
  /** Enables `POST /__reset`; never true in production. */
  readonly resetEndpointEnabled: boolean;
}

/** Thrown when the environment is invalid; messages never include values. */
export class ConfigError extends Error {
  constructor(readonly problems: readonly string[]) {
    super(`Invalid configuration:\n${problems.map((problem) => `  - ${problem}`).join('\n')}`);
    this.name = 'ConfigError';
  }
}

/** Validates [source] and builds the configuration, failing fast on any problem. */
export function loadConfig(source: NodeJS.ProcessEnv = process.env): AppConfig {
  const parsed = envSchema.safeParse(source);
  if (!parsed.success) {
    throw new ConfigError(
      parsed.error.issues.map((issue) => `${issue.path.join('.')}: ${issue.message}`),
    );
  }
  const env = parsed.data;
  const isProduction = env.NODE_ENV === 'production';

  if (isProduction && env.MOCK_SIMULATION_ENABLED === true) {
    throw new ConfigError(['MOCK_SIMULATION_ENABLED: must not be enabled in production']);
  }

  return {
    env: env.NODE_ENV,
    isProduction,
    port: env.PORT,
    logLevel: env.LOG_LEVEL,
    corsAllowedOrigins: env.CORS_ALLOWED_ORIGINS.split(',')
      .map((origin) => origin.trim())
      .filter((origin) => origin.length > 0),
    bodyLimit: env.BODY_LIMIT,
    trustProxy: env.TRUST_PROXY,
    jwt: {
      accessSecret: env.JWT_ACCESS_SECRET,
      accessTtlSeconds: env.ACCESS_TOKEN_TTL_SECONDS,
      refreshTtlSeconds: env.REFRESH_TOKEN_TTL_SECONDS,
    },
    rateLimit: {
      windowSeconds: env.RATE_LIMIT_WINDOW_SECONDS,
      max: env.RATE_LIMIT_MAX,
      authMax: env.RATE_LIMIT_AUTH_MAX,
      refreshMax: env.RATE_LIMIT_REFRESH_MAX,
    },
    mockSimulationEnabled: !isProduction && (env.MOCK_SIMULATION_ENABLED ?? true),
    resetEndpointEnabled: !isProduction,
  };
}
