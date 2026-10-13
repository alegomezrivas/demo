import type { RequestHandler } from 'express';
import { AppError } from '../../../../shared/errors/app-error.js';
import type { AuthenticateAccessToken } from '../../application/authenticate-access-token.js';

/** Identity attached to authenticated requests. */
export interface AuthContext {
  readonly userId: string;
}

declare module 'express-serve-static-core' {
  interface Request {
    auth?: AuthContext;
  }
}

const BEARER = /^Bearer ([A-Za-z0-9\-._~+/]+=*)$/;

/** Requires a valid bearer access token; other contexts use it to protect their routes. */
export function authenticate(useCase: AuthenticateAccessToken): RequestHandler {
  return async (req, _res, next) => {
    const match = BEARER.exec(req.headers.authorization ?? '');
    if (match?.[1] === undefined) {
      next(AppError.unauthorized());
      return;
    }
    const userId = await useCase.execute(match[1]);
    req.auth = { userId };
    next();
  };
}

/** Returns the authenticated user id; only call it behind [authenticate]. */
export function requireAuth(req: { readonly auth?: AuthContext }): AuthContext {
  if (req.auth === undefined) throw AppError.unauthorized();
  return req.auth;
}
