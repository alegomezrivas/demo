import type { Express } from 'express';
import request from 'supertest';
import { beforeAll, describe, expect, it } from 'vitest';
import {
  authResponseSchema,
  tokenPairResponseSchema,
} from '../../../../src/contexts/auth/presentation/http/auth-schemas.js';
import {
  buildTestContext,
  DEMO_CREDENTIALS,
  loginAs,
  type TestContext,
} from '../../../helpers/test-app.js';

const NEW_USER = {
  name: 'Lucía Pérez',
  email: 'lucia@example.com',
  password: 'Str0ng!Pass',
  phone: '+34600123456',
};

let ctx: TestContext;
let app: Express;

beforeAll(async () => {
  ctx = await buildTestContext();
  app = ctx.app;
});

describe('POST /auth/login', () => {
  it('returns the user and a token pair matching the contract', async () => {
    const response = await request(app).post('/auth/login').send(DEMO_CREDENTIALS);
    expect(response.status).toBe(200);
    const body = authResponseSchema.parse(response.body);
    expect(body.user).toEqual({
      id: 'user-0',
      name: 'Demo User',
      email: 'demo@starkshowcase.dev',
      phone: null,
    });
    expect(body.accessToken.split('.')).toHaveLength(3);
  });

  it('never exposes the password or its hash', async () => {
    const response = await request(app).post('/auth/login').send(DEMO_CREDENTIALS);
    expect(JSON.stringify(response.body)).not.toMatch(/argon2|passwordHash|Demo1234/);
  });

  it('matches the e-mail case-insensitively and ignoring surrounding spaces', async () => {
    const response = await request(app)
      .post('/auth/login')
      .send({ email: '  DEMO@StarkShowcase.dev ', password: DEMO_CREDENTIALS.password });
    expect(response.status).toBe(200);
  });

  it('answers 401 invalid_credentials for a wrong password', async () => {
    const response = await request(app)
      .post('/auth/login')
      .send({ email: DEMO_CREDENTIALS.email, password: 'Wrong1234!' });
    expect(response.status).toBe(401);
    expect(response.body).toMatchObject({ code: 'invalid_credentials' });
  });

  it('answers the same 401 for an unknown e-mail (no account enumeration)', async () => {
    const wrongPassword = await request(app)
      .post('/auth/login')
      .send({ email: DEMO_CREDENTIALS.email, password: 'Wrong1234!' });
    const unknownUser = await request(app)
      .post('/auth/login')
      .send({ email: 'nobody@example.com', password: 'Wrong1234!' });
    expect(unknownUser.status).toBe(401);
    expect(unknownUser.body).toEqual(wrongPassword.body);
  });

  it('does not enforce the password policy on login', async () => {
    const response = await request(app)
      .post('/auth/login')
      .send({ email: DEMO_CREDENTIALS.email, password: 'weak' });
    expect(response.status).toBe(401);
  });

  it.each([
    ['missing body', undefined],
    ['empty object', {}],
    ['missing password', { email: DEMO_CREDENTIALS.email }],
    ['invalid e-mail', { email: 'not-an-email', password: 'x' }],
    ['non-string password', { email: DEMO_CREDENTIALS.email, password: 123 }],
    ['unknown field', { ...DEMO_CREDENTIALS, admin: true }],
    ['oversized password', { email: DEMO_CREDENTIALS.email, password: 'a'.repeat(129) }],
  ])('answers 422 for %s', async (_name, body) => {
    const response = await request(app).post('/auth/login').send(body);
    expect(response.status).toBe(422);
    expect(response.body).toMatchObject({ code: 'validation_error' });
  });

  it('answers 404 for other methods', async () => {
    const response = await request(app).get('/auth/login');
    expect(response.status).toBe(404);
  });
});

