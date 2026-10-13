import { Writable } from 'node:stream';
import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { createLogger } from '../src/shared/logging/logger.js';
import { errorBodySchema } from '../src/shared/http/error-schemas.js';
import { buildTestContext, buildTestApp, DEMO_CREDENTIALS, loginAs } from './helpers/test-app.js';

function captureLogs(): { stream: Writable; text: () => string } {
  const lines: string[] = [];
  const stream = new Writable({
    write(chunk: Buffer, _encoding, done) {
      lines.push(chunk.toString());
      done();
    },
  });
  return { stream, text: () => lines.join('') };
}

describe('logging', () => {
  it('never writes passwords, tokens or the Authorization header', async () => {
    const logs = captureLogs();
    const { app } = await buildTestContext({}, { logger: createLogger('debug', logs.stream) });

    const registered = await request(app)
      .post('/auth/register')
      .send({ name: 'Log Test', email: 'log@example.com', password: 'Sup3r!Secret' })
      .expect(201);
    const { accessToken, refreshToken } = registered.body as {
      accessToken: string;
      refreshToken: string;
    };
    await request(app).post('/auth/login').send(DEMO_CREDENTIALS).expect(200);
    await request(app)
      .post('/auth/login')
      .send({ ...DEMO_CREDENTIALS, password: 'Bad1234!!' });
    await request(app).get('/tasks').set('Authorization', `Bearer ${accessToken}`).expect(200);
    await request(app).post('/auth/refresh').send({ refreshToken }).expect(200);
    await request(app).post('/auth/logout').send({ refreshToken });

    const output = logs.text();
    expect(output).toContain('request completed');
    for (const secret of ['Sup3r!Secret', 'Demo1234!', 'Bad1234!!', accessToken, refreshToken]) {
      expect(output).not.toContain(secret);
    }
    expect(output.toLowerCase()).not.toContain('bearer');
  });

  it('logs unexpected failures by name only', async () => {
    const logs = captureLogs();
    const { app, container } = await buildTestContext(
      {},
      { logger: createLogger('debug', logs.stream) },
    );
    const { accessToken } = await loginAs(app);
    // Force an internal failure inside a use case.
    container.tasks.list.execute = (): never => {
      throw new Error('db password is hunter2');
    };
    const response = await request(app).get('/tasks').set('Authorization', `Bearer ${accessToken}`);
    expect(response.status).toBe(500);
    expect(logs.text()).toContain('unhandled error');
    expect(logs.text()).not.toContain('hunter2');
    expect(JSON.stringify(response.body)).not.toContain('hunter2');
  });
});

describe('response hygiene', () => {
  it('forbids caching of token responses', async () => {
    const app = await buildTestApp();
    const login = await request(app).post('/auth/login').send(DEMO_CREDENTIALS);
    expect(login.headers['cache-control']).toBe('no-store');
    const failed = await request(app).post('/auth/login').send({});
    expect(failed.headers['cache-control']).toBe('no-store');
  });

  it('sends the standard helmet protections', async () => {
    const response = await request(await buildTestApp()).get('/health');
    expect(response.headers['strict-transport-security']).toBeDefined();
    expect(response.headers['x-frame-options']).toBeDefined();
    expect(response.headers['x-content-type-options']).toBe('nosniff');
    expect(response.headers['content-security-policy']).toContain("default-src 'self'");
    expect(response.headers['x-powered-by']).toBeUndefined();
  });

  it('never leaks stack traces or file paths in any error body', async () => {
    const app = await buildTestApp();
    const { accessToken } = await loginAs(app);
    const bearer = ['Authorization', `Bearer ${accessToken}`] as const;
    const responses = [
      await request(app).get('/nope'),
      await request(app).post('/auth/login').set('Content-Type', 'application/json').send('{bad'),
      await request(app).post('/auth/login').send({ email: 1 }),
      await request(app)
        .get('/tasks?page=x')
        .set(...bearer),
      await request(app)
        .get('/tasks/zzz')
        .set(...bearer),
      await request(app)
        .post('/tasks')
        .set(...bearer)
        .send('not json'),
    ];
    for (const response of responses) {
      expect(response.status).toBeGreaterThanOrEqual(400);
      errorBodySchema.parse(response.body);
      expect(JSON.stringify(response.body)).not.toMatch(/\.ts|node_modules|at .*\(|stack/i);
    }
  });

  it('rejects a non-JSON content type with a validation error instead of crashing', async () => {
    const app = await buildTestApp();
    const response = await request(app)
      .post('/auth/login')
      .set('Content-Type', 'text/plain')
      .send('email=a&password=b');
    expect(response.status).toBe(422);
  });

  it('does not treat JSON arrays or primitives as bodies', async () => {
    const app = await buildTestApp();
    for (const body of ['[]', '"text"', '42', 'null']) {
      const response = await request(app)
        .post('/auth/login')
        .set('Content-Type', 'application/json')
        .send(body);
      expect([400, 422]).toContain(response.status);
    }
  });

  it('keeps __proto__ pollution attempts out of validated input', async () => {
    const app = await buildTestApp();
    const response = await request(app)
      .post('/auth/register')
      .set('Content-Type', 'application/json')
      .send(
        '{"name":"A","email":"p@example.com","password":"Str0ng!Pass","__proto__":{"admin":true}}',
      );
    expect(response.status).toBe(422);
    expect(({} as Record<string, unknown>)['admin']).toBeUndefined();
  });
});
