import { randomUUID } from 'node:crypto';
import type { Clock } from '../../../shared/clock.js';
import { AppError } from '../../../shared/errors/app-error.js';
import type { PasswordHasher } from '../domain/password-hasher.js';
import type { SignUpRepository } from '../domain/signup-repository.js';
import type { User } from '../domain/user.js';
import type { UserRepository } from '../domain/user-repository.js';
import { sha256Hex } from './sha256.js';
import type { SessionIssuer, TokenPair } from './session-issuer.js';

export interface RegisterUserInput {
  /** Proof of a confirmed e-mail, from `POST /auth/signup/verify`. */
  readonly verificationToken: string;
  readonly name: string;
  readonly username: string;
  readonly password: string;
}

export interface AuthResult extends TokenPair {
  readonly user: User;
  readonly hasAvatar: boolean;
}

export class RegisterUser {
  constructor(
    private readonly users: UserRepository,
    private readonly signUps: SignUpRepository,
    private readonly hasher: PasswordHasher,
    private readonly sessions: SessionIssuer,
    private readonly clock: Clock,
  ) {}

  async execute(input: RegisterUserInput): Promise<AuthResult> {
    const tokenHash = sha256Hex(input.verificationToken);
    const grant = await this.signUps.findGrant(tokenHash);
    if (grant === undefined || grant.expiresAt.getTime() <= this.clock.now().getTime()) {
      throw AppError.validation(
        [{ field: 'verificationToken', issue: 'invalid_verification_token' }],
        'invalid_verification_token',
      );
    }

    const user: User = {
      id: randomUUID(),
      name: input.name,
      email: grant.email,
      username: input.username,
      passwordHash: await this.hasher.hash(input.password),
    };
    // The repository enforces uniqueness atomically, so no check-then-insert race.
    const result = await this.users.add(user);
    if (result !== 'added') throw AppError.conflict(result);

    // Redeemed only after success, so a taken username does not force a new e-mail check.
    await this.signUps.deleteGrant(tokenHash);
    return { user, hasAvatar: false, ...(await this.sessions.issue(user.id)) };
  }
}
