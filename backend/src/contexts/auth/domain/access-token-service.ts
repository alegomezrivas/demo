export interface AccessTokenClaims {
  readonly userId: string;
}

/** Issues and verifies short-lived access tokens. */
export interface AccessTokenService {
  issue(userId: string): Promise<string>;
  /** Throws `AppError.unauthorized` (`token_expired` or `unauthorized`) when invalid. */
  verify(token: string): Promise<AccessTokenClaims>;
}
