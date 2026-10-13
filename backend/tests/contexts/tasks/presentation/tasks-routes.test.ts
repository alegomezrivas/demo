import type { Express } from 'express';
import request from 'supertest';
import { beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  taskPageResponseSchema,
  taskResponseSchema,
  taskStatsResponseSchema,
} from '../../../../src/contexts/tasks/presentation/http/task-schemas.js';
import { buildTestContext, loginAs, type TestContext } from '../../../helpers/test-app.js';

let ctx: TestContext;
let app: Express;
let token: string;

const auth = (): [string, string] => ['Authorization', `Bearer ${token}`];

beforeAll(async () => {
  ctx = await buildTestContext();
  app = ctx.app;
});

beforeEach(async () => {
  await ctx.container.reset();
  token = (await loginAs(app)).accessToken;
});

async function list(query = ''): Promise<request.Response> {
  return request(app)
    .get(`/tasks${query}`)
    .set(...auth());
}

function page(response: request.Response) {
  return taskPageResponseSchema.parse(response.body);
}

const VALID_INPUT = {
  title: 'Escribir el informe',
  description: 'Con gráficos',
  priority: 'high',
  isDone: false,
  dueDate: '2026-02-01T10:00:00.000Z',
};

describe('authentication', () => {
  it.each([
    ['GET', '/tasks'],
    ['GET', '/tasks/stats'],
    ['GET', '/tasks/task-0'],
    ['POST', '/tasks'],
    ['PUT', '/tasks/task-0'],
    ['DELETE', '/tasks/task-0'],
  ])('%s %s answers 401 without a token, before validating anything', async (method, path) => {
    const response = await request(app)
      [method.toLowerCase() as 'get' | 'post' | 'put' | 'delete'](path)
      .send(method === 'GET' || method === 'DELETE' ? undefined : { invalid: true });
    expect(response.status).toBe(401);
    expect(response.body).toMatchObject({ code: 'unauthorized' });
  });

  it('answers 401 token_expired with an expired token', async () => {
    ctx.clock.advanceSeconds(ctx.config.jwt.accessTtlSeconds + 1);
    const response = await list();
    expect(response.status).toBe(401);
    expect(response.body).toMatchObject({ code: 'token_expired' });
  });
});

