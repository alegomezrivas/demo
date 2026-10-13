import SwaggerParser from '@apidevtools/swagger-parser';
import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { buildOpenApiDocument } from '../../src/docs/openapi.js';
import { buildTestApp, testConfig } from '../helpers/test-app.js';

type Doc = {
  paths: Record<string, Record<string, { parameters?: unknown[] }>>;
  components: {
    schemas: Record<string, { properties?: Record<string, unknown> }>;
    parameters: object;
  };
};

const build = (env: NodeJS.ProcessEnv = {}): Doc =>
  buildOpenApiDocument(testConfig(env)) as unknown as Doc;

const operations = (doc: Doc): string[] =>
  Object.entries(doc.paths)
    .flatMap(([path, methods]) =>
      Object.keys(methods).map((method) => `${method.toUpperCase()} ${path}`),
    )
    .sort();

describe('OpenAPI document', () => {
  it('is a valid OpenAPI 3 document with every reference resolvable', async () => {
    const api = await SwaggerParser.validate(structuredClone(build()) as never);
    expect('openapi' in api && api.openapi).toBe('3.0.3');
  });

  it('documents exactly the implemented endpoints', () => {
    expect(operations(build())).toEqual(
      [
        'GET /health',
        'POST /auth/login',
        'POST /auth/register',
        'POST /auth/refresh',
        'POST /auth/logout',
        'GET /tasks',
        'POST /tasks',
        'GET /tasks/stats',
        'GET /tasks/{id}',
        'PUT /tasks/{id}',
        'DELETE /tasks/{id}',
        'POST /__reset',
      ].sort(),
    );
  });

  it('is generated from the zod schemas that validate requests', () => {
    const { schemas } = build().components;
    expect(Object.keys(schemas.Task?.properties ?? {})).toEqual([
      'id',
      'title',
      'description',
      'priority',
      'isDone',
      'createdAt',
      'dueDate',
    ]);
    expect(Object.keys(schemas.AuthResponse?.properties ?? {})).toEqual([
      'user',
      'accessToken',
      'refreshToken',
    ]);
    expect(schemas.TaskInput).toMatchObject({ additionalProperties: false });
    expect(schemas.RegisterRequest?.properties).toHaveProperty('password');
  });

  it('derives the list query parameters from the validation schema', () => {
    const parameters = build().paths['/tasks']?.['get']?.parameters as { name: string }[];
    expect(parameters.map((parameter) => parameter.name)).toEqual(
      expect.arrayContaining(['page', 'pageSize', 'q', 'status', 'priority']),
    );
  });

  it('mentions the mock headers only where simulation is enabled', () => {
    expect(Object.keys(build().components.parameters)).toEqual(
      expect.arrayContaining(['MockLatency', 'MockError', 'MockScenario']),
    );
    const production = build({ NODE_ENV: 'production' });
    expect(Object.keys(production.components.parameters)).toEqual([]);
    expect(JSON.stringify(production)).not.toMatch(/X-Mock|x-mock/i);
  });

  it('does not document /__reset in production', async () => {
    const production = build({ NODE_ENV: 'production' });
    expect(operations(production)).not.toContain('POST /__reset');
    await SwaggerParser.validate(structuredClone(production) as never);
  });
});

describe('documentation routes', () => {
  it('serves the document as JSON', async () => {
    const response = await request(await buildTestApp()).get('/openapi.json');
    expect(response.status).toBe(200);
    expect(response.body).toMatchObject({
      openapi: '3.0.3',
      info: { title: 'Stark Showcase API' },
    });
  });

  it('serves Swagger UI with a CSP that lets it run, only on /docs', async () => {
    const app = await buildTestApp();
    const docs = await request(app).get('/docs/');
    expect(docs.status).toBe(200);
    expect(docs.headers['content-type']).toContain('text/html');
    expect(docs.headers['content-security-policy']).toContain("script-src 'self' 'unsafe-inline'");

    const health = await request(app).get('/health');
    expect(health.headers['content-security-policy']).toContain("script-src 'self';");
  });
});
