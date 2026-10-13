import type { Express } from 'express';
import request from 'supertest';
import { beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  taskPageResponseSchema,
  taskStatsResponseSchema,
} from '../../../../src/contexts/tasks/presentation/http/task-schemas.js';
import { buildTestContext, loginAs, signUp, type TestContext } from '../../../helpers/test-app.js';

let ctx: TestContext;
let app: Express;
let demo: string;
let ana: string;

const bearer = (token: string): [string, string] => ['Authorization', `Bearer ${token}`];

beforeAll(async () => {
  ctx = await buildTestContext();
  app = ctx.app;
});

beforeEach(async () => {
  await ctx.container.reset();
  demo = (await loginAs(app)).accessToken;
  ana = (await loginAs(app, { email: 'ana@starkshowcase.dev', password: 'Ana12345!' })).accessToken;
});

async function totalOf(token: string): Promise<number> {
  const response = await request(app)
    .get('/tasks')
    .set(...bearer(token));
  return taskPageResponseSchema.parse(response.body).total;
}

describe('data isolation between users', () => {
  it('gives every user only their own tasks', async () => {
    expect(await totalOf(demo)).toBe(23);
    expect(await totalOf(ana)).toBe(5);

    const anaIds = taskPageResponseSchema
      .parse(
        (
          await request(app)
            .get('/tasks')
            .set(...bearer(ana))
        ).body,
      )
      .items.map((task) => task.id);
    const demoIds = taskPageResponseSchema
      .parse(
        (
          await request(app)
            .get('/tasks?pageSize=100')
            .set(...bearer(demo))
        ).body,
      )
      .items.map((task) => task.id);
    expect(anaIds.filter((id) => demoIds.includes(id))).toEqual([]);
  });

  it('keeps statistics per user', async () => {
    const stats = async (token: string) =>
      taskStatsResponseSchema.parse(
        (
          await request(app)
            .get('/tasks/stats')
            .set(...bearer(token))
        ).body,
      );
    expect((await stats(demo)).total).toBe(23);
    expect((await stats(ana)).total).toBe(5);
  });

  it('starts new accounts with no tasks and no statistics', async () => {
    const created = await signUp(app, { email: 'nueva@example.com', username: 'nueva' });
    expect(created.status).toBe(201);
    const fresh = (created.body as { accessToken: string }).accessToken;

    expect(await totalOf(fresh)).toBe(0);
    const stats = await request(app)
      .get('/tasks/stats')
      .set(...bearer(fresh));
    expect(stats.body).toEqual({ total: 0, done: 0, overdue: 0, highPriorityPending: 0 });
  });

  it('hides the search results of other users', async () => {
    const response = await request(app)
      .get('/tasks?q=%5BAna%5D')
      .set(...bearer(demo));
    expect(taskPageResponseSchema.parse(response.body).total).toBe(0);
  });

  describe('accessing a task of another user', () => {
    // task-0 belongs to the demo user, task-23 to Ana.
    it('GET answers 404, not 403, so existence is not revealed', async () => {
      const foreign = await request(app)
        .get('/tasks/task-0')
        .set(...bearer(ana));
      const missing = await request(app)
        .get('/tasks/does-not-exist')
        .set(...bearer(ana));
      expect(foreign.status).toBe(404);
      expect(foreign.body).toEqual(missing.body);
    });

    it('PUT answers 404 and leaves the task untouched', async () => {
      const before = await request(app)
        .get('/tasks/task-0')
        .set(...bearer(demo));
      const response = await request(app)
        .put('/tasks/task-0')
        .set(...bearer(ana))
        .send({ title: 'Hacked', description: '', priority: 'low', isDone: true, dueDate: null });
      expect(response.status).toBe(404);
      const after = await request(app)
        .get('/tasks/task-0')
        .set(...bearer(demo));
      expect(after.body).toEqual(before.body);
    });

    it('DELETE answers 404 and the task survives', async () => {
      const response = await request(app)
        .delete('/tasks/task-0')
        .set(...bearer(ana));
      expect(response.status).toBe(404);
      expect(
        (
          await request(app)
            .get('/tasks/task-0')
            .set(...bearer(demo))
        ).status,
      ).toBe(200);
      expect(await totalOf(demo)).toBe(23);
    });

    it('works the other way round too', async () => {
      expect(
        (
          await request(app)
            .get('/tasks/task-23')
            .set(...bearer(demo))
        ).status,
      ).toBe(404);
      expect(
        (
          await request(app)
            .get('/tasks/task-23')
            .set(...bearer(ana))
        ).status,
      ).toBe(200);
    });
  });

  it('keeps created tasks private to their author', async () => {
    const created = await request(app)
      .post('/tasks')
      .set(...bearer(ana))
      .send({ title: 'Solo para Ana', description: '', priority: 'low', isDone: false })
      .expect(201);
    const id = (created.body as { id: string }).id;

    expect(await totalOf(ana)).toBe(6);
    expect(await totalOf(demo)).toBe(23);
    expect(
      (
        await request(app)
          .get(`/tasks/${id}`)
          .set(...bearer(demo))
      ).status,
    ).toBe(404);
  });

  it('uses the owner from the token, never from the request', async () => {
    const response = await request(app)
      .get('/tasks?ownerId=user-0')
      .set(...bearer(ana));
    expect(taskPageResponseSchema.parse(response.body).total).toBe(5);
  });
});
