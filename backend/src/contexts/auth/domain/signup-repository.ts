/** Code waiting to be confirmed for an e-mail address. */
export interface PendingCode {
  readonly email: string;
  readonly codeHash: string;
  readonly expiresAt: Date;
  readonly sentAt: Date;
  readonly failedAttempts: number;
}

/** Proof that an e-mail address was confirmed; redeemed once by `register`. */
export interface VerificationGrant {
  readonly tokenHash: string;
  readonly email: string;
  readonly expiresAt: Date;
}

/** Storage port for the sign-up steps that happen before the account exists. */
export interface SignUpRepository {
  findPending(email: string): Promise<PendingCode | undefined>;
  /** Replaces any previous code for the same e-mail. */
  savePending(pending: PendingCode): Promise<void>;
  deletePending(email: string): Promise<void>;
  /** Records a wrong guess and returns the updated pending code. */
  registerFailedAttempt(email: string): Promise<PendingCode | undefined>;
  saveGrant(grant: VerificationGrant): Promise<void>;
  findGrant(tokenHash: string): Promise<VerificationGrant | undefined>;
  deleteGrant(tokenHash: string): Promise<void>;
}
