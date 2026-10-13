import type { RequestHandler } from 'express';
import { rateLimit } from 'express-rate-limit';
import type { AppConfig } from '../../config/env.js';
import { AppError } from '../errors/app-error.js';

export interface RateLimiters {
  /** Applied to every route. */
  readonly general: RequestHandler;
  /** Stricter limit for login and register (credential guessing). */
  readonly credentials: RequestHandler;
  /** Stricter limit for refresh (token guessing). */
  readonly refresh: RequestHandler;
}

function limiter(windowSeconds: number, max: number): RequestHandler {
  return rateLimit({
    windowMs: windowSeconds * 1000,
    limit: max,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    // Same uniform body as every other error (and a Retry-After header from the lib).
    handler: (_req, _res, next) => {
      next(AppError.rateLimited());
    },
  });
}

/** One independent counter per limiter and client IP (in memory). */
export function createRateLimiters({ rateLimit: limits }: AppConfig): RateLimiters {
  return {
    general: limiter(limits.windowSeconds, limits.max),
    credentials: limiter(limits.windowSeconds, limits.authMax),
    refresh: limiter(limits.windowSeconds, limits.refreshMax),
  };
}
