import type { IncomingHttpHeaders } from 'node:http';
import type { RequestHandler } from 'express';
import type { AccessTokenService } from '../../contexts/auth/domain/access-token-service.js';

/** Errors that can be forced with `X-Mock-Error`. */
export const FORCED_STATUSES = [500, 401, 403, 404, 422] as const;
type ForcedStatus = (typeof FORCED_STATUSES)[number];

/** What the headers ask for. */
export type MockError =
  | { readonly kind: 'status'; readonly status: ForcedStatus }
  | { readonly kind: 'timeout' }
  | { readonly kind: 'expire-once' };

export interface MockScenario {
  readonly latencyMs: number;
  readonly error: MockError | undefined;
}

export const MAX_LATENCY_MS = 60_000;

/** Equivalences for the header the Flutter app's own mock already uses. */
const APP_SCENARIOS: Readonly<Record<string, string>> = {
  server_error: '500',
  offline: 'timeout',
  unauthorized: '401',
  unauthorized_once: '401-once',
};

const BODIES: Readonly<Record<ForcedStatus, { code: string; message: string }>> = {
  500: { code: 'internal_error', message: 'Simulated server error.' },
  401: { code: 'unauthorized', message: 'Simulated authentication failure.' },
  403: { code: 'forbidden', message: 'Simulated forbidden response.' },
  404: { code: 'not_found', message: 'Simulated missing resource.' },
  422: { code: 'validation_error', message: 'Simulated validation failure.' },
};

function header(headers: IncomingHttpHeaders, name: string): string | undefined {
  const value = headers[name];
  return typeof value === 'string' ? value.trim().toLowerCase() : undefined;
}

function parseError(value: string | undefined): MockError | undefined {
  if (value === undefined) return undefined;
  if (value === 'timeout') return { kind: 'timeout' };
  if (value === '401-once') return { kind: 'expire-once' };
  const status = FORCED_STATUSES.find((candidate) => String(candidate) === value);
  return status === undefined ? undefined : { kind: 'status', status };
}

/**
 * Reads the simulation headers. `X-Mock-Error` wins over the app's `x-mock-scenario`;
 * unknown or malformed values are ignored and latency is capped.
 */
export function parseScenario(headers: IncomingHttpHeaders): MockScenario {
  const latency = header(headers, 'x-mock-latency');
  const latencyMs =
    latency !== undefined && /^\d{1,9}$/.test(latency)
      ? Math.min(Number(latency), MAX_LATENCY_MS)
      : 0;
  const appScenario = APP_SCENARIOS[header(headers, 'x-mock-scenario') ?? ''];
  return {
    latencyMs,
    error: parseError(header(headers, 'x-mock-error')) ?? parseError(appScenario),
  };
}

export interface MockSimulationOptions {
  readonly accessTokens: AccessTokenService;
  /** How long a `timeout` scenario holds the connection before dropping it. */
  readonly timeoutHoldMs?: number;
  /** Upper bound of remembered forced-401 tokens. */
  readonly maxTrackedTokens?: number;
}

const BEARER = /^Bearer ([A-Za-z0-9\-._~+/]+=*)$/;
const sleep = (ms: number): Promise<void> =>
  new Promise((resolve) => {
    setTimeout(resolve, ms);
  });

/**
 * Development/staging only: latency and forced errors driven by request headers.
 * It is never mounted in production (see `AppConfig.mockSimulationEnabled`).
 */
export function mockSimulation(options: MockSimulationOptions): RequestHandler {
  // Access tokens that already received their one forced 401.
  const expired = new Set<string>();
  const holdMs = options.timeoutHoldMs ?? 60_000;
  const maxTracked = options.maxTrackedTokens ?? 10_000;

  /** True when this request must receive the one-off 401 (and records it). */
  const shouldExpireOnce = async (authorization: string | undefined): Promise<boolean> => {
    const token = BEARER.exec(authorization ?? '')?.[1];
    if (token === undefined) return false;
    try {
      const claims = await options.accessTokens.verify(token);
      // Tokens minted by a refresh are the "new token" of the flow and always pass.
      if (claims.refreshed || expired.has(claims.tokenId)) return false;
      expired.add(claims.tokenId);
      if (expired.size > maxTracked) {
        const oldest = expired.values().next().value;
        if (oldest !== undefined) expired.delete(oldest);
      }
      return true;
    } catch {
      return false; // Invalid tokens are the real authentication's business.
    }
  };

  return async (req, res, next) => {
    const { latencyMs, error } = parseScenario(req.headers);
    if (latencyMs > 0) await sleep(latencyMs);

    if (error === undefined) {
      next();
    } else if (error.kind === 'status') {
      res.status(error.status).json(BODIES[error.status]);
    } else if (error.kind === 'timeout') {
      // Hold the connection past the client's receive timeout, then drop it.
      const timer = setTimeout(() => {
        res.destroy();
      }, holdMs);
      req.on('close', () => {
        clearTimeout(timer);
      });
    } else if (req.baseUrl === '/tasks' && (await shouldExpireOnce(req.headers.authorization))) {
      res.status(401).json({ code: 'token_expired', message: 'Simulated expired access token.' });
    } else {
      next();
    }
  };
}
