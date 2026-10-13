import express from 'express';
import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { z } from 'zod';
import { AppError } from '../../../src/shared/errors/app-error.js';
import { errorHandler } from '../../../src/shared/http/error-handler.js';
import { createLogger } from '../../../src/shared/logging/logger.js';

function appThrowing(error: unknown): express.Express {
  const app = express();
  app.get('/boom', () => {
    throw error;
  });
  app.use(errorHandler(createLogger('silent')));
  return app;
}

describe('errorHandler', () => {
  it.each([
    [AppError.unauthorized('invalid_credentials'), 401, 'invalid_credentials'],
    [AppError.forbidden(), 403, 'forbidden'],
    [AppError.notFound(), 404, 'not_found'],
    [AppError.conflict('email_taken'), 409, 'email_taken'],
    [AppError.validation([{ field: 'title', issue: 'required' }]), 422, 'validation_error'],
  ])('maps AppError %#', async (error, status, code) => {
    const response = await request(appThrowing(error)).get('/boom');
    expect(response.status).toBe(status);
    expect(response.body).toMatchObject({ code });
  });

  it('includes details only when present', async () => {
    const withDetails = await request(
      appThrowing(AppError.validation([{ field: 'title', issue: 'required' }])),
    ).get('/boom');
    const without = await request(appThrowing(AppError.notFound())).get('/boom');
    expect(withDetails.body).toMatchObject({ details: [{ field: 'title', issue: 'required' }] });
    expect(without.body).not.toHaveProperty('details');
  });

  it('maps ZodError to 422 with field details and no echoed values', async () => {
    const parsed = z.object({ title: z.string().min(20) }).safeParse({ title: 'secret-ish' });
    if (parsed.success) throw new Error('expected failure');
    const response = await request(appThrowing(parsed.error)).get('/boom');
    expect(response.status).toBe(422);
    expect(response.body).toMatchObject({ details: [{ field: 'title', issue: 'too_small' }] });
    expect(JSON.stringify(response.body)).not.toContain('secret-ish');
  });
});
