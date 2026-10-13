export interface AccessTokenClaims {
  readonly userId: string;
  /** Unique id of this token (JWT `jti`). */
  readonly tokenId: string;
  /** True when the token was minted by a refresh rather than by a login. */
  readonly refreshed: boolean;
}

export interface IssueOptions {
  readonly refreshed?: boolean;
}

/** Issues and verifies short-lived access tokens. */
export interface AccessTokenService {
  issue(userId: string, options?: IssueOptions): Promise<string>;
  /** Throws `AppError.unauthorized` (`token_expired` or `unauthorized`) when invalid. */
  verify(token: string): Promise<AccessTokenClaims>;
}
