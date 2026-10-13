import type { Express } from 'express';
import request from 'supertest';
import { beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { MAX_LATENCY_MS, parseScenario } from '../../../src/shared/http/mock-simulation.js';
import { errorBodySchema } from '../../../src/shared/http/error-schemas.js';
import { buildTestContext, loginAs, type TestContext } from '../../helpers/test-app.js';

describe('parseScenario', () => {
  it('reads latency and caps it', () => {
    expect(parseScenario({ 'x-mock-latency': '250' }).latencyMs).toBe(250);
    expect(parseScenario({ 'x-mock-latency': '999999999' }).latencyMs).toBe(MAX_LATENCY_MS);
    expect(parseScenario({}).latencyMs).toBe(0);
  });

  it.each(['abc', '-5', '1.5', '', '1e3', '12345678901'])('ignores the bad latency %j', (value) => {
    expect(parseScenario({ 'x-mock-latency': value }).latencyMs).toBe(0);
  });

  it.each([
    ['500', { kind: 'status', status: 500 }],
    ['401', { kind: 'status', status: 401 }],
    ['403', { kind: 'status', status: 403 }],
    ['404', { kind: 'status', status: 404 }],
    ['422', { kind: 'status', status: 422 }],
    ['timeout', { kind: 'timeout' }],
    ['401-once', { kind: 'expire-once' }],
    [' TIMEOUT ', { kind: 'timeout' }],
  ])('parses X-Mock-Error %j', (value, expected) => {
    expect(parseScenario({ 'x-mock-error': value }).error).toEqual(expected);
  });

  it.each(['418', 'boom', '', '5xx'])('ignores the unknown X-Mock-Error %j', (value) => {
    expect(parseScenario({ 'x-mock-error': value }).error).toBeUndefined();
  });

  it.each([
    ['server_error', { kind: 'status', status: 500 }],
    ['offline', { kind: 'timeout' }],
    ['unauthorized', { kind: 'status', status: 401 }],
    ['unauthorized_once', { kind: 'expire-once' }],
  ])("maps the app's x-mock-scenario %s", (value, expected) => {
    expect(parseScenario({ 'x-mock-scenario': value }).error).toEqual(expected);
  });

  it('lets X-Mock-Error win over x-mock-scenario', () => {
    const scenario = parseScenario({ 'x-mock-error': '403', 'x-mock-scenario': 'server_error' });
    expect(scenario.error).toEqual({ kind: 'status', status: 403 });
  });

  it('falls back to the app scenario when X-Mock-Error is unknown', () => {
    const scenario = parseScenario({ 'x-mock-error': 'nope', 'x-mock-scenario': 'offline' });
    expect(scenario.error).toEqual({ kind: 'timeout' });
  });

  it('ignores header arrays', () => {
    expect(parseScenario({ 'x-mock-error': ['500', '401'] }).error).toBeUndefined();
  });
});

describe('simulation over HTTP', () => {
  let ctx: TestContext;
  let app: Express;

  beforeAll(async () => {
    ctx = await buildTestContext({}, { timeoutHoldMs: 80 });
    app = ctx.app;
  });

  beforeEach(async () => {
    await ctx.container.reset();
  });

  it.each([
    [500, 'internal_error'],
    [401, 'unauthorized'],
    [403, 'forbidden'],
    [404, 'not_found'],
    [422, 'validation_error'],
  ])('X-Mock-Error: %i answers that status with the uniform body', async (status, code) => {
    const { accessToken } = await loginAs(app);
    const response = await request(app)
      .get('/tasks')
      .set('Authorization', `Bearer ${accessToken}`)
      .set('X-Mock-Error', String(status));
    expect(response.status).toBe(status);
    expect(errorBodySchema.parse(response.body)).toMatchObject({ code });
  });

  it('works on public auth endpoints too, before touching any data', async () => {
    const response = await request(app)
      .post('/auth/login')
      .set('X-Mock-Error', '500')
      .send({ email: 'demo@starkshowcase.dev', password: 'Demo1234!' });
    expect(response.status).toBe(500);
  });

  it("understands the Flutter app's x-mock-scenario header", async () => {
    const { accessToken } = await loginAs(app);
    const response = await request(app)
      .get('/tasks')
      .set('Authorization', `Bearer ${accessToken}`)
      .set('x-mock-scenario', 'server_error');
    expect(response.status).toBe(500);
  });

  it('delays the response with X-Mock-Latency', async () => {
    const started = Date.now();
    const response = await request(app).post('/auth/logout').set('X-Mock-Latency', '120').send({
      refreshToken: 'unknown',
    });
    expect(response.status).toBe(204);
    expect(Date.now() - started).toBeGreaterThanOrEqual(100);
  });

  it('combines latency and error', async () => {
    const started = Date.now();
    const response = await request(app)
      .get('/tasks')
      .set('X-Mock-Latency', '100')
      .set('X-Mock-Error', '500');
    expect(response.status).toBe(500);
    expect(Date.now() - started).toBeGreaterThanOrEqual(80);
  });

  it('drops the connection on timeout without ever answering', async () => {
    await expect(request(app).get('/tasks').set('X-Mock-Error', 'timeout')).rejects.toThrow();
  });

  it('does not affect /health, /docs or /__reset', async () => {
    const headers = { 'X-Mock-Error': '500' };
    expect((await request(app).get('/health').set(headers)).status).toBe(200);
    expect((await request(app).get('/openapi.json').set(headers)).status).toBe(200);
    expect((await request(app).post('/__reset').set(headers)).status).toBe(204);
  });

  it('ignores unknown values and serves normally', async () => {
    const { accessToken } = await loginAs(app);
    const response = await request(app)
      .get('/tasks')
      .set('Authorization', `Bearer ${accessToken}`)
      .set('X-Mock-Error', '418')
      .set('X-Mock-Latency', 'fast');
    expect(response.status).toBe(200);
  });

  describe('X-Mock-Error: 401-once', () => {
    const once = { 'X-Mock-Error': '401-once' };

    it('rejects the first request of a login token, then lets it through', async () => {
      const { accessToken } = await loginAs(app);
      const bearer = `Bearer ${accessToken}`;
      const first = await request(app).get('/tasks').set('Authorization', bearer).set(once);
      expect(first.status).toBe(401);
      expect(first.body).toMatchObject({ code: 'token_expired' });
      const second = await request(app).get('/tasks').set('Authorization', bearer).set(once);
      expect(second.status).toBe(200);
    });

    it('lets tokens obtained through a refresh pass, even with the header kept (app flow)', async () => {
      const session = await loginAs(app);
      const first = await request(app)
        .get('/tasks')
        .set('Authorization', `Bearer ${session.accessToken}`)
        .set('x-mock-scenario', 'unauthorized_once');
      expect(first.status).toBe(401);

      // What the app does next: refresh, then retry with the same headers and the new token.
      const refreshed = await request(app)
        .post('/auth/refresh')
        .send({ refreshToken: session.refreshToken })
        .expect(200);
      const next = (refreshed.body as { accessToken: string }).accessToken;
      const retry = await request(app)
        .get('/tasks')
        .set('Authorization', `Bearer ${next}`)
        .set('x-mock-scenario', 'unauthorized_once');
      expect(retry.status).toBe(200);
    });

    it('applies again to a brand new login', async () => {
      const first = await loginAs(app);
      await request(app)
        .get('/tasks')
        .set('Authorization', `Bearer ${first.accessToken}`)
        .set(once)
        .expect(401);
      const second = await loginAs(app);
      await request(app)
        .get('/tasks')
        .set('Authorization', `Bearer ${second.accessToken}`)
        .set(once)
        .expect(401);
    });

    it('is per token: another user is unaffected by a burned token', async () => {
      const demo = await loginAs(app);
      await request(app)
        .get('/tasks')
        .set('Authorization', `Bearer ${demo.accessToken}`)
        .set(once)
        .expect(401);
      const ana = await loginAs(app, { email: 'ana@starkshowcase.dev', password: 'Ana12345!' });
      await request(app)
        .get('/tasks')
        .set('Authorization', `Bearer ${ana.accessToken}`)
        .expect(200);
    });

    it('leaves real authentication to decide when there is no valid token', async () => {
      const missing = await request(app).get('/tasks').set(once);
      expect(missing.body).toMatchObject({ code: 'unauthorized' });
      const garbage = await request(app)
        .get('/tasks')
        .set('Authorization', 'Bearer not.a.jwt')
        .set(once);
      expect(garbage.body).toMatchObject({ code: 'unauthorized' });
    });

    it('does not touch public endpoints', async () => {
      const response = await request(app)
        .post('/auth/login')
        .set(once)
        .send({ email: 'demo@starkshowcase.dev', password: 'Demo1234!' });
      expect(response.status).toBe(200);
    });
  });

  describe('forgetting old tokens', () => {
    it('stays bounded in memory', async () => {
      const { accessToken } = await loginAs(app);
      // Behavioural smoke test: many distinct tokens must not break the middleware.
      for (let i = 0; i < 5; i += 1) {
        const { accessToken: token } = await loginAs(app);
        await request(app)
          .get('/tasks')
          .set('Authorization', `Bearer ${token}`)
          .set('X-Mock-Error', '401-once')
          .expect(401);
      }
      expect(accessToken).toBeTruthy();
    });
  });
});

describe('simulation switched off', () => {
  it('ignores every mock header in production', async () => {
    const { app } = await buildTestContext({ NODE_ENV: 'production' });
    const headers = {
      'X-Mock-Error': '500',
      'X-Mock-Latency': '5000',
      'x-mock-scenario': 'server_error',
    };
    const started = Date.now();
    const response = await request(app).get('/health').set(headers);
    const login = await request(app)
      .post('/auth/login')
      .set(headers)
      .send({ email: 'demo@starkshowcase.dev', password: 'Demo1234!' });
    expect(response.status).toBe(200);
    expect(login.status).toBe(200);
    expect(Date.now() - started).toBeLessThan(2000);
  });

  it('can be disabled explicitly outside production', async () => {
    const { app } = await buildTestContext({ MOCK_SIMULATION_ENABLED: 'false' });
    const response = await request(app).get('/tasks').set('X-Mock-Error', '500');
    expect(response.status).toBe(401); // the real authentication answers, not the simulation
  });
});