describe('GET /tasks', () => {
  it('returns the first page of the 23 seeded tasks, newest first, matching the contract', async () => {
    const response = await list();
    expect(response.status).toBe(200);
    const body = page(response);
    expect(body).toMatchObject({ page: 1, pageSize: 10, total: 23 });
    expect(body.items).toHaveLength(10);
    const dates = body.items.map((task) => Date.parse(task.createdAt));
    expect(dates).toEqual([...dates].sort((a, b) => b - a));
    // Optional fields are present as explicit nulls, never omitted.
    for (const item of (response.body as { items: object[] }).items) {
      expect(item).toHaveProperty('dueDate');
      expect(item).not.toHaveProperty('ownerId');
    }
  });

  it('paginates without overlap and ends with a partial last page', async () => {
    const ids = new Set<string>();
    for (const [pageNumber, expected] of [
      [1, 10],
      [2, 10],
      [3, 3],
    ] as const) {
      const body = page(await list(`?page=${String(pageNumber)}`));
      expect(body.items).toHaveLength(expected);
      body.items.forEach((task) => ids.add(task.id));
    }
    expect(ids.size).toBe(23);
  });

  it('returns an empty page (with the real total) beyond the last one', async () => {
    const body = page(await list('?page=99'));
    expect(body).toMatchObject({ items: [], page: 99, total: 23 });
  });

  it.each([
    ['?pageSize=5', 5],
    ['?pageSize=100', 100],
    ['?pageSize=500', 100],
    ['?pageSize=0', 1],
    ['?pageSize=-3', 1],
  ])('clamps the page size silently: %s -> %i', async (query, expectedSize) => {
    const body = page(await list(query));
    expect(body.pageSize).toBe(expectedSize);
    expect(body.items.length).toBeLessThanOrEqual(expectedSize);
  });

  it.each(['?page=0', '?page=-4'])('clamps the page to 1: %s', async (query) => {
    expect(page(await list(query)).page).toBe(1);
  });

  it.each([
    '?page=abc',
    '?pageSize=ten',
    '?page=1.5',
    '?page=',
    '?page=1&page=2',
    '?page=99999999999',
    '?status=archived',
    '?priority=urgent',
    `?q=${'a'.repeat(101)}`,
  ])('answers 422 for the invalid query %s', async (query) => {
    const response = await list(query);
    expect(response.status).toBe(422);
    expect(response.body).toMatchObject({ code: 'validation_error' });
  });

  it('ignores unknown query parameters', async () => {
    expect((await list('?_=123&foo=bar')).status).toBe(200);
  });

  it('searches title and description case-insensitively', async () => {
    const byTitle = page(await list('?q=PRUEBAS'));
    expect(byTitle.total).toBeGreaterThan(0);
    expect(byTitle.items.every((task) => /pruebas/i.test(task.title))).toBe(true);

    const byDescription = page(await list('?q=detalle de la tarea 1&pageSize=100'));
    expect(byDescription.total).toBeGreaterThan(0);
    expect(byDescription.items.every((task) => /detalle/i.test(task.description))).toBe(true);
  });

  it('returns no results for a search without matches', async () => {
    expect(page(await list('?q=zzzz-no-match'))).toMatchObject({ items: [], total: 0 });
  });

  it('treats search text literally (no regex or wildcard interpretation)', async () => {
    expect(page(await list('?q=.*')).total).toBe(0);
    expect(page(await list('?q=%25')).total).toBe(0);
  });

  it.each([
    ['status=done', 6],
    ['status=pending', 17],
    ['status=all', 23],
    ['priority=low', 8],
    ['priority=medium', 8],
    ['priority=high', 7],
    ['status=pending&priority=high', 5],
    ['status=done&priority=high', 2],
  ])('filters by %s -> %i tasks', async (query, expectedTotal) => {
    expect(page(await list(`?${query}&pageSize=100`)).total).toBe(expectedTotal);
  });

  it('combines search, filters and pagination', async () => {
    const body = page(await list('?q=revisar&status=pending&priority=medium&pageSize=1'));
    expect(body.items.length).toBeLessThanOrEqual(1);
    for (const task of body.items) {
      expect(task).toMatchObject({ isDone: false, priority: 'medium' });
    }
  });
});

describe('GET /tasks/stats', () => {
  it('matches the contract and agrees with the listing', async () => {
    const response = await request(app)
      .get('/tasks/stats')
      .set(...auth());
    expect(response.status).toBe(200);
    const stats = taskStatsResponseSchema.parse(response.body);

    const all = page(await list('?pageSize=100')).items;
    const open = all.filter((task) => !task.isDone);
    const now = ctx.clock.now().getTime();
    expect(stats).toEqual({
      total: 23,
      done: all.length - open.length,
      overdue: open.filter((task) => task.dueDate !== null && Date.parse(task.dueDate) < now)
        .length,
      highPriorityPending: open.filter((task) => task.priority === 'high').length,
    });
    expect(stats).toMatchObject({ done: 6, overdue: 5, highPriorityPending: 5 });
  });

  it('is not shadowed by the :id route', async () => {
    const response = await request(app)
      .get('/tasks/stats')
      .set(...auth());
    expect(response.body).toHaveProperty('highPriorityPending');
  });

  it('reflects changes and the passing of time', async () => {
    await request(app)
      .post('/tasks')
      .set(...auth())
      .send({ ...VALID_INPUT, dueDate: '2025-12-31T00:00:00.000Z' })
      .expect(201);
    const before = taskStatsResponseSchema.parse(
      (
        await request(app)
          .get('/tasks/stats')
          .set(...auth())
      ).body,
    );
    expect(before).toMatchObject({ total: 24, overdue: 6, highPriorityPending: 6 });

    ctx.clock.advanceSeconds(30 * 24 * 3600);
    token = (await loginAs(app)).accessToken;
    const later = taskStatsResponseSchema.parse(
      (
        await request(app)
          .get('/tasks/stats')
          .set(...auth())
      ).body,
    );
    expect(later.overdue).toBeGreaterThan(before.overdue);
  });
});

