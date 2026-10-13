/** Tunable limits of the sign-up flow, in one place. */
export const SIGNUP_POLICY = {
  /** How long a code can be confirmed. */
  codeTtlSeconds: 10 * 60,
  /** Wrong guesses allowed before the code is discarded. */
  maxFailedAttempts: 5,
  /** Minimum time between two sends to the same e-mail. */
  resendCooldownSeconds: 30,
  /** How long a confirmed e-mail may be used to create the account. */
  grantTtlSeconds: 30 * 60,
} as const;
