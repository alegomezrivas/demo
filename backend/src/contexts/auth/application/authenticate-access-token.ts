import { AppError } from '../../../shared/errors/app-error.js';
import type { AccessTokenService } from '../domain/access-token-service.js';
import type { UserRepository } from '../domain/user-repository.js';

/** Resolves a bearer token to the id of an existing user. */
export class AuthenticateAccessToken {
  constructor(
    private readonly accessTokens: AccessTokenService,
    private readonly users: UserRepository,
  ) {}

  async execute(token: string): Promise<string> {
    const { userId } = await this.accessTokens.verify(token);
    if ((await this.users.findById(userId)) === undefined) throw AppError.unauthorized();
    return userId;
  }
}
