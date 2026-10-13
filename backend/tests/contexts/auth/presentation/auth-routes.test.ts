import type { Express } from 'express';
import request from 'supertest';
import { beforeAll, describe, expect, it } from 'vitest';
import { SIGNUP_POLICY } from '../../../../src/contexts/auth/application/signup-policy.js';
import {
  authResponseSchema,
  tokenPairResponseSchema,
  usernameAvailabilityResponseSchema,
  verificationResponseSchema,
} from '../../../../src/contexts/auth/presentation/http/auth-schemas.js';
import {
  buildTestContext,
  CONFIRMATION_CODE,
  confirmEmail,
  DEMO_CREDENTIALS,
  loginAs,
  signUp,
  type TestContext,
} from '../../../helpers/test-app.js';

const NEW_USER = {
  name: 'Lucía Pérez',
  email: 'lucia@example.com',
  username: 'lucia.perez',
  password: 'Str0ng!Pass',
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
      username: 'demo',
      hasAvatar: false,
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
    const response = await signUp(app, NEW_USER);
    expect(response.status).toBe(201);
    const body = authResponseSchema.parse(response.body);
    expect(body.user).toMatchObject({
      name: NEW_USER.name,
      email: NEW_USER.email,
      username: NEW_USER.username,
      hasAvatar: false,
    });
    expect(body.user).not.toHaveProperty('phone');

    const login = await request(app)
      .post('/auth/login')
      .send({ email: NEW_USER.email, password: NEW_USER.password });
    expect(login.status).toBe(200);
  });

  it('normalizes the e-mail, the username and trims the name', async () => {
    const response = await signUp(app, {
      name: '  Trim Me  ',
      email: ' Mixed.Case@Example.COM ',
      username: '  Mixed.Name ',
    });
    expect(response.status).toBe(201);
    expect(response.body).toMatchObject({
      user: { name: 'Trim Me', email: 'mixed.case@example.com', username: 'mixed.name' },
    });
  });

  it('takes the e-mail from the verification token, not from the body', async () => {
    const verificationToken = await confirmEmail(app, 'bound@example.com');
    const response = await request(app).post('/auth/register').send({
      verificationToken,
      name: 'Bound',
      username: 'bound',
      password: 'Str0ng!Pass',
      email: 'other@example.com',
    });
    expect(response.status).toBe(422);
    expect(response.body).toMatchObject({ code: 'validation_error' });
  });

  it('answers 409 username_taken, ignoring case, and keeps the token usable', async () => {
    const verificationToken = await confirmEmail(app, 'second@example.com');
    const taken = await request(app).post('/auth/register').send({
      verificationToken,
      name: 'Dup',
      username: NEW_USER.username.toUpperCase(),
      password: 'Str0ng!Pass',
    });
    expect(taken.status).toBe(409);
    expect(taken.body).toMatchObject({ code: 'username_taken' });

    const retry = await request(app).post('/auth/register').send({
      verificationToken,
      name: 'Dup',
      username: 'second_try',
      password: 'Str0ng!Pass',
    });
    expect(retry.status).toBe(201);
  });

  it('accepts a verification token only once', async () => {
    const verificationToken = await confirmEmail(app, 'once@example.com');
    const body = { verificationToken, name: 'Once', username: 'once', password: 'Str0ng!Pass' };
    await request(app).post('/auth/register').send(body).expect(201);

    const again = await request(app)
      .post('/auth/register')
      .send({ ...body, username: 'once_again' });
    expect(again.status).toBe(422);
    expect(again.body).toMatchObject({ code: 'invalid_verification_token' });
  });

  it('rejects an unknown token', async () => {
    const response = await request(app).post('/auth/register').send({
      verificationToken: 'made-up',
      name: 'Nope',
      username: 'nope',
      password: 'Str0ng!Pass',
    });
    expect(response.status).toBe(422);
    expect(response.body).toMatchObject({ code: 'invalid_verification_token' });
  });

  it('rejects an expired token', async () => {
    const verificationToken = await confirmEmail(app, 'late@example.com');
    ctx.clock.advanceSeconds(SIGNUP_POLICY.grantTtlSeconds + 1);
    const response = await request(app).post('/auth/register').send({
      verificationToken,
      name: 'Late',
      username: 'late',
      password: 'Str0ng!Pass',
    });
    expect(response.status).toBe(422);
    expect(response.body).toMatchObject({ code: 'invalid_verification_token' });
  });

  it('reports every broken password rule per field', async () => {
    const response = await signUp(app, {
      email: 'weak@example.com',
      username: 'weak',
      password: 'abc',
    });
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
    const response = await signUp(app, {
      email: 'weak2@example.com',
      username: 'weak2',
      password: 'secretvalue',
    });
    expect(response.status).toBe(422);
    expect(JSON.stringify(response.body)).not.toContain('secretvalue');
  });

  const valid = {
    verificationToken: 't',
    name: 'A',
    username: 'valid_name',
    password: 'Str0ng!Pass',
  };
  it.each([
    ['missing name', { ...valid, name: undefined }],
    ['blank name', { ...valid, name: '   ' }],
    ['too long name', { ...valid, name: 'n'.repeat(101) }],
    ['missing username', { ...valid, username: undefined }],
    ['too short username', { ...valid, username: 'ab' }],
    ['too long username', { ...valid, username: 'a'.repeat(31) }],
    ['username with spaces', { ...valid, username: 'two words' }],
    ['username with symbols', { ...valid, username: 'bad@name' }],
    ['username ending with a dot', { ...valid, username: 'name.' }],
    ['username starting with a dot', { ...valid, username: '.name' }],
    ['missing token', { ...valid, verificationToken: undefined }],
    ['removed phone field', { ...valid, phone: '+34600123456' }],
    ['removed birthdate field', { ...valid, birthdate: '2000-01-01' }],
    ['unknown field', { ...valid, admin: true }],
    ['no body', undefined],
  ])('answers 422 for %s', async (_name, body) => {
    const response = await request(app).post('/auth/register').send(body);
    expect(response.status).toBe(422);
    expect(response.body).toMatchObject({ code: 'validation_error' });
  });

  it('answers 409 email_taken if the address got registered meanwhile', async () => {
    const verificationToken = await confirmEmail(app, 'race@example.com');
    await signUp(app, { email: 'race@example.com', username: 'race_one' });
    const response = await request(app).post('/auth/register').send({
      verificationToken,
      name: 'Race',
      username: 'race_two',
      password: 'Str0ng!Pass',
    });
    expect(response.status).toBe(409);
    expect(response.body).toMatchObject({ code: 'email_taken' });
  });
});

