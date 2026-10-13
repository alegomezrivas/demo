import { AppError } from '../../../shared/errors/app-error.js';
import type { PasswordHasher } from '../domain/password-hasher.js';
import type { UserRepository } from '../domain/user-repository.js';
import type { AuthResult } from './register-user.js';
import type { SessionIssuer } from './session-issuer.js';

export interface LoginInput {
  readonly email: string;
  readonly password: string;
}

export class LoginUser {
  /** Verified when the e-mail is unknown, so both failures cost the same time. */
  private dummyHash: Promise<string> | undefined;

  constructor(
    private readonly users: UserRepository,
    private readonly hasher: PasswordHasher,
    private readonly sessions: SessionIssuer,
  ) {}

  async execute(input: LoginInput): Promise<AuthResult> {
    const user = await this.users.findByEmail(input.email);
    const hash = user?.passwordHash ?? (await this.getDummyHash());
    const matches = await this.hasher.verify(hash, input.password);
    // Same error for unknown e-mail and wrong password: no account enumeration.
    if (user === undefined || !matches) throw AppError.unauthorized('invalid_credentials');
    return { user, ...(await this.sessions.issue(user.id)) };
  }

  private getDummyHash(): Promise<string> {
    this.dummyHash ??= this.hasher.hash('not-a-real-password');
    return this.dummyHash;
  }
}
