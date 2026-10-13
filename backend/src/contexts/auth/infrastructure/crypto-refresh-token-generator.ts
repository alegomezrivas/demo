import { createHash, randomBytes } from 'node:crypto';
import type { RefreshTokenGenerator } from '../domain/refresh-token-generator.js';

/** 48 random bytes (384 bits) as base64url; stored only as a SHA-256 hash. */
export class CryptoRefreshTokenGenerator implements RefreshTokenGenerator {
  generate(): { readonly token: string; readonly hash: string } {
    const token = randomBytes(48).toString('base64url');
    return { token, hash: this.hash(token) };
  }

  hash(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }
}
