import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { errorBodySchema } from '../../../src/shared/http/error-schemas.js';
import { buildTestContext } from '../../helpers/test-app.js';

const LOGIN = { email: 'demo@starkshowcase.dev', password: 'Wrong1234!' };

describe('rate limiting', () => {
  it('throttles login attempts per IP with the uniform error body', async () => {
    const { app } = await buildTestContext({ RATE_LIMIT_AUTH_MAX: '3' });
    for (let attempt = 0; attempt < 3; attempt += 1) {
      expect((await request(app).post('/auth/login').send(LOGIN)).status).toBe(401);
    }
    const blocked = await request(app).post('/auth/login').send(LOGIN);
    expect(blocked.status).toBe(429);
    expect(errorBodySchema.parse(blocked.body)).toMatchObject({ code: 'rate_limited' });
    expect(blocked.headers['retry-after']).toBeDefined();
    expect(blocked.headers['ratelimit']).toBeDefined();
  });

  it('shares the credentials budget between login and register', async () => {
    const { app } = await buildTestContext({ RATE_LIMIT_AUTH_MAX: '2' });
    await request(app).post('/auth/login').send(LOGIN);
    await request(app).post('/auth/register').send({});
    const blocked = await request(app).post('/auth/register').send({});
    expect(blocked.status).toBe(429);
  });

  it('throttles refresh independently of login', async () => {
    const { app } = await buildTestContext({ RATE_LIMIT_REFRESH_MAX: '2' });
    for (let attempt = 0; attempt < 2; attempt += 1) {
      expect((await request(app).post('/auth/refresh').send({ refreshToken: 'x' })).status).toBe(
        401,
      );
    }
    expect((await request(app).post('/auth/refresh').send({ refreshToken: 'x' })).status).toBe(429);
    // Login has its own, untouched budget.
    expect((await request(app).post('/auth/login').send(LOGIN)).status).toBe(401);
  });

  it('applies a general limit to the other routes but never to /health', async () => {
    const { app } = await buildTestContext({ RATE_LIMIT_MAX: '2' });
    expect((await request(app).get('/tasks')).status).toBe(401);
    expect((await request(app).get('/tasks')).status).toBe(401);
    expect((await request(app).get('/tasks')).status).toBe(429);
    for (let i = 0; i < 5; i += 1) {
      expect((await request(app).get('/health')).status).toBe(200);
    }
  });

  it('counts failures and successes alike', async () => {
    const { app } = await buildTestContext({ RATE_LIMIT_AUTH_MAX: '2' });
    const good = { email: LOGIN.email, password: 'Demo1234!' };
    expect((await request(app).post('/auth/login').send(good)).status).toBe(200);
    expect((await request(app).post('/auth/login').send(good)).status).toBe(200);
    expect((await request(app).post('/auth/login').send(good)).status).toBe(429);
  });
});