describe('POST /auth/register', () => {
  it('creates the account (201) and the new user can log in', async () => {
    const response = await request(app).post('/auth/register').send(NEW_USER);
    expect(response.status).toBe(201);
    const body = authResponseSchema.parse(response.body);
    expect(body.user).toMatchObject({
      name: NEW_USER.name,
      email: NEW_USER.email,
      phone: NEW_USER.phone,
    });

    const login = await request(app)
      .post('/auth/login')
      .send({ email: NEW_USER.email, password: NEW_USER.password });
    expect(login.status).toBe(200);
  });

  it('stores phone as null when it is omitted or null', async () => {
    const omitted = await request(app)
      .post('/auth/register')
      .send({ name: 'A', email: 'omitted@example.com', password: 'Str0ng!Pass' });
    const explicit = await request(app)
      .post('/auth/register')
      .send({ name: 'B', email: 'explicit@example.com', password: 'Str0ng!Pass', phone: null });
    expect(omitted.status).toBe(201);
    expect(explicit.status).toBe(201);
    expect(authResponseSchema.parse(omitted.body).user.phone).toBeNull();
    expect(authResponseSchema.parse(explicit.body).user.phone).toBeNull();
  });

  it('normalizes the e-mail and trims the name', async () => {
    const response = await request(app)
      .post('/auth/register')
      .send({ name: '  Trim Me  ', email: ' Mixed.Case@Example.COM ', password: 'Str0ng!Pass' });
    expect(response.status).toBe(201);
    expect(response.body).toMatchObject({
      user: { name: 'Trim Me', email: 'mixed.case@example.com' },
    });
  });

  it('answers 409 email_taken for a duplicate, ignoring case', async () => {
    const response = await request(app)
      .post('/auth/register')
      .send({ ...NEW_USER, email: NEW_USER.email.toUpperCase() });
    expect(response.status).toBe(409);
    expect(response.body).toMatchObject({ code: 'email_taken' });
  });

  it('answers 409 for the seeded e-mail', async () => {
    const response = await request(app)
      .post('/auth/register')
      .send({ ...NEW_USER, email: DEMO_CREDENTIALS.email });
    expect(response.status).toBe(409);
  });

  it('reports every broken password rule per field', async () => {
    const response = await request(app)
      .post('/auth/register')
      .send({ name: 'Weak', email: 'weak@example.com', password: 'abc' });
    expect(response.status).toBe(422);
    expect(response.body).toMatchObject({ code: 'validation_error' });
    const issues = (response.body as { details: { field: string; issue: string }[] }).details
      .filter((detail) => detail.field === 'password')
      .map((detail) => detail.issue);
    expect(issues).toEqual(
      expect.arrayContaining(['too_small', 'missing_uppercase', 'missing_digit', 'missing_symbol']),
    );
    expect(issues).not.toContain('missing_lowercase');
  });

  it('never echoes the submitted password in the error', async () => {
    const response = await request(app)
      .post('/auth/register')
      .send({ name: 'Weak', email: 'weak2@example.com', password: 'secretvalue' });
    expect(response.status).toBe(422);
    expect(JSON.stringify(response.body)).not.toContain('secretvalue');
  });

  it.each([
    ['missing name', { email: 'a@example.com', password: 'Str0ng!Pass' }],
    ['blank name', { name: '   ', email: 'a@example.com', password: 'Str0ng!Pass' }],
    ['too long name', { name: 'n'.repeat(101), email: 'a@example.com', password: 'Str0ng!Pass' }],
    ['invalid e-mail', { name: 'A', email: 'nope', password: 'Str0ng!Pass' }],
    ['invalid phone', { name: 'A', email: 'a@example.com', password: 'Str0ng!Pass', phone: '12' }],
    [
      'empty phone string',
      { name: 'A', email: 'a@example.com', password: 'Str0ng!Pass', phone: '' },
    ],
    [
      'unknown field',
      { name: 'A', email: 'a@example.com', password: 'Str0ng!Pass', role: 'admin' },
    ],
    ['no body', undefined],
  ])('answers 422 for %s', async (_name, body) => {
    const response = await request(app).post('/auth/register').send(body);
    expect(response.status).toBe(422);
    expect(response.body).toMatchObject({ code: 'validation_error' });
  });
});

