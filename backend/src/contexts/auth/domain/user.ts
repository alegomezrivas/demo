/** Registered person. The password is only ever stored as a hash. */
export interface User {
  readonly id: string;
  readonly name: string;
  /** Normalized (trimmed, lower-case) and unique. */
  readonly email: string;
  /** Public identifier: lower-case, unique, 3-30 characters of `a-z 0-9 . _`. */
  readonly username: string;
  readonly passwordHash: string;
}