describe('GET /tasks/:id', () => {
  it('returns the task matching the contract', async () => {
    const response = await request(app)
      .get('/tasks/task-1')
      .set(...auth());
    expect(response.status).toBe(200);
    expect(taskResponseSchema.parse(response.body)).toMatchObject({
      id: 'task-1',
      title: 'Revisar pull requests',
      priority: 'medium',
      isDone: false,
    });
  });

  it('answers 404 not_found for an unknown id', async () => {
    const response = await request(app)
      .get('/tasks/nope')
      .set(...auth());
    expect(response.status).toBe(404);
    expect(response.body).toMatchObject({ code: 'not_found' });
  });

  it('handles odd ids safely', async () => {
    for (const id of ['%2e%2e', encodeURIComponent('../auth'), encodeURIComponent('a b')]) {
      expect(
        (
          await request(app)
            .get(`/tasks/${id}`)
            .set(...auth())
        ).status,
      ).toBe(404);
    }
  });
});

describe('POST /tasks', () => {
  it('creates a task (201) that shows up in the listing', async () => {
    const response = await request(app)
      .post('/tasks')
      .set(...auth())
      .send(VALID_INPUT);
    expect(response.status).toBe(201);
    const created = taskResponseSchema.parse(response.body);
    expect(created).toMatchObject({ ...VALID_INPUT, createdAt: ctx.clock.now().toISOString() });

    const fetched = await request(app)
      .get(`/tasks/${created.id}`)
      .set(...auth());
    expect(fetched.body).toEqual(response.body);
    const first = page(await list()).items[0];
    expect(first?.id).toBe(created.id);
    expect(page(await list()).total).toBe(24);
  });

  it('accepts a null or omitted dueDate and returns it as null', async () => {
    const withNull = await request(app)
      .post('/tasks')
      .set(...auth())
      .send({ ...VALID_INPUT, dueDate: null });
    const withoutDueDate = Object.fromEntries(
      Object.entries(VALID_INPUT).filter(([key]) => key !== 'dueDate'),
    );
    const omitted = await request(app)
      .post('/tasks')
      .set(...auth())
      .send(withoutDueDate);
    expect(withNull.status).toBe(201);
    expect(omitted.status).toBe(201);
    expect(withNull.body).toMatchObject({ dueDate: null });
    expect(omitted.body).toMatchObject({ dueDate: null });
  });

  it('accepts the microsecond timestamps Dart produces and normalizes them', async () => {
    const response = await request(app)
      .post('/tasks')
      .set(...auth())
      .send({ ...VALID_INPUT, dueDate: '2026-03-05T12:34:56.123456Z' });
    expect(response.status).toBe(201);
    expect(response.body).toMatchObject({ dueDate: '2026-03-05T12:34:56.123Z' });
  });

  it('trims the title and allows an empty description', async () => {
    const response = await request(app)
      .post('/tasks')
      .set(...auth())
      .send({ ...VALID_INPUT, title: '  Spaced  ', description: '' });
    expect(response.status).toBe(201);
    expect(response.body).toMatchObject({ title: 'Spaced', description: '' });
  });

  it('accepts the maximum lengths', async () => {
    const response = await request(app)
      .post('/tasks')
      .set(...auth())
      .send({ ...VALID_INPUT, title: 't'.repeat(120), description: 'd'.repeat(1000) });
    expect(response.status).toBe(201);
  });

  it.each([
    ['no body', undefined],
    ['empty object', {}],
    ['missing title', { ...VALID_INPUT, title: undefined }],
    ['blank title', { ...VALID_INPUT, title: '   ' }],
    ['title too long', { ...VALID_INPUT, title: 't'.repeat(121) }],
    ['description too long', { ...VALID_INPUT, description: 'd'.repeat(1001) }],
    ['missing description', { ...VALID_INPUT, description: undefined }],
    ['unknown priority', { ...VALID_INPUT, priority: 'urgent' }],
    ['non-boolean isDone', { ...VALID_INPUT, isDone: 'yes' }],
    ['malformed dueDate', { ...VALID_INPUT, dueDate: 'tomorrow' }],
    ['date-only dueDate', { ...VALID_INPUT, dueDate: '2026-02-01' }],
    ['numeric title', { ...VALID_INPUT, title: 5 }],
    ['unknown field', { ...VALID_INPUT, ownerId: 'user-1' }],
  ])('answers 422 for %s', async (_name, body) => {
    const response = await request(app)
      .post('/tasks')
      .set(...auth())
      .send(body);
    expect(response.status).toBe(422);
    expect(response.body).toMatchObject({ code: 'validation_error' });
    expect(page(await list()).total).toBe(23);
  });

  it('reports the offending fields without echoing values', async () => {
    const response = await request(app)
      .post('/tasks')
      .set(...auth())
      .send({ ...VALID_INPUT, title: '', priority: 'top-secret-value' });
    const details = (response.body as { details: { field: string }[] }).details;
    expect(details.map((detail) => detail.field).sort()).toEqual(['priority', 'title']);
    expect(JSON.stringify(response.body)).not.toContain('top-secret-value');
  });

  it('does not let the client choose id, owner or creation date', async () => {
    const response = await request(app)
      .post('/tasks')
      .set(...auth())
      .send({ ...VALID_INPUT, id: 'task-0' });
    expect(response.status).toBe(422);
  });
});

