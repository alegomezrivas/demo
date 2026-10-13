import { AppError } from '../../../shared/errors/app-error.js';
import type { Clock } from '../../../shared/clock.js';
import type { RefreshTokenGenerator } from '../domain/refresh-token-generator.js';
import type { RefreshTokenRepository } from '../domain/refresh-token-repository.js';
import type { UserRepository } from '../domain/user-repository.js';
import type { SessionIssuer, TokenPair } from './session-issuer.js';

const INVALID = 'invalid_refresh_token';

/** Exchanges a refresh token for a new pair, rotating it and detecting reuse. */
export class RefreshSession {
  constructor(
    private readonly users: UserRepository,
    private readonly refreshTokens: RefreshTokenRepository,
    private readonly generator: RefreshTokenGenerator,
    private readonly sessions: SessionIssuer,
    private readonly clock: Clock,
  ) {}

  async execute(refreshToken: string): Promise<TokenPair> {
    const now = this.clock.now();
    const record = await this.refreshTokens.findByHash(this.generator.hash(refreshToken));
    if (record === undefined || record.revokedAt !== null) throw AppError.unauthorized(INVALID);
    if (record.expiresAt.getTime() <= now.getTime()) throw AppError.unauthorized(INVALID);

    // consume() is atomic: false means the token was already rotated, so someone is
    // replaying it. Revoke the whole family to lock out the thief and the victim alike.
    if (!(await this.refreshTokens.consume(record.id, now))) {
      await this.refreshTokens.revokeFamily(record.familyId, now);
      throw AppError.unauthorized(INVALID);
    }

    if ((await this.users.findById(record.userId)) === undefined) {
      throw AppError.unauthorized(INVALID);
    }
    return this.sessions.issue(record.userId, record.familyId);
  }
}