describe('sign-up: sending the code', () => {
  it('answers 204 with no body', async () => {
    const response = await request(app)
      .post('/auth/signup/email')
      .send({ email: 'new@example.com' });
    expect(response.status).toBe(204);
    expect(response.text).toBe('');
  });

  it('answers 409 email_taken for registered addresses, ignoring case', async () => {
    const response = await request(app)
      .post('/auth/signup/email')
      .send({ email: DEMO_CREDENTIALS.email.toUpperCase() });
    expect(response.status).toBe(409);
    expect(response.body).toMatchObject({ code: 'email_taken' });
  });

  it.each([
    ['invalid e-mail', { email: 'nope' }],
    ['missing e-mail', {}],
    ['extra field', { email: 'a@example.com', extra: 1 }],
  ])('answers 422 for %s', async (_name, body) => {
    expect((await request(app).post('/auth/signup/email').send(body)).status).toBe(422);
  });

  it('refuses to resend too soon, then allows it after the cooldown', async () => {
    const email = 'resend@example.com';
    await request(app).post('/auth/signup/email').send({ email }).expect(204);

    const early = await request(app).post('/auth/signup/code/resend').send({ email });
    expect(early.status).toBe(429);
    expect(early.body).toMatchObject({ code: 'resend_too_soon' });

    ctx.clock.advanceSeconds(SIGNUP_POLICY.resendCooldownSeconds);
    await request(app).post('/auth/signup/code/resend').send({ email }).expect(204);
  });

  it('resends even if no code was requested before', async () => {
    await request(app)
      .post('/auth/signup/code/resend')
      .send({ email: 'fresh@example.com' })
      .expect(204);
  });

  it('answers 409 when resending to a registered address', async () => {
    const response = await request(app)
      .post('/auth/signup/code/resend')
      .send({ email: DEMO_CREDENTIALS.email });
    expect(response.status).toBe(409);
  });
});

