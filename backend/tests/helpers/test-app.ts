import type { Express } from 'express';
import request from 'supertest';
import { createApp } from '../../src/app.js';
import { createContainer, type Container } from '../../src/composition.js';
import { loadConfig, type AppConfig } from '../../src/config/env.js';
import { Argon2PasswordHasher } from '../../src/contexts/auth/infrastructure/argon2-password-hasher.js';
import type { Clock } from '../../src/shared/clock.js';
import { createLogger, type Logger } from '../../src/shared/logging/logger.js';

export const TEST_SECRET = 'test-only-secret-test-only-secret-0123456789';

const BASE_ENV: NodeJS.ProcessEnv = {
  NODE_ENV: 'test',
  LOG_LEVEL: 'silent',
  JWT_ACCESS_SECRET: TEST_SECRET,
  // Effectively unlimited so functional tests are not throttled; rate-limit tests lower them.
  RATE_LIMIT_MAX: '1000000',
  RATE_LIMIT_AUTH_MAX: '1000000',
  RATE_LIMIT_REFRESH_MAX: '1000000',
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
export async function buildTestContext(
  overrides: NodeJS.ProcessEnv = {},
  extras: { timeoutHoldMs?: number; logger?: Logger } = {},
): Promise<TestContext> {
  const config = testConfig(overrides);
  const clock = new FakeClock();
  const container = await createContainer(config, { clock, passwordHasher: fastHasher });
  const app = createApp({
    config,
    logger: extras.logger ?? createLogger('silent'),
    container,
    ...(extras.timeoutHoldMs === undefined
      ? {}
      : { simulation: { timeoutHoldMs: extras.timeoutHoldMs } }),
  });
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

/** The code every e-mail accepts outside production (see `FIXED_CONFIRMATION_CODE`). */
export const CONFIRMATION_CODE = '123456';

/** Runs sign-up steps 1 and 2 for [email] and returns the `verificationToken`. */
export async function confirmEmail(app: Express, email: string): Promise<string> {
  await request(app).post('/auth/signup/email').send({ email }).expect(204);
  const verified = await request(app)
    .post('/auth/signup/verify')
    .send({ email, code: CONFIRMATION_CODE })
    .expect(200);
  return (verified.body as { verificationToken: string }).verificationToken;
}

export interface NewAccount {
  readonly email: string;
  readonly username: string;
  readonly name?: string;
  readonly password?: string;
}

/** Full sign-up (confirm the e-mail, then register); returns the register response. */
export async function signUp(app: Express, account: NewAccount): Promise<request.Response> {
  const verificationToken = await confirmEmail(app, account.email);
  return request(app)
    .post('/auth/register')
    .send({
      verificationToken,
      name: account.name ?? 'Test User',
      username: account.username,
      password: account.password ?? 'Str0ng!Pass',
    });
}
