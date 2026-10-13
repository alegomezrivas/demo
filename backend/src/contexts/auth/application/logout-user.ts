import type { Clock } from '../../../shared/clock.js';
import type { RefreshTokenGenerator } from '../domain/refresh-token-generator.js';
import type { RefreshTokenRepository } from '../domain/refresh-token-repository.js';

/** Revokes the session behind a refresh token. Idempotent: unknown tokens are ignored. */
export class LogoutUser {
  constructor(
    private readonly refreshTokens: RefreshTokenRepository,
    private readonly generator: RefreshTokenGenerator,
    private readonly clock: Clock,
  ) {}

  async execute(refreshToken: string): Promise<void> {
    const record = await this.refreshTokens.findByHash(this.generator.hash(refreshToken));
    if (record !== undefined) {
      await this.refreshTokens.revokeFamily(record.familyId, this.clock.now());
    }
  }
}
