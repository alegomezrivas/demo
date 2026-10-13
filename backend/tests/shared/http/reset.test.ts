import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { buildTestContext, DEMO_CREDENTIALS, loginAs } from '../../helpers/test-app.js';

describe('POST /__reset', () => {
  it('restores seed users and tasks after changes', async () => {
    const { app } = await buildTestContext();
    const { accessToken } = await loginAs(app);
    const bearer = ['Authorization', `Bearer ${accessToken}`] as const;

    await request(app)
      .delete('/tasks/task-0')
      .set(...bearer)
      .expect(204);
    await request(app)
      .post('/tasks')
      .set(...bearer)
      .send({ title: 'Extra', description: '', priority: 'low', isDone: false })
      .expect(201);
    await request(app)
      .post('/auth/register')
      .send({ name: 'Temp', email: 'temp@example.com', password: 'Str0ng!Pass' })
      .expect(201);

    const reset = await request(app).post('/__reset');
    expect(reset.status).toBe(204);
    expect(reset.text).toBe('');

    // A fresh login works and sees the original 23 tasks; the new account is gone.
    const again = await loginAs(app, DEMO_CREDENTIALS);
    const tasks = await request(app)
      .get('/tasks?pageSize=100')
      .set('Authorization', `Bearer ${again.accessToken}`);
    expect(tasks.body).toMatchObject({ total: 23 });
    expect((tasks.body as { items: { id: string }[] }).items.map((t) => t.id)).toContain('task-0');
    await request(app)
      .post('/auth/login')
      .send({ email: 'temp@example.com', password: 'Str0ng!Pass' })
      .expect(401);
  });

  it('does not exist in production', async () => {
    const { app } = await buildTestContext({ NODE_ENV: 'production' });
    const response = await request(app).post('/__reset');
    expect(response.status).toBe(404);
    expect(response.body).toMatchObject({ code: 'not_found' });
  });
});