describe('POST /auth/refresh', () => {
  it('rotates the pair and matches the contract', async () => {
    const session = await loginAs(app);
    const response = await request(app)
      .post('/auth/refresh')
      .send({ refreshToken: session.refreshToken });
    expect(response.status).toBe(200);
    const pair = tokenPairResponseSchema.parse(response.body);
    expect(pair.refreshToken).not.toBe(session.refreshToken);
    expect(pair.accessToken).not.toBe(session.accessToken);
  });

  it('answers 401 invalid_refresh_token for an unknown token', async () => {
    const response = await request(app).post('/auth/refresh').send({ refreshToken: 'nope' });
    expect(response.status).toBe(401);
    expect(response.body).toMatchObject({ code: 'invalid_refresh_token' });
  });

  it('revokes the whole family when a consumed token is replayed', async () => {
    const session = await loginAs(app);
    const rotated = await request(app)
      .post('/auth/refresh')
      .send({ refreshToken: session.refreshToken })
      .expect(200);
    const newRefresh = (rotated.body as { refreshToken: string }).refreshToken;

    const replay = await request(app)
      .post('/auth/refresh')
      .send({ refreshToken: session.refreshToken });
    expect(replay.status).toBe(401);
    expect(replay.body).toMatchObject({ code: 'invalid_refresh_token' });

    // The legitimate descendant is revoked too, forcing a new login.
    const descendant = await request(app).post('/auth/refresh').send({ refreshToken: newRefresh });
    expect(descendant.status).toBe(401);
  });

  it('answers 401 once the refresh token has expired', async () => {
    const session = await loginAs(app);
    ctx.clock.advanceSeconds(ctx.config.jwt.refreshTtlSeconds + 1);
    const response = await request(app)
      .post('/auth/refresh')
      .send({ refreshToken: session.refreshToken });
    expect(response.status).toBe(401);
    expect(response.body).toMatchObject({ code: 'invalid_refresh_token' });
  });

  it('keeps independent sessions independent', async () => {
    const first = await loginAs(app);
    const second = await loginAs(app);
    await request(app).post('/auth/logout').send({ refreshToken: first.refreshToken }).expect(204);
    const response = await request(app)
      .post('/auth/refresh')
      .send({ refreshToken: second.refreshToken });
    expect(response.status).toBe(200);
  });

  it.each([
    ['no body', undefined],
    ['empty object', {}],
    ['non-string token', { refreshToken: 5 }],
    ['empty token', { refreshToken: '' }],
    ['oversized token', { refreshToken: 'a'.repeat(513) }],
    ['unknown field', { refreshToken: 'x', extra: 1 }],
  ])('answers 422 for %s', async (_name, body) => {
    const response = await request(app).post('/auth/refresh').send(body);
    expect(response.status).toBe(422);
  });
});

describe('POST /auth/logout', () => {
  it('answers 204 and revokes the refresh token', async () => {
    const session = await loginAs(app);
    const logout = await request(app)
      .post('/auth/logout')
      .send({ refreshToken: session.refreshToken });
    expect(logout.status).toBe(204);
    expect(logout.text).toBe('');

    const refresh = await request(app)
      .post('/auth/refresh')
      .send({ refreshToken: session.refreshToken });
    expect(refresh.status).toBe(401);
  });

  it('is idempotent: an already revoked token still answers 204', async () => {
    const session = await loginAs(app);
    await request(app)
      .post('/auth/logout')
      .send({ refreshToken: session.refreshToken })
      .expect(204);
    await request(app)
      .post('/auth/logout')
      .send({ refreshToken: session.refreshToken })
      .expect(204);
  });

  it('answers 204 for an unknown token', async () => {
    await request(app).post('/auth/logout').send({ refreshToken: 'never-issued' }).expect(204);
  });

  it('revokes descendants of a rotated token too', async () => {
    const session = await loginAs(app);
    const rotated = await request(app)
      .post('/auth/refresh')
      .send({ refreshToken: session.refreshToken })
      .expect(200);
    const newRefresh = (rotated.body as { refreshToken: string }).refreshToken;
    await request(app)
      .post('/auth/logout')
      .send({ refreshToken: session.refreshToken })
      .expect(204);
    await request(app).post('/auth/refresh').send({ refreshToken: newRefresh }).expect(401);
  });

  it('answers 422 without a token', async () => {
    const response = await request(app).post('/auth/logout').send({});
    expect(response.status).toBe(422);
  });
});
