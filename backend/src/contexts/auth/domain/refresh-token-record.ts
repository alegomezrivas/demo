/**
 * Server-side state of one issued refresh token.
 *
 * Tokens form a family: every rotation creates a new record in the same family, so a
 * reused (already consumed) token can invalidate the whole chain.
 */
export interface RefreshTokenRecord {
  readonly id: string;
  readonly familyId: string;
  readonly userId: string;
  /** SHA-256 of the opaque token; the token itself is never stored. */
  readonly tokenHash: string;
  readonly expiresAt: Date;
  readonly usedAt: Date | null;
  readonly revokedAt: Date | null;
}
