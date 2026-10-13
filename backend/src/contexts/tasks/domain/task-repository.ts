import type { Task, TaskPage, TaskQuery, TaskStats } from './task.js';

/**
 * Persistence port for tasks. Every operation is scoped to an owner, so a user can
 * never reach another user's data, whatever the id.
 */
export interface TaskRepository {
  list(ownerId: string, query: TaskQuery): Promise<TaskPage>;
  findById(ownerId: string, id: string): Promise<Task | undefined>;
  add(task: Task): Promise<void>;
  /** Replaces the task with the same id and owner; false when there is none. */
  replace(task: Task): Promise<boolean>;
  remove(ownerId: string, id: string): Promise<boolean>;
  stats(ownerId: string, now: Date): Promise<TaskStats>;
}
