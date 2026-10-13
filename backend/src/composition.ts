import type { AppConfig } from './config/env.js';
import { AuthenticateAccessToken } from './contexts/auth/application/authenticate-access-token.js';
import { LoginUser } from './contexts/auth/application/login-user.js';
import { LogoutUser } from './contexts/auth/application/logout-user.js';
import { RefreshSession } from './contexts/auth/application/refresh-session.js';
import { RegisterUser } from './contexts/auth/application/register-user.js';
import { SessionIssuer } from './contexts/auth/application/session-issuer.js';
import type { AccessTokenService } from './contexts/auth/domain/access-token-service.js';
import type { PasswordHasher } from './contexts/auth/domain/password-hasher.js';
import { Argon2PasswordHasher } from './contexts/auth/infrastructure/argon2-password-hasher.js';
import { CryptoRefreshTokenGenerator } from './contexts/auth/infrastructure/crypto-refresh-token-generator.js';
import { InMemoryRefreshTokenRepository } from './contexts/auth/infrastructure/in-memory-refresh-token-repository.js';
import { InMemoryUserRepository } from './contexts/auth/infrastructure/in-memory-user-repository.js';
import { JoseAccessTokenService } from './contexts/auth/infrastructure/jose-access-token-service.js';
import type { AuthUseCases } from './contexts/auth/presentation/http/auth-controller.js';
import {
  CreateTask,
  DeleteTask,
  GetTask,
  GetTaskStats,
  ListTasks,
  UpdateTask,
} from './contexts/tasks/application/task-use-cases.js';
import { InMemoryTaskRepository } from './contexts/tasks/infrastructure/in-memory-task-repository.js';
import type { TaskUseCases } from './contexts/tasks/presentation/http/task-controller.js';
import { buildSeedTasks } from './seed/tasks.js';
import { buildSeedUsers } from './seed/users.js';
import { SystemClock, type Clock } from './shared/clock.js';

export interface Container {
  readonly auth: AuthUseCases;
  readonly tasks: TaskUseCases;
  readonly authenticate: AuthenticateAccessToken;
  /** Exposed for the dev/staging simulation middleware. */
  readonly accessTokens: AccessTokenService;
  /** Restores the seed data (used by `POST /__reset`). */
  reset(): Promise<void>;
}

export interface ContainerOverrides {
  readonly clock?: Clock;
  readonly passwordHasher?: PasswordHasher;
}

/** Composition root: the only place that knows the concrete adapters. */
export async function createContainer(
  config: AppConfig,
  overrides: ContainerOverrides = {},
): Promise<Container> {
  const clock = overrides.clock ?? new SystemClock();
  const hasher = overrides.passwordHasher ?? new Argon2PasswordHasher();

  const users = new InMemoryUserRepository();
  const refreshTokens = new InMemoryRefreshTokenRepository();
  const generator = new CryptoRefreshTokenGenerator();
  const accessTokens = new JoseAccessTokenService(
    config.jwt.accessSecret,
    config.jwt.accessTtlSeconds,
    clock,
  );
  const sessions = new SessionIssuer(
    accessTokens,
    refreshTokens,
    generator,
    clock,
    config.jwt.refreshTtlSeconds,
  );

  const tasks = new InMemoryTaskRepository();

  const seed = async (): Promise<void> => {
    for (const user of await buildSeedUsers(hasher)) await users.add(user);
    tasks.load(buildSeedTasks(clock.now()));
  };
  await seed();

  return {
    tasks: {
      list: new ListTasks(tasks),
      get: new GetTask(tasks),
      create: new CreateTask(tasks, clock),
      update: new UpdateTask(tasks),
      remove: new DeleteTask(tasks),
      stats: new GetTaskStats(tasks, clock),
    },
    auth: {
      register: new RegisterUser(users, hasher, sessions),
      login: new LoginUser(users, hasher, sessions),
      refresh: new RefreshSession(users, refreshTokens, generator, sessions, clock),
      logout: new LogoutUser(refreshTokens, generator, clock),
    },
    authenticate: new AuthenticateAccessToken(accessTokens, users),
    accessTokens,
    async reset() {
      users.clear();
      refreshTokens.clear();
      await seed();
      // Tasks are replaced wholesale by seed(), so nothing else to clear.
    },
  };
}
