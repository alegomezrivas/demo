import type { Express } from 'express';
import request from 'supertest';
import { beforeEach, describe, expect, it } from 'vitest';
import {
  AVATAR_MAX_BYTES,
  isJpeg,
} from '../../../../src/contexts/users/application/avatar-use-cases.js';
import { errorBodySchema } from '../../../../src/shared/http/error-schemas.js';
import {
  buildTestContext,
  DEMO_CREDENTIALS,
  loginAs,
  signUp,
  type TestContext,
} from '../../../helpers/test-app.js';

/** Smallest byte sequence the validator accepts as a JPEG. */
function fakeJpeg(size = 64): Buffer {
  const bytes = Buffer.alloc(size, 0x11);
  bytes[0] = 0xff;
  bytes[1] = 0xd8;
  bytes[2] = 0xff;
  bytes[size - 2] = 0xff;
  bytes[size - 1] = 0xd9;
  return bytes;
}

let ctx: TestContext;
let app: Express;
let bearer: readonly ['Authorization', string];

beforeEach(async () => {
  ctx = await buildTestContext();
  app = ctx.app;
  const session = await loginAs(app);
  bearer = ['Authorization', `Bearer ${session.accessToken}`];
});

describe('isJpeg', () => {
  it('accepts a complete JPEG', () => {
    expect(isJpeg(fakeJpeg())).toBe(true);
  });

  it.each([
    ['empty', Buffer.alloc(0)],
    ['too short', Buffer.from([0xff, 0xd8, 0xff, 0xd9])],
    ['PNG', Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0xff, 0xd9])],
    ['SVG text', Buffer.from('<svg xmlns="http://www.w3.org/2000/svg"></svg>')],
    ['truncated JPEG', Buffer.concat([Buffer.from([0xff, 0xd8, 0xff]), Buffer.alloc(20, 1)])],
  ])('rejects %s', (_name, bytes) => {
    expect(isJpeg(bytes)).toBe(false);
  });
});

describe('PUT /users/me/avatar', () => {
  it('stores the picture (204) and the owner can read it back unchanged', async () => {
    const picture = fakeJpeg(1000);
    const put = await request(app)
      .put('/users/me/avatar')
      .set(...bearer)
      .set('Content-Type', 'image/jpeg')
      .send(picture);
    expect(put.status).toBe(204);

    const get = await request(app)
      .get('/users/me/avatar')
      .set(...bearer)
      .buffer(true)
      .parse((res, done) => {
        const chunks: Buffer[] = [];
        res.on('data', (chunk: Buffer) => chunks.push(chunk));
        res.on('end', () => {
          done(null, Buffer.concat(chunks));
        });
      });
    expect(get.status).toBe(200);
    expect(get.headers['content-type']).toBe('image/jpeg');
    expect(Buffer.from(get.body as Buffer).equals(picture)).toBe(true);
  });

  it('serves the picture as a non-sniffable, non-cacheable JPEG', async () => {
    await request(app)
      .put('/users/me/avatar')
      .set(...bearer)
      .send(fakeJpeg())
      .expect(204);
    const get = await request(app)
      .get('/users/me/avatar')
      .set(...bearer);
    expect(get.headers['x-content-type-options']).toBe('nosniff');
    expect(get.headers['cache-control']).toContain('no-store');
    expect(get.headers['cache-control']).toContain('private');
  });

  it('validates the bytes, not the declared Content-Type', async () => {
    const png = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0xff, 0xd9]);
    const lying = await request(app)
      .put('/users/me/avatar')
      .set(...bearer)
      .set('Content-Type', 'image/jpeg')
      .send(png);
    expect(lying.status).toBe(422);
    expect(lying.body).toMatchObject({ code: 'invalid_image' });

    const honest = await request(app)
      .put('/users/me/avatar')
      .set(...bearer)
      .set('Content-Type', 'application/octet-stream')
      .send(fakeJpeg());
    expect(honest.status).toBe(204);
  });

  it('rejects an empty body', async () => {
    const response = await request(app)
      .put('/users/me/avatar')
      .set(...bearer)
      .set('Content-Type', 'image/jpeg');
    expect(response.status).toBe(422);
    expect(response.body).toMatchObject({ code: 'invalid_image' });
  });

  it('accepts exactly the size limit and rejects one byte more with 413', async () => {
    await request(app)
      .put('/users/me/avatar')
      .set(...bearer)
      .send(fakeJpeg(AVATAR_MAX_BYTES))
      .expect(204);

    const tooBig = await request(app)
      .put('/users/me/avatar')
      .set(...bearer)
      .send(fakeJpeg(AVATAR_MAX_BYTES + 1));
    expect(tooBig.status).toBe(413);
    expect(errorBodySchema.parse(tooBig.body).code).toBe('payload_too_large');
  });

  it('requires a session', async () => {
    const response = await request(app).put('/users/me/avatar').send(fakeJpeg());
    expect(response.status).toBe(401);
  });

  it('replaces the previous picture', async () => {
    const first = fakeJpeg(100);
    const second = fakeJpeg(200);
    for (const picture of [first, second]) {
      await request(app)
        .put('/users/me/avatar')
        .set(...bearer)
        .send(picture)
        .expect(204);
    }
    const get = await request(app)
      .get('/users/me/avatar')
      .set(...bearer);
    expect((get.body as Buffer).length).toBe(200);
  });
});

