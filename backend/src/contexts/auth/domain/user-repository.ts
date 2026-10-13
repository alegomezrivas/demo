import type { User } from './user.js';

/** Persistence port for users; swap the in-memory adapter for a real database later. */
export interface UserRepository {
  findById(id: string): Promise<User | undefined>;
  findByEmail(email: string): Promise<User | undefined>;
  /** Stores the user; returns false when the e-mail is already taken. */
  add(user: User): Promise<boolean>;
}
