import type { Express } from 'express';
import request from 'supertest';
import { createApp } from '../../src/app.js';
import { createContainer, type Container } from '../../src/composition.js';
import { loadConfig, type AppConfig } from '../../src/config/env.js';
import { Argon2PasswordHasher } from '../../src/contexts/auth/infrastructure/argon2-password-hasher.js';
import type { Clock } from '../../src/shared/clock.js';
import { createLogger } from '../../src/shared/logging/logger.js';

export const TEST_SECRET = 'test-only-secret-test-only-secret-0123456789';

const BASE_ENV: NodeJS.ProcessEnv = {
  NODE_ENV: 'test',
  LOG_LEVEL: 'silent',
  JWT_ACCESS_SECRET: TEST_SECRET,
};

/** Clock whose time only moves when a test says so. */
export class FakeClock implements Clock {
  private current = new Date('2026-01-01T00:00:00.000Z');

  now(): Date {
    return new Date(this.current);
  }

  advanceSeconds(seconds: number): void {
    this.current = new Date(this.current.getTime() + seconds * 1000);
  }
}

/** Cheap argon2 settings so the suite stays fast. */
export const fastHasher = new Argon2PasswordHasher({ memoryCost: 1024, timeCost: 1 });

/** Builds a config for tests, optionally overriding environment variables. */
export function testConfig(overrides: NodeJS.ProcessEnv = {}): AppConfig {
  return loadConfig({ ...BASE_ENV, ...overrides });
}

export interface TestContext {
  readonly app: Express;
  readonly container: Container;
  readonly clock: FakeClock;
  readonly config: AppConfig;
}

/** Builds the whole app with fast hashing and a controllable clock. */
export async function buildTestContext(overrides: NodeJS.ProcessEnv = {}): Promise<TestContext> {
  const config = testConfig(overrides);
  const clock = new FakeClock();
  const container = await createContainer(config, { clock, passwordHasher: fastHasher });
  const app = createApp({ config, logger: createLogger('silent'), container });
  return { app, container, clock, config };
}

export async function buildTestApp(overrides: NodeJS.ProcessEnv = {}): Promise<Express> {
  return (await buildTestContext(overrides)).app;
}

export const DEMO_CREDENTIALS = { email: 'demo@starkshowcase.dev', password: 'Demo1234!' };

export interface Session {
  readonly accessToken: string;
  readonly refreshToken: string;
}

/** Logs in with the given credentials (demo user by default) and returns the tokens. */
export async function loginAs(
  app: Express,
  credentials: { email: string; password: string } = DEMO_CREDENTIALS,
): Promise<Session> {
  const response = await request(app).post('/auth/login').send(credentials).expect(200);
  const body = response.body as Session;
  return { accessToken: body.accessToken, refreshToken: body.refreshToken };
}
