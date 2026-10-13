import type { Clock } from '../../../shared/clock.js';
import { AppError } from '../../../shared/errors/app-error.js';
import type {
  ConfirmationCodeGenerator,
  ConfirmationCodeSender,
} from '../domain/confirmation-code.js';
import type { SignUpRepository } from '../domain/signup-repository.js';
import type { UserRepository } from '../domain/user-repository.js';
import { sha256Hex } from './sha256.js';
import { SIGNUP_POLICY } from './signup-policy.js';

/**
 * Sends a confirmation code to an e-mail address. Used both for the first send
 * (`resend = false`) and for "send it again", which is throttled per address.
 */
export class SendSignUpCode {
  constructor(
    private readonly users: UserRepository,
    private readonly signUps: SignUpRepository,
    private readonly generator: ConfirmationCodeGenerator,
    private readonly sender: ConfirmationCodeSender,
    private readonly clock: Clock,
  ) {}

  async execute(email: string, { resend }: { resend: boolean }): Promise<void> {
    if ((await this.users.findByEmail(email)) !== undefined) throw AppError.conflict('email_taken');

    const now = this.clock.now();
    const previous = await this.signUps.findPending(email);
    if (resend && previous !== undefined) {
      const waitedMs = now.getTime() - previous.sentAt.getTime();
      if (waitedMs < SIGNUP_POLICY.resendCooldownSeconds * 1000) {
        throw AppError.rateLimited('resend_too_soon');
      }
    }

    const code = this.generator.generate();
    await this.signUps.savePending({
      email,
      codeHash: sha256Hex(code),
      expiresAt: new Date(now.getTime() + SIGNUP_POLICY.codeTtlSeconds * 1000),
      sentAt: now,
      failedAttempts: 0,
    });
    await this.sender.send(email, code);
  }
}
