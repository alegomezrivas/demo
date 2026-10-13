import { randomBytes } from 'node:crypto';
import type { Clock } from '../../../shared/clock.js';
import { AppError } from '../../../shared/errors/app-error.js';
import type { SignUpRepository } from '../domain/signup-repository.js';
import { digestsEqual, sha256Hex } from './sha256.js';
import { SIGNUP_POLICY } from './signup-policy.js';

function invalidCode(code: string): AppError {
  return AppError.validation([{ field: 'code', issue: code }], code);
}

/** Checks the code and, when right, hands out a single-use proof of the e-mail. */
export class VerifySignUpCode {
  constructor(
    private readonly signUps: SignUpRepository,
    private readonly clock: Clock,
  ) {}

  /** Returns the opaque `verificationToken` that `register` redeems. */
  async execute(email: string, code: string): Promise<string> {
    const now = this.clock.now();
    const pending = await this.signUps.findPending(email);
    // An unknown e-mail answers like a wrong code: no way to probe pending sign-ups.
    if (pending === undefined) throw invalidCode('invalid_code');
    if (pending.expiresAt.getTime() <= now.getTime()) {
      await this.signUps.deletePending(email);
      throw invalidCode('code_expired');
    }

    if (!digestsEqual(pending.codeHash, sha256Hex(code))) {
      const updated = await this.signUps.registerFailedAttempt(email);
      if ((updated?.failedAttempts ?? 0) >= SIGNUP_POLICY.maxFailedAttempts) {
        await this.signUps.deletePending(email);
        throw AppError.rateLimited('too_many_attempts');
      }
      throw invalidCode('invalid_code');
    }

    await this.signUps.deletePending(email);
    const token = randomBytes(32).toString('base64url');
    await this.signUps.saveGrant({
      tokenHash: sha256Hex(token),
      email,
      expiresAt: new Date(now.getTime() + SIGNUP_POLICY.grantTtlSeconds * 1000),
    });
    return token;
  }
}
