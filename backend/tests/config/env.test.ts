import { describe, expect, it } from 'vitest';
import {
  ConfigError,
  DEFAULT_CONFIRMATION_CODE,
  loadConfig,
  startupWarnings,
} from '../../src/config/env.js';

const SECRET = 'x'.repeat(32);

describe('loadConfig', () => {
  it('applies defaults', () => {
    const config = loadConfig({ JWT_ACCESS_SECRET: SECRET });
    expect(config).toMatchObject({
      env: 'development',
      port: 5556,
      bodyLimit: '10kb',
      trustProxy: false,
      corsAllowedOrigins: [],
      mockSimulationEnabled: true,
      resetEndpointEnabled: true,
    });
    expect(config.jwt.accessTtlSeconds).toBe(900);
  });

  it('parses the CORS origin list', () => {
    const config = loadConfig({
      JWT_ACCESS_SECRET: SECRET,
      CORS_ALLOWED_ORIGINS: ' https://a.test , ,https://b.test',
    });
    expect(config.corsAllowedOrigins).toEqual(['https://a.test', 'https://b.test']);
  });

  it('fails fast without the JWT secret and never echoes values', () => {
    expect(() => loadConfig({})).toThrow(ConfigError);
    try {
      loadConfig({ JWT_ACCESS_SECRET: 'short-but-secret' });
      expect.unreachable();
    } catch (error) {
      expect(error).toBeInstanceOf(ConfigError);
      expect((error as ConfigError).message).toContain('JWT_ACCESS_SECRET');
      expect((error as ConfigError).message).not.toContain('short-but-secret');
    }
  });

  it('rejects invalid values', () => {
    expect(() => loadConfig({ JWT_ACCESS_SECRET: SECRET, PORT: '70000' })).toThrow(ConfigError);
    expect(() => loadConfig({ JWT_ACCESS_SECRET: SECRET, NODE_ENV: 'qa' })).toThrow(ConfigError);
    expect(() => loadConfig({ JWT_ACCESS_SECRET: SECRET, BODY_LIMIT: 'huge' })).toThrow(
      ConfigError,
    );
  });

  it('disables simulation and reset in production', () => {
    const config = loadConfig({ JWT_ACCESS_SECRET: SECRET, NODE_ENV: 'production' });
    expect(config.isProduction).toBe(true);
    expect(config.mockSimulationEnabled).toBe(false);
    expect(config.resetEndpointEnabled).toBe(false);
  });

  it('refuses to start with simulation enabled in production', () => {
    expect(() =>
      loadConfig({
        JWT_ACCESS_SECRET: SECRET,
        NODE_ENV: 'production',
        MOCK_SIMULATION_ENABLED: 'true',
      }),
    ).toThrow(ConfigError);
  });

  it('allows turning simulation off in development', () => {
    const config = loadConfig({ JWT_ACCESS_SECRET: SECRET, MOCK_SIMULATION_ENABLED: 'false' });
    expect(config.mockSimulationEnabled).toBe(false);
  });
});

describe('confirmation code configuration', () => {
  const base = { JWT_ACCESS_SECRET: SECRET };

  it('defaults to the documented demo code outside production', () => {
    for (const NODE_ENV of ['development', 'test', 'staging']) {
      expect(loadConfig({ ...base, NODE_ENV }).fixedConfirmationCode).toBe(
        DEFAULT_CONFIRMATION_CODE,
      );
    }
    expect(DEFAULT_CONFIRMATION_CODE).toBe('123456');
  });

  it('can be overridden outside production', () => {
    const config = loadConfig({ ...base, FIXED_CONFIRMATION_CODE: '246810' });
    expect(config.fixedConfirmationCode).toBe('246810');
  });

  it('is absent in production unless set on purpose', () => {
    expect(loadConfig({ ...base, NODE_ENV: 'production' }).fixedConfirmationCode).toBeUndefined();
    expect(
      loadConfig({ ...base, NODE_ENV: 'production', FIXED_CONFIRMATION_CODE: '135790' })
        .fixedConfirmationCode,
    ).toBe('135790');
  });

  it.each(['12345', '1234567', 'abcdef', '12 456', ''])('rejects %j', (value) => {
    expect(() => loadConfig({ ...base, FIXED_CONFIRMATION_CODE: value })).toThrow(ConfigError);
  });

  it('never echoes the configured value in the error', () => {
    try {
      loadConfig({ ...base, FIXED_CONFIRMATION_CODE: '12ab56' });
      expect.unreachable();
    } catch (error) {
      expect((error as ConfigError).message).toContain('FIXED_CONFIRMATION_CODE');
      expect((error as ConfigError).message).not.toContain('12ab56');
    }
  });
});

describe('startupWarnings', () => {
  const base = { JWT_ACCESS_SECRET: SECRET };

  it('warns in production when a fixed code is set, without printing it', () => {
    const warnings = startupWarnings(
      loadConfig({ ...base, NODE_ENV: 'production', FIXED_CONFIRMATION_CODE: '135790' }),
    );
    expect(warnings).toHaveLength(1);
    expect(warnings.join(' ')).toContain('FIXED_CONFIRMATION_CODE');
    expect(warnings.join(' ')).not.toContain('135790');
  });

  it('is quiet in production without a fixed code', () => {
    expect(startupWarnings(loadConfig({ ...base, NODE_ENV: 'production' }))).toEqual([]);
  });

  it('is quiet outside production, where the fixed code is expected', () => {
    expect(startupWarnings(loadConfig(base))).toEqual([]);
    expect(startupWarnings(loadConfig({ ...base, NODE_ENV: 'staging' }))).toEqual([]);
  });
});
