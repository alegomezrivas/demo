import type { PasswordHasher } from '../contexts/auth/domain/password-hasher.js';
import type { User } from '../contexts/auth/domain/user.js';

/** Test accounts documented in the README; these are fixtures, not real secrets. */
export const SEED_USERS = [
  {
    id: 'user-0',
    name: 'Demo User',
    email: 'demo@starkshowcase.dev',
    phone: null,
    password: 'Demo1234!',
  },
  {
    id: 'user-1',
    name: 'Ana Gómez',
    email: 'ana@starkshowcase.dev',
    phone: '+34600111222',
    password: 'Ana12345!',
  },
] as const;

export async function buildSeedUsers(hasher: PasswordHasher): Promise<User[]> {
  return Promise.all(
    SEED_USERS.map(async ({ password, ...profile }) => ({
      ...profile,
      passwordHash: await hasher.hash(password),
    })),
  );
}
