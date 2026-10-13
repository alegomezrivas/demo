import type { User } from './user.js';

/** Outcome of [UserRepository.add]. */
export type AddUserResult = 'added' | 'email_taken' | 'username_taken';

/** Persistence port for users; swap the in-memory adapter for a real database later. */
export interface UserRepository {
  findById(id: string): Promise<User | undefined>;
  findByEmail(email: string): Promise<User | undefined>;
  findByUsername(username: string): Promise<User | undefined>;
  /** Stores the user unless the e-mail or the username is already taken (atomic). */
  add(user: User): Promise<AddUserResult>;
}
