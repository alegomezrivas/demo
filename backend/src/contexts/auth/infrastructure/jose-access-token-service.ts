import { randomUUID } from 'node:crypto';
import { errors, jwtVerify, SignJWT } from 'jose';
import type { Clock } from '../../../shared/clock.js';
import { AppError } from '../../../shared/errors/app-error.js';
import type {
  AccessTokenClaims,
  AccessTokenService,
  IssueOptions,
} from '../domain/access-token-service.js';

const ISSUER = 'stark-showcase-backend';
const AUDIENCE = 'stark-showcase-app';

/** HS256 JWT access tokens. The secret comes from the environment only. */
export class JoseAccessTokenService implements AccessTokenService {
  private readonly key: Uint8Array;

  constructor(
    secret: string,
    private readonly ttlSeconds: number,
    private readonly clock: Clock,
  ) {
    this.key = new TextEncoder().encode(secret);
  }

  issue(userId: string, options: IssueOptions = {}): Promise<string> {
    const issuedAt = Math.floor(this.clock.now().getTime() / 1000);
    // `rfr` marks tokens minted by a refresh; the mock simulation uses it to apply
    // the one-off forced 401 only to tokens that come from a login.
    return new SignJWT(options.refreshed === true ? { rfr: true } : {})
      .setProtectedHeader({ alg: 'HS256' })
      .setSubject(userId)
      .setIssuer(ISSUER)
      .setAudience(AUDIENCE)
      .setJti(randomUUID())
      .setIssuedAt(issuedAt)
      .setExpirationTime(issuedAt + this.ttlSeconds)
      .sign(this.key);
  }

  async verify(token: string): Promise<AccessTokenClaims> {
    try {
      const { payload } = await jwtVerify(token, this.key, {
        algorithms: ['HS256'],
        issuer: ISSUER,
        audience: AUDIENCE,
        currentDate: this.clock.now(),
      });
      if (typeof payload.sub !== 'string' || payload.sub.length === 0) {
        throw AppError.unauthorized();
      }
      return {
        userId: payload.sub,
        tokenId: payload.jti ?? '',
        refreshed: payload['rfr'] === true,
      };
    } catch (error) {
      if (error instanceof AppError) throw error;
      throw AppError.unauthorized(error instanceof errors.JWTExpired ? 'token_expired' : undefined);
    }
  }
}
