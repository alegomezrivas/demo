import type { RefreshTokenRecord } from '../domain/refresh-token-record.js';
import type { RefreshTokenRepository } from '../domain/refresh-token-repository.js';

export class InMemoryRefreshTokenRepository implements RefreshTokenRepository {
  private readonly byId = new Map<string, RefreshTokenRecord>();
  private readonly idByHash = new Map<string, string>();

  save(record: RefreshTokenRecord): Promise<void> {
    this.byId.set(record.id, record);
    this.idByHash.set(record.tokenHash, record.id);
    return Promise.resolve();
  }

  findByHash(tokenHash: string): Promise<RefreshTokenRecord | undefined> {
    const id = this.idByHash.get(tokenHash);
    return Promise.resolve(id === undefined ? undefined : this.byId.get(id));
  }

  consume(id: string, at: Date): Promise<boolean> {
    const record = this.byId.get(id);
    // No await between the check and the write, so this is atomic on a single thread.
    if (record === undefined || record.usedAt !== null || record.revokedAt !== null) {
      return Promise.resolve(false);
    }
    this.byId.set(id, { ...record, usedAt: at });
    return Promise.resolve(true);
  }

  revokeFamily(familyId: string, at: Date): Promise<void> {
    for (const [id, record] of this.byId) {
      if (record.familyId === familyId && record.revokedAt === null) {
        this.byId.set(id, { ...record, revokedAt: at });
      }
    }
    return Promise.resolve();
  }

  /** Drops every token (used by the reset endpoint). */
  clear(): void {
    this.byId.clear();
    this.idByHash.clear();
  }
}
