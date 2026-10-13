import * as argon2 from 'argon2';
import type { PasswordHasher } from '../domain/password-hasher.js';

export interface Argon2Options {
  readonly memoryCost: number;
  readonly timeCost: number;
}

/** OWASP-recommended argon2id baseline (19 MiB, 2 iterations). */
export const DEFAULT_ARGON2_OPTIONS: Argon2Options = { memoryCost: 19_456, timeCost: 2 };

export class Argon2PasswordHasher implements PasswordHasher {
  constructor(private readonly options: Argon2Options = DEFAULT_ARGON2_OPTIONS) {}

  hash(plain: string): Promise<string> {
    return argon2.hash(plain, {
      type: argon2.argon2id,
      memoryCost: this.options.memoryCost,
      timeCost: this.options.timeCost,
      parallelism: 1,
    });
  }

  async verify(hash: string, plain: string): Promise<boolean> {
    try {
      return await argon2.verify(hash, plain);
    } catch {
      // A malformed stored hash must behave like a wrong password.
      return false;
    }
  }
}
