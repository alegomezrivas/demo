import { describe, expect, it } from 'vitest';
import { ConfigError, loadConfig } from '../../src/config/env.js';

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
