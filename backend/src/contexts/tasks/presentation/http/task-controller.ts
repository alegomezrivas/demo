import type { RequestHandler } from 'express';
import { requireAuth } from '../../../auth/presentation/http/authenticate.js';
import type {
  CreateTask,
  DeleteTask,
  GetTask,
  GetTaskStats,
  ListTasks,
  UpdateTask,
} from '../../application/task-use-cases.js';
import type { Task } from '../../domain/task.js';
import { listQuerySchema, taskIdSchema, taskInputSchema } from './task-schemas.js';

export interface TaskUseCases {
  readonly list: ListTasks;
  readonly get: GetTask;
  readonly create: CreateTask;
  readonly update: UpdateTask;
  readonly remove: DeleteTask;
  readonly stats: GetTaskStats;
}

/** Wire shape of a task; the owner never leaves the server. */
function toTaskResponse(task: Task): object {
  return {
    id: task.id,
    title: task.title,
    description: task.description,
    priority: task.priority,
    isDone: task.isDone,
    createdAt: task.createdAt.toISOString(),
    dueDate: task.dueDate === null ? null : task.dueDate.toISOString(),
  };
}

/** Thin HTTP adapter; routes are mounted behind the `authenticate` middleware. */
export class TaskController {
  constructor(private readonly useCases: TaskUseCases) {}

  readonly list: RequestHandler = async (req, res) => {
    const query = listQuerySchema.parse(req.query);
    const { items, total } = await this.useCases.list.execute(requireAuth(req).userId, query);
    res.json({
      items: items.map(toTaskResponse),
      page: query.page,
      pageSize: query.pageSize,
      total,
    });
  };

  readonly stats: RequestHandler = async (req, res) => {
    res.json(await this.useCases.stats.execute(requireAuth(req).userId));
  };

  readonly get: RequestHandler = async (req, res) => {
    const id = taskIdSchema.parse(req.params['id']);
    res.json(toTaskResponse(await this.useCases.get.execute(requireAuth(req).userId, id)));
  };

  readonly create: RequestHandler = async (req, res) => {
    const draft = taskInputSchema.parse(req.body);
    const task = await this.useCases.create.execute(requireAuth(req).userId, draft);
    res.status(201).json(toTaskResponse(task));
  };

  readonly update: RequestHandler = async (req, res) => {
    const id = taskIdSchema.parse(req.params['id']);
    const draft = taskInputSchema.parse(req.body);
    res.json(
      toTaskResponse(await this.useCases.update.execute(requireAuth(req).userId, id, draft)),
    );
  };

  readonly remove: RequestHandler = async (req, res) => {
    const id = taskIdSchema.parse(req.params['id']);
    await this.useCases.remove.execute(requireAuth(req).userId, id);
    res.status(204).end();
  };
}
