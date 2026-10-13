import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { buildTestContext } from '../../../helpers/test-app.js';

const production = { NODE_ENV: 'production', TRUST_PROXY: 'true' };

describe('sign-up in production', () => {
  it('accepts the deliberately configured code and nothing else', async () => {
    const { app } = await buildTestContext({ ...production, FIXED_CONFIRMATION_CODE: '135790' });
    const email = 'prod@example.com';
    await request(app).post('/auth/signup/email').send({ email }).expect(204);

    const wrong = await request(app).post('/auth/signup/verify').send({ email, code: '123456' });
    expect(wrong.status).toBe(422);

    const right = await request(app).post('/auth/signup/verify').send({ email, code: '135790' });
    expect(right.status).toBe(200);
  });

  it('does not accept the demo code when none was configured (codes are random)', async () => {
    const { app } = await buildTestContext(production);
    const email = 'prod2@example.com';
    await request(app).post('/auth/signup/email').send({ email }).expect(204);
    // The demo has no e-mail delivery, so nobody can know the random code.
    const guess = await request(app).post('/auth/signup/verify').send({ email, code: '000000' });
    expect(guess.status).toBe(422);
  });

  it('keeps the reset endpoint closed', async () => {
    const { app } = await buildTestContext(production);
    expect((await request(app).post('/__reset')).status).toBe(404);
  });
});

describe('sign-up outside production', () => {
  it('honours a custom code', async () => {
    const { app } = await buildTestContext({ FIXED_CONFIRMATION_CODE: '246810' });
    const email = 'custom@example.com';
    await request(app).post('/auth/signup/email').send({ email }).expect(204);
    expect(
      (await request(app).post('/auth/signup/verify').send({ email, code: '123456' })).status,
    ).toBe(422);
    expect(
      (await request(app).post('/auth/signup/verify').send({ email, code: '246810' })).status,
    ).toBe(200);
  });

  it('applies the simulation headers to the new endpoints', async () => {
    const { app } = await buildTestContext();
    const response = await request(app)
      .post('/auth/signup/email')
      .set('X-Mock-Error', '500')
      .send({ email: 'sim@example.com' });
    expect(response.status).toBe(500);
    expect(response.body).toMatchObject({ code: 'internal_error' });
  });
});
