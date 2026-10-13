import express from 'express';
import { SignJWT } from 'jose';
import request from 'supertest';
import { beforeEach, describe, expect, it } from 'vitest';
import {
  authenticate,
  requireAuth,
} from '../../../../src/contexts/auth/presentation/http/authenticate.js';
import { errorHandler } from '../../../../src/shared/http/error-handler.js';
import { createLogger } from '../../../../src/shared/logging/logger.js';
import {
  buildTestContext,
  DEMO_CREDENTIALS,
  loginAs,
  signUp,
  TEST_SECRET,
  type TestContext,
} from '../../../helpers/test-app.js';

let ctx: TestContext;

/** Minimal app with one protected route, standing in for the real feature routes. */
function protectedApp(context: TestContext): express.Express {
  const app = express();
  app.get('/probe', authenticate(context.container.authenticate), (req, res) => {
    res.json({ userId: requireAuth(req).userId });
  });
  app.use(errorHandler(createLogger('silent')));
  return app;
}

beforeEach(async () => {
  ctx = await buildTestContext();
});

describe('complete authentication flow', () => {
  it('login -> protected access -> expiry -> refresh -> reuse -> logout', async () => {
    const probe = protectedApp(ctx);

    // Login and reach a protected route.
    const session = await loginAs(ctx.app);
    const ok = await request(probe)
      .get('/probe')
      .set('Authorization', `Bearer ${session.accessToken}`);
    expect(ok.status).toBe(200);
    expect(ok.body).toEqual({ userId: 'user-0' });

    // The access token expires on purpose.
    ctx.clock.advanceSeconds(ctx.config.jwt.accessTtlSeconds + 1);
    const expired = await request(probe)
      .get('/probe')
      .set('Authorization', `Bearer ${session.accessToken}`);
    expect(expired.status).toBe(401);
    expect(expired.body).toMatchObject({ code: 'token_expired' });

    // Refresh yields a working token and rotates the refresh token.
    const refreshed = await request(ctx.app)
      .post('/auth/refresh')
      .send({ refreshToken: session.refreshToken })
      .expect(200);
    const next = refreshed.body as { accessToken: string; refreshToken: string };
    const again = await request(probe)
      .get('/probe')
      .set('Authorization', `Bearer ${next.accessToken}`);
    expect(again.status).toBe(200);

    // Replaying the old refresh token is detected and kills the family.
    await request(ctx.app)
      .post('/auth/refresh')
      .send({ refreshToken: session.refreshToken })
      .expect(401);
    await request(ctx.app)
      .post('/auth/refresh')
      .send({ refreshToken: next.refreshToken })
      .expect(401);

    // Logout of a fresh session revokes it.
    const fresh = await loginAs(ctx.app);
    await request(ctx.app)
      .post('/auth/logout')
      .send({ refreshToken: fresh.refreshToken })
      .expect(204);
    await request(ctx.app)
      .post('/auth/refresh')
      .send({ refreshToken: fresh.refreshToken })
      .expect(401);
  });
});

describe('authenticate middleware', () => {
  async function probeWith(header?: string): Promise<request.Response> {
    const req = request(protectedApp(ctx)).get('/probe');
    return header === undefined ? req : req.set('Authorization', header);
  }

  it('rejects a missing header', async () => {
    const response = await probeWith();
    expect(response.status).toBe(401);
    expect(response.body).toMatchObject({ code: 'unauthorized' });
  });

  it.each(['Basic abc', 'Bearer', 'Bearer ', 'bearer lowercase', 'Bearer a b'])(
    'rejects the malformed header %j',
    async (header) => {
      expect((await probeWith(header)).status).toBe(401);
    },
  );

  it('rejects garbage tokens', async () => {
    expect((await probeWith('Bearer not.a.jwt')).status).toBe(401);
  });

  it('rejects a token signed with another secret', async () => {
    const forged = await new SignJWT({})
      .setProtectedHeader({ alg: 'HS256' })
      .setSubject('user-0')
      .setIssuer('stark-showcase-backend')
      .setAudience('stark-showcase-app')
      .setIssuedAt()
      .setExpirationTime('1h')
      .sign(new TextEncoder().encode('another-secret-another-secret-0123456789'));
    expect((await probeWith(`Bearer ${forged}`)).status).toBe(401);
  });

  it('rejects a token for another audience', async () => {
    const token = await new SignJWT({})
      .setProtectedHeader({ alg: 'HS256' })
      .setSubject('user-0')
      .setIssuer('stark-showcase-backend')
      .setAudience('somebody-else')
      .setExpirationTime('1h')
      .sign(new TextEncoder().encode(TEST_SECRET));
    expect((await probeWith(`Bearer ${token}`)).status).toBe(401);
  });

  it('rejects an unsigned (alg none) token', async () => {
    const header = Buffer.from('{"alg":"none","typ":"JWT"}').toString('base64url');
    const payload = Buffer.from('{"sub":"user-0"}').toString('base64url');
    expect((await probeWith(`Bearer ${header}.${payload}.`)).status).toBe(401);
  });

  it('rejects a token without subject', async () => {
    const token = await new SignJWT({})
      .setProtectedHeader({ alg: 'HS256' })
      .setIssuer('stark-showcase-backend')
      .setAudience('stark-showcase-app')
      .setExpirationTime('1h')
      .sign(new TextEncoder().encode(TEST_SECRET));
    expect((await probeWith(`Bearer ${token}`)).status).toBe(401);
  });

  it('rejects a valid token whose user no longer exists', async () => {
    const created = await signUp(ctx.app, { email: 'gone@example.com', username: 'gone' });
    expect(created.status).toBe(201);
    const { accessToken } = created.body as { accessToken: string };
    expect((await probeWith(`Bearer ${accessToken}`)).status).toBe(200);

    await ctx.container.reset();
    expect((await probeWith(`Bearer ${accessToken}`)).status).toBe(401);
  });

  it('requireAuth fails when the middleware did not run', () => {
    expect(() => requireAuth({})).toThrow();
  });
});

describe('container.reset', () => {
  it('restores the seed users and drops registered ones and sessions', async () => {
    const session = await loginAs(ctx.app);
    expect((await signUp(ctx.app, { email: 'temp@example.com', username: 'temp' })).status).toBe(
      201,
    );

    await ctx.container.reset();

    await request(ctx.app)
      .post('/auth/login')
      .send({ email: 'temp@example.com', password: 'Str0ng!Pass' })
      .expect(401);
    await request(ctx.app).post('/auth/login').send(DEMO_CREDENTIALS).expect(200);
    await request(ctx.app)
      .post('/auth/refresh')
      .send({ refreshToken: session.refreshToken })
      .expect(401);
    await request(ctx.app)
      .post('/auth/login')
      .send({ email: 'ana@starkshowcase.dev', password: 'Ana12345!' })
      .expect(200);
  });
});