describe('sign-up: confirming the code', () => {
  const post = (body: object) => request(app).post('/auth/signup/verify').send(body);

  it('returns a verification token for the right code', async () => {
    const email = 'verify@example.com';
    await request(app).post('/auth/signup/email').send({ email }).expect(204);
    const response = await post({ email, code: CONFIRMATION_CODE });
    expect(response.status).toBe(200);
    expect(
      verificationResponseSchema.parse(response.body).verificationToken.length,
    ).toBeGreaterThan(20);
  });

  it('rejects a wrong code with invalid_code', async () => {
    const email = 'wrong@example.com';
    await request(app).post('/auth/signup/email').send({ email }).expect(204);
    const response = await post({ email, code: '000000' });
    expect(response.status).toBe(422);
    expect(response.body).toMatchObject({ code: 'invalid_code' });
  });

  it('answers an unknown e-mail like a wrong code', async () => {
    const response = await post({ email: 'unknown@example.com', code: CONFIRMATION_CODE });
    expect(response.status).toBe(422);
    expect(response.body).toMatchObject({ code: 'invalid_code' });
  });

  it('accepts a code only once', async () => {
    const email = 'single@example.com';
    await request(app).post('/auth/signup/email').send({ email }).expect(204);
    await post({ email, code: CONFIRMATION_CODE }).then((r) => {
      expect(r.status).toBe(200);
    });
    expect((await post({ email, code: CONFIRMATION_CODE })).status).toBe(422);
  });

  it('expires the code after ten minutes', async () => {
    const email = 'expire@example.com';
    await request(app).post('/auth/signup/email').send({ email }).expect(204);
    ctx.clock.advanceSeconds(SIGNUP_POLICY.codeTtlSeconds);
    const response = await post({ email, code: CONFIRMATION_CODE });
    expect(response.status).toBe(422);
    expect(response.body).toMatchObject({ code: 'code_expired' });
  });

  it('discards the code after too many wrong guesses, even if the next one is right', async () => {
    const email = 'brute@example.com';
    await request(app).post('/auth/signup/email').send({ email }).expect(204);
    for (let i = 1; i < SIGNUP_POLICY.maxFailedAttempts; i += 1) {
      expect((await post({ email, code: '000000' })).status).toBe(422);
    }
    const last = await post({ email, code: '000000' });
    expect(last.status).toBe(429);
    expect(last.body).toMatchObject({ code: 'too_many_attempts' });

    const afterwards = await post({ email, code: CONFIRMATION_CODE });
    expect(afterwards.status).toBe(422);
    expect(afterwards.body).toMatchObject({ code: 'invalid_code' });
  });

  it('a new code resets the failed attempts', async () => {
    const email = 'reset-attempts@example.com';
    await request(app).post('/auth/signup/email').send({ email }).expect(204);
    await post({ email, code: '000000' });
    ctx.clock.advanceSeconds(SIGNUP_POLICY.resendCooldownSeconds);
    await request(app).post('/auth/signup/code/resend').send({ email }).expect(204);
    expect((await post({ email, code: CONFIRMATION_CODE })).status).toBe(200);
  });

  it.each([
    ['short code', { email: 'a@example.com', code: '123' }],
    ['non-numeric code', { email: 'a@example.com', code: 'abcdef' }],
    ['missing code', { email: 'a@example.com' }],
  ])('answers 422 for %s', async (_name, body) => {
    expect((await post(body)).status).toBe(422);
  });
});

describe('GET /auth/username-available', () => {
  it('reports free and taken usernames, ignoring case', async () => {
    const free = await request(app).get('/auth/username-available?username=free_name');
    expect(free.status).toBe(200);
    expect(usernameAvailabilityResponseSchema.parse(free.body)).toEqual({ available: true });

    const taken = await request(app).get('/auth/username-available?username=DEMO');
    expect(usernameAvailabilityResponseSchema.parse(taken.body)).toEqual({ available: false });
  });

  it.each(['', 'ab', 'bad name', 'x'.repeat(31)])('answers 422 for %j', async (username) => {
    const response = await request(app).get('/auth/username-available').query({ username });
    expect(response.status).toBe(422);
  });

  it('answers 422 without the parameter', async () => {
    expect((await request(app).get('/auth/username-available')).status).toBe(422);
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
