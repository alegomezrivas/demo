import express from 'express';
import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { errorHandler } from '../src/shared/http/error-handler.js';
import { createLogger } from '../src/shared/logging/logger.js';
import { buildTestApp } from './helpers/test-app.js';

describe('GET /health', () => {
  it('answers ok without exposing internals', async () => {
    const response = await request(await buildTestApp()).get('/health');
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ status: 'ok' });
  });

  it('sets security headers and a request id, and hides the framework', async () => {
    const response = await request(await buildTestApp()).get('/health');
    expect(response.headers['x-powered-by']).toBeUndefined();
    expect(response.headers['x-content-type-options']).toBe('nosniff');
    expect(response.headers['x-request-id']).toMatch(/^[0-9a-f-]{36}$/);
  });
});

describe('unknown routes', () => {
  it('answer 404 with the uniform error body', async () => {
    const response = await request(await buildTestApp()).get('/nope');
    expect(response.status).toBe(404);
    expect(response.body).toEqual({
      code: 'not_found',
      message: 'The resource was not found.',
    });
  });
});

describe('body parsing', () => {
  it('answers 400 invalid_json for malformed JSON', async () => {
    const response = await request(await buildTestApp())
      .post('/health')
      .set('Content-Type', 'application/json')
      .send('{"a":');
    expect(response.status).toBe(400);
    expect(response.body).toMatchObject({ code: 'invalid_json' });
  });

  it('answers 413 payload_too_large above the limit', async () => {
    const response = await request(await buildTestApp({ BODY_LIMIT: '1kb' }))
      .post('/health')
      .send({ filler: 'x'.repeat(2000) });
    expect(response.status).toBe(413);
    expect(response.body).toMatchObject({ code: 'payload_too_large' });
  });
});

describe('CORS', () => {
  it('does not allow any origin by default', async () => {
    const response = await request(await buildTestApp())
      .get('/health')
      .set('Origin', 'https://evil.test');
    expect(response.headers['access-control-allow-origin']).toBeUndefined();
  });

  it('allows only the configured origins', async () => {
    const app = await buildTestApp({ CORS_ALLOWED_ORIGINS: 'https://ok.test' });
    const allowed = await request(app).get('/health').set('Origin', 'https://ok.test');
    const denied = await request(app).get('/health').set('Origin', 'https://evil.test');
    expect(allowed.headers['access-control-allow-origin']).toBe('https://ok.test');
    expect(denied.headers['access-control-allow-origin']).toBeUndefined();
  });
});

describe('error handler', () => {
  function appThrowing(error: unknown): express.Express {
    const app = express();
    app.get('/boom', () => {
      throw error;
    });
    app.use(errorHandler(createLogger('silent')));
    return app;
  }

  it('hides internal details of unexpected errors', async () => {
    const response = await request(appThrowing(new Error('db password is hunter2'))).get('/boom');
    expect(response.status).toBe(500);
    expect(response.body).toEqual({
      code: 'internal_error',
      message: 'An unexpected error occurred.',
    });
    expect(JSON.stringify(response.body)).not.toContain('hunter2');
  });

  it('handles non-Error throwables', async () => {
    const response = await request(appThrowing('plain string')).get('/boom');
    expect(response.status).toBe(500);
    expect(response.body).toMatchObject({ code: 'internal_error' });
  });
});
