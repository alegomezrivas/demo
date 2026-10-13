import type { Task, TaskPage, TaskQuery, TaskStats } from '../domain/task.js';
import type { TaskRepository } from '../domain/task-repository.js';

export class InMemoryTaskRepository implements TaskRepository {
  private tasks = new Map<string, Task>();

  list(ownerId: string, query: TaskQuery): Promise<TaskPage> {
    const needle = query.search.toLowerCase();
    const matches = this.owned(ownerId)
      .filter((task) => {
        if (
          needle !== '' &&
          !task.title.toLowerCase().includes(needle) &&
          !task.description.toLowerCase().includes(needle)
        ) {
          return false;
        }
        if (query.status === 'done' && !task.isDone) return false;
        if (query.status === 'pending' && task.isDone) return false;
        return query.priority === undefined || task.priority === query.priority;
      })
      // Newest first; the id keeps the order stable for equal timestamps.
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime() || b.id.localeCompare(a.id));
    const start = (query.page - 1) * query.pageSize;
    return Promise.resolve({
      items: matches.slice(start, start + query.pageSize),
      total: matches.length,
    });
  }

  findById(ownerId: string, id: string): Promise<Task | undefined> {
    const task = this.tasks.get(id);
    return Promise.resolve(task?.ownerId === ownerId ? task : undefined);
  }

  add(task: Task): Promise<void> {
    this.tasks.set(task.id, task);
    return Promise.resolve();
  }

  replace(task: Task): Promise<boolean> {
    if (this.tasks.get(task.id)?.ownerId !== task.ownerId) return Promise.resolve(false);
    this.tasks.set(task.id, task);
    return Promise.resolve(true);
  }

  remove(ownerId: string, id: string): Promise<boolean> {
    if (this.tasks.get(id)?.ownerId !== ownerId) return Promise.resolve(false);
    return Promise.resolve(this.tasks.delete(id));
  }

  stats(ownerId: string, now: Date): Promise<TaskStats> {
    const owned = this.owned(ownerId);
    const open = owned.filter((task) => !task.isDone);
    return Promise.resolve({
      total: owned.length,
      done: owned.length - open.length,
      overdue: open.filter((task) => task.dueDate !== null && task.dueDate < now).length,
      highPriorityPending: open.filter((task) => task.priority === 'high').length,
    });
  }

  /** Replaces the whole content (used by the reset endpoint). */
  load(tasks: readonly Task[]): void {
    this.tasks = new Map(tasks.map((task) => [task.id, task]));
  }

  private owned(ownerId: string): Task[] {
    return [...this.tasks.values()].filter((task) => task.ownerId === ownerId);
  }
}
