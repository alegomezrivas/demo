import type { User } from '../domain/user.js';
import type { UserRepository } from '../domain/user-repository.js';

export class InMemoryUserRepository implements UserRepository {
  private readonly byId = new Map<string, User>();
  private readonly idByEmail = new Map<string, string>();

  findById(id: string): Promise<User | undefined> {
    return Promise.resolve(this.byId.get(id));
  }

  findByEmail(email: string): Promise<User | undefined> {
    const id = this.idByEmail.get(email);
    return Promise.resolve(id === undefined ? undefined : this.byId.get(id));
  }

  add(user: User): Promise<boolean> {
    if (this.idByEmail.has(user.email)) return Promise.resolve(false);
    this.byId.set(user.id, user);
    this.idByEmail.set(user.email, user.id);
    return Promise.resolve(true);
  }

  /** Drops every user (used by the reset endpoint before re-seeding). */
  clear(): void {
    this.byId.clear();
    this.idByEmail.clear();
  }
}