describe('PUT /tasks/:id', () => {
  it('replaces the editable fields and keeps id and createdAt', async () => {
    const before = taskResponseSchema.parse(
      (
        await request(app)
          .get('/tasks/task-2')
          .set(...auth())
      ).body,
    );
    const response = await request(app)
      .put('/tasks/task-2')
      .set(...auth())
      .send({ ...VALID_INPUT, isDone: true, dueDate: null });
    expect(response.status).toBe(200);
    const updated = taskResponseSchema.parse(response.body);
    expect(updated).toMatchObject({
      id: 'task-2',
      createdAt: before.createdAt,
      title: VALID_INPUT.title,
      isDone: true,
      dueDate: null,
    });
    const fetched = await request(app)
      .get('/tasks/task-2')
      .set(...auth());
    expect(fetched.body).toEqual(response.body);
    expect(page(await list()).total).toBe(23);
  });

  it('answers 404 for an unknown id', async () => {
    const response = await request(app)
      .put('/tasks/nope')
      .set(...auth())
      .send(VALID_INPUT);
    expect(response.status).toBe(404);
    expect(response.body).toMatchObject({ code: 'not_found' });
  });

  it.each([
    ['no body', undefined],
    ['partial body', { title: 'Only a title' }],
    ['invalid priority', { ...VALID_INPUT, priority: 'x' }],
  ])('answers 422 for %s and leaves the task untouched', async (_name, body) => {
    const before = await request(app)
      .get('/tasks/task-3')
      .set(...auth());
    const response = await request(app)
      .put('/tasks/task-3')
      .set(...auth())
      .send(body);
    expect(response.status).toBe(422);
    const after = await request(app)
      .get('/tasks/task-3')
      .set(...auth());
    expect(after.body).toEqual(before.body);
  });
});

describe('DELETE /tasks/:id', () => {
  it('answers 204 with no body and removes the task', async () => {
    const response = await request(app)
      .delete('/tasks/task-4')
      .set(...auth());
    expect(response.status).toBe(204);
    expect(response.text).toBe('');
    expect(
      (
        await request(app)
          .get('/tasks/task-4')
          .set(...auth())
      ).status,
    ).toBe(404);
    expect(page(await list()).total).toBe(22);
  });

  it('answers 404 the second time', async () => {
    await request(app)
      .delete('/tasks/task-5')
      .set(...auth())
      .expect(204);
    const again = await request(app)
      .delete('/tasks/task-5')
      .set(...auth());
    expect(again.status).toBe(404);
    expect(again.body).toMatchObject({ code: 'not_found' });
  });

  it('answers 404 for an unknown id', async () => {
    expect(
      (
        await request(app)
          .delete('/tasks/nope')
          .set(...auth())
      ).status,
    ).toBe(404);
  });
});
