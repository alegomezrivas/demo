/** Registered person. The password is only ever stored as a hash. */
export interface User {
  readonly id: string;
  readonly name: string;
  /** Normalized (trimmed, lower-case) and unique. */
  readonly email: string;
  readonly phone: string | null;
  readonly passwordHash: string;
}
