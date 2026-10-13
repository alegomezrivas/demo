import type { UserRepository } from '../domain/user-repository.js';

export class CheckUsernameAvailability {
  constructor(private readonly users: UserRepository) {}

  async execute(username: string): Promise<boolean> {
    return (await this.users.findByUsername(username)) === undefined;
  }
}
