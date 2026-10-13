import { randomUUID } from 'node:crypto';
import { AppError } from '../../../shared/errors/app-error.js';
import type { PasswordHasher } from '../domain/password-hasher.js';
import type { User } from '../domain/user.js';
import type { UserRepository } from '../domain/user-repository.js';
import type { SessionIssuer, TokenPair } from './session-issuer.js';

export interface RegisterUserInput {
  readonly name: string;
  readonly email: string;
  readonly password: string;
  readonly phone: string | null;
}

export interface AuthResult extends TokenPair {
  readonly user: User;
}

export class RegisterUser {
  constructor(
    private readonly users: UserRepository,
    private readonly hasher: PasswordHasher,
    private readonly sessions: SessionIssuer,
  ) {}

  async execute(input: RegisterUserInput): Promise<AuthResult> {
    const user: User = {
      id: randomUUID(),
      name: input.name,
      email: input.email,
      phone: input.phone,
      passwordHash: await this.hasher.hash(input.password),
    };
    // The repository enforces uniqueness atomically, so no check-then-insert race.
    if (!(await this.users.add(user))) throw AppError.conflict('email_taken');
    return { user, ...(await this.sessions.issue(user.id)) };
  }
}
