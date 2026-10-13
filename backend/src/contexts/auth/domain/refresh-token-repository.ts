import type { RefreshTokenRecord } from './refresh-token-record.js';

export interface RefreshTokenRepository {
  save(record: RefreshTokenRecord): Promise<void>;
  findByHash(tokenHash: string): Promise<RefreshTokenRecord | undefined>;
  /**
   * Atomically marks the record as used. Returns false when it was already used or
   * revoked, which callers must treat as a reuse attempt.
   */
  consume(id: string, at: Date): Promise<boolean>;
  /** Revokes every token of the family (idempotent). */
  revokeFamily(familyId: string, at: Date): Promise<void>;
}
