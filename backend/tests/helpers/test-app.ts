import type { Express } from 'express';
import { createApp } from '../../src/app.js';
import { loadConfig, type AppConfig } from '../../src/config/env.js';
import { createLogger } from '../../src/shared/logging/logger.js';

const BASE_ENV: NodeJS.ProcessEnv = {
  NODE_ENV: 'test',
  LOG_LEVEL: 'silent',
  JWT_ACCESS_SECRET: 'test-only-secret-test-only-secret-0123456789',
};

/** Builds a config for tests, optionally overriding environment variables. */
export function testConfig(overrides: NodeJS.ProcessEnv = {}): AppConfig {
  return loadConfig({ ...BASE_ENV, ...overrides });
}

/** Builds the Express app with a silent logger. */
export function buildTestApp(overrides: NodeJS.ProcessEnv = {}): Express {
  const config = testConfig(overrides);
  return createApp({ config, logger: createLogger('silent') });
}
