import type { User } from '../domain/user.js';
import type { AddUserResult, UserRepository } from '../domain/user-repository.js';

export class InMemoryUserRepository implements UserRepository {
  private readonly byId = new Map<string, User>();
  private readonly idByEmail = new Map<string, string>();
  private readonly idByUsername = new Map<string, string>();

  findById(id: string): Promise<User | undefined> {
    return Promise.resolve(this.byId.get(id));
  }

  findByEmail(email: string): Promise<User | undefined> {
    return Promise.resolve(this.resolve(this.idByEmail.get(email)));
  }

  findByUsername(username: string): Promise<User | undefined> {
    return Promise.resolve(this.resolve(this.idByUsername.get(username)));
  }

  add(user: User): Promise<AddUserResult> {
    if (this.idByEmail.has(user.email)) return Promise.resolve('email_taken');
    if (this.idByUsername.has(user.username)) return Promise.resolve('username_taken');
    this.byId.set(user.id, user);
    this.idByEmail.set(user.email, user.id);
    this.idByUsername.set(user.username, user.id);
    return Promise.resolve('added');
  }

  /** Drops every user (used by the reset endpoint before re-seeding). */
  clear(): void {
    this.byId.clear();
    this.idByEmail.clear();
    this.idByUsername.clear();
  }

  private resolve(id: string | undefined): User | undefined {
    return id === undefined ? undefined : this.byId.get(id);
  }
}
