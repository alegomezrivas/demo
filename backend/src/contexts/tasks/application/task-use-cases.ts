import { randomUUID } from 'node:crypto';
import type { Clock } from '../../../shared/clock.js';
import { AppError } from '../../../shared/errors/app-error.js';
import type { Task, TaskDraft, TaskPage, TaskQuery, TaskStats } from '../domain/task.js';
import type { TaskRepository } from '../domain/task-repository.js';

export class ListTasks {
  constructor(private readonly tasks: TaskRepository) {}

  execute(ownerId: string, query: TaskQuery): Promise<TaskPage> {
    return this.tasks.list(ownerId, query);
  }
}

export class GetTask {
  constructor(private readonly tasks: TaskRepository) {}

  async execute(ownerId: string, id: string): Promise<Task> {
    // Someone else's task is reported exactly like a missing one.
    const task = await this.tasks.findById(ownerId, id);
    if (task === undefined) throw AppError.notFound();
    return task;
  }
}

export class CreateTask {
  constructor(
    private readonly tasks: TaskRepository,
    private readonly clock: Clock,
  ) {}

  async execute(ownerId: string, draft: TaskDraft): Promise<Task> {
    const task: Task = { ...draft, id: randomUUID(), ownerId, createdAt: this.clock.now() };
    await this.tasks.add(task);
    return task;
  }
}

export class UpdateTask {
  constructor(private readonly tasks: TaskRepository) {}

  /** Full replacement; `id` and `createdAt` never change. */
  async execute(ownerId: string, id: string, draft: TaskDraft): Promise<Task> {
    const current = await this.tasks.findById(ownerId, id);
    if (current === undefined) throw AppError.notFound();
    const updated: Task = { ...draft, id: current.id, ownerId, createdAt: current.createdAt };
    if (!(await this.tasks.replace(updated))) throw AppError.notFound();
    return updated;
  }
}

export class DeleteTask {
  constructor(private readonly tasks: TaskRepository) {}

  async execute(ownerId: string, id: string): Promise<void> {
    if (!(await this.tasks.remove(ownerId, id))) throw AppError.notFound();
  }
}

export class GetTaskStats {
  constructor(
    private readonly tasks: TaskRepository,
    private readonly clock: Clock,
  ) {}

  execute(ownerId: string): Promise<TaskStats> {
    return this.tasks.stats(ownerId, this.clock.now());
  }
}
