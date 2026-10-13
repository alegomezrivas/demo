import { describe, expect, it } from 'vitest';
import type { Task, TaskQuery } from '../../../../src/contexts/tasks/domain/task.js';
import { InMemoryTaskRepository } from '../../../../src/contexts/tasks/infrastructure/in-memory-task-repository.js';
import { buildSeedTasks } from '../../../../src/seed/tasks.js';

const NOW = new Date('2026-01-01T00:00:00.000Z');
const QUERY: TaskQuery = {
  page: 1,
  pageSize: 100,
  search: '',
  status: 'all',
  priority: undefined,
};

function task(overrides: Partial<Task> = {}): Task {
  return {
    id: 't1',
    ownerId: 'u1',
    title: 'Title',
    description: '',
    priority: 'low',
    isDone: false,
    createdAt: NOW,
    dueDate: null,
    ...overrides,
  };
}

describe('InMemoryTaskRepository', () => {
  it('orders equal timestamps by id so pages are stable', async () => {
    const repo = new InMemoryTaskRepository();
    await repo.add(task({ id: 'a' }));
    await repo.add(task({ id: 'b' }));
    const { items } = await repo.list('u1', QUERY);
    expect(items.map((t) => t.id)).toEqual(['b', 'a']);
  });

  it('only replaces and removes tasks of the right owner', async () => {
    const repo = new InMemoryTaskRepository();
    await repo.add(task());
    expect(await repo.replace(task({ ownerId: 'u2', title: 'x' }))).toBe(false);
    expect(await repo.remove('u2', 't1')).toBe(false);
    expect(await repo.remove('u1', 'missing')).toBe(false);
    expect(await repo.replace(task({ title: 'new' }))).toBe(true);
    expect((await repo.findById('u1', 't1'))?.title).toBe('new');
    expect(await repo.remove('u1', 't1')).toBe(true);
  });

  it('counts overdue only for open tasks with a past deadline', async () => {
    const repo = new InMemoryTaskRepository();
    const past = new Date(NOW.getTime() - 1000);
    await repo.add(task({ id: 'a', dueDate: past }));
    await repo.add(task({ id: 'b', dueDate: past, isDone: true }));
    await repo.add(task({ id: 'c', dueDate: new Date(NOW.getTime() + 1000) }));
    await repo.add(task({ id: 'd', priority: 'high' }));
    expect(await repo.stats('u1', NOW)).toEqual({
      total: 4,
      done: 1,
      overdue: 1,
      highPriorityPending: 1,
    });
  });

  it('load() replaces the whole content', async () => {
    const repo = new InMemoryTaskRepository();
    await repo.add(task());
    repo.load([task({ id: 'other' })]);
    expect(await repo.findById('u1', 't1')).toBeUndefined();
    expect(await repo.findById('u1', 'other')).toBeDefined();
  });
});

describe('buildSeedTasks', () => {
  it('creates 23 tasks for the demo user and 5 for the second account', () => {
    const tasks = buildSeedTasks(NOW);
    expect(tasks.filter((t) => t.ownerId === 'user-0')).toHaveLength(23);
    expect(tasks.filter((t) => t.ownerId === 'user-1')).toHaveLength(5);
    expect(new Set(tasks.map((t) => t.id)).size).toBe(28);
  });

  it('is relative to the given time and deterministic', () => {
    expect(buildSeedTasks(NOW)).toEqual(buildSeedTasks(NOW));
    expect(buildSeedTasks(NOW)[0]?.createdAt.getTime()).toBeLessThan(NOW.getTime());
  });
});
