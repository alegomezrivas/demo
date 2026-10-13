import { randomUUID } from 'node:crypto';
import type { Clock } from '../../../shared/clock.js';
import type { AccessTokenService } from '../domain/access-token-service.js';
import type { RefreshTokenGenerator } from '../domain/refresh-token-generator.js';
import type { RefreshTokenRepository } from '../domain/refresh-token-repository.js';

export interface TokenPair {
  readonly accessToken: string;
  readonly refreshToken: string;
}

/** Creates a new access token plus a persisted refresh token. */
export class SessionIssuer {
  constructor(
    private readonly accessTokens: AccessTokenService,
    private readonly refreshTokens: RefreshTokenRepository,
    private readonly generator: RefreshTokenGenerator,
    private readonly clock: Clock,
    private readonly refreshTtlSeconds: number,
  ) {}

  /** Issues a pair; pass [familyId] when rotating so the chain stays linked. */
  async issue(userId: string, familyId: string = randomUUID()): Promise<TokenPair> {
    const { token, hash } = this.generator.generate();
    const expiresAt = new Date(this.clock.now().getTime() + this.refreshTtlSeconds * 1000);
    await this.refreshTokens.save({
      id: randomUUID(),
      familyId,
      userId,
      tokenHash: hash,
      expiresAt,
      usedAt: null,
      revokedAt: null,
    });
    return { accessToken: await this.accessTokens.issue(userId), refreshToken: token };
  }
}
