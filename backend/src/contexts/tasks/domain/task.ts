export const TASK_PRIORITIES = ['low', 'medium', 'high'] as const;
export type TaskPriority = (typeof TASK_PRIORITIES)[number];

export const TASK_STATUS_FILTERS = ['all', 'pending', 'done'] as const;
export type TaskStatusFilter = (typeof TASK_STATUS_FILTERS)[number];

/** A to-do item. Every task belongs to exactly one user. */
export interface Task {
  readonly id: string;
  readonly ownerId: string;
  readonly title: string;
  readonly description: string;
  readonly priority: TaskPriority;
  readonly isDone: boolean;
  readonly createdAt: Date;
  readonly dueDate: Date | null;
}

/** The editable part of a task (what create and update receive). */
export interface TaskDraft {
  readonly title: string;
  readonly description: string;
  readonly priority: TaskPriority;
  readonly isDone: boolean;
  readonly dueDate: Date | null;
}

/** Search, filter and pagination parameters; already normalized (page >= 1, size 1..100). */
export interface TaskQuery {
  readonly page: number;
  readonly pageSize: number;
  readonly search: string;
  readonly status: TaskStatusFilter;
  readonly priority: TaskPriority | undefined;
}

export interface TaskPage {
  readonly items: readonly Task[];
  /** Number of tasks matching the filters across all pages. */
  readonly total: number;
}

export interface TaskStats {
  readonly total: number;
  readonly done: number;
  /** Open tasks whose deadline has passed. */
  readonly overdue: number;
  readonly highPriorityPending: number;
}