describe('GET /users/me/avatar', () => {
  it('answers 404 avatar_not_found before any upload', async () => {
    const response = await request(app)
      .get('/users/me/avatar')
      .set(...bearer);
    expect(response.status).toBe(404);
    expect(response.body).toMatchObject({ code: 'avatar_not_found' });
  });

  it('requires a session', async () => {
    expect((await request(app).get('/users/me/avatar')).status).toBe(401);
  });

  it('only ever serves the picture of the authenticated user', async () => {
    await request(app)
      .put('/users/me/avatar')
      .set(...bearer)
      .send(fakeJpeg())
      .expect(204);

    const other = await loginAs(app, { email: 'ana@starkshowcase.dev', password: 'Ana12345!' });
    const response = await request(app)
      .get('/users/me/avatar')
      .set('Authorization', `Bearer ${other.accessToken}`);
    expect(response.status).toBe(404);
  });

  it('does not accept a user id in the path (no way to read others)', async () => {
    const response = await request(app)
      .get('/users/user-0/avatar')
      .set(...bearer);
    expect(response.status).toBe(404);
  });
});

describe('hasAvatar in the user payload', () => {
  it('turns true on the next login after an upload', async () => {
    const before = await request(app).post('/auth/login').send(DEMO_CREDENTIALS);
    expect((before.body as { user: { hasAvatar: boolean } }).user.hasAvatar).toBe(false);

    await request(app)
      .put('/users/me/avatar')
      .set(...bearer)
      .send(fakeJpeg())
      .expect(204);

    const after = await request(app).post('/auth/login').send(DEMO_CREDENTIALS);
    expect((after.body as { user: { hasAvatar: boolean } }).user.hasAvatar).toBe(true);
  });

  it('is false for a freshly registered account', async () => {
    const created = await signUp(app, { email: 'pic@example.com', username: 'pic' });
    expect((created.body as { user: { hasAvatar: boolean } }).user.hasAvatar).toBe(false);
  });

  it('is cleared by the reset', async () => {
    await request(app)
      .put('/users/me/avatar')
      .set(...bearer)
      .send(fakeJpeg())
      .expect(204);
    await ctx.container.reset();

    const login = await request(app).post('/auth/login').send(DEMO_CREDENTIALS);
    expect((login.body as { user: { hasAvatar: boolean } }).user.hasAvatar).toBe(false);
  });
});
