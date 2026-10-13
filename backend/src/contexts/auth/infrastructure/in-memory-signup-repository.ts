import type {
  PendingCode,
  SignUpRepository,
  VerificationGrant,
} from '../domain/signup-repository.js';

export class InMemorySignUpRepository implements SignUpRepository {
  private readonly pending = new Map<string, PendingCode>();
  private readonly grants = new Map<string, VerificationGrant>();

  findPending(email: string): Promise<PendingCode | undefined> {
    return Promise.resolve(this.pending.get(email));
  }

  savePending(pending: PendingCode): Promise<void> {
    this.pending.set(pending.email, pending);
    return Promise.resolve();
  }

  deletePending(email: string): Promise<void> {
    this.pending.delete(email);
    return Promise.resolve();
  }

  registerFailedAttempt(email: string): Promise<PendingCode | undefined> {
    const current = this.pending.get(email);
    if (current === undefined) return Promise.resolve(undefined);
    const updated = { ...current, failedAttempts: current.failedAttempts + 1 };
    this.pending.set(email, updated);
    return Promise.resolve(updated);
  }

  saveGrant(grant: VerificationGrant): Promise<void> {
    this.grants.set(grant.tokenHash, grant);
    return Promise.resolve();
  }

  findGrant(tokenHash: string): Promise<VerificationGrant | undefined> {
    return Promise.resolve(this.grants.get(tokenHash));
  }

  deleteGrant(tokenHash: string): Promise<void> {
    this.grants.delete(tokenHash);
    return Promise.resolve();
  }

  /** Drops every pending code and grant (used by the reset endpoint). */
  clear(): void {
    this.pending.clear();
    this.grants.clear();
  }
}
