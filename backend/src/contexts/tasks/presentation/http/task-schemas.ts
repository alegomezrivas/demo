import { z } from 'zod';
import {
  TASK_PRIORITIES,
  TASK_STATUS_FILTERS,
  type TaskDraft,
  type TaskQuery,
} from '../../domain/task.js';

export const DEFAULT_PAGE_SIZE = 10;
export const MAX_PAGE_SIZE = 100;
export const MAX_TITLE_LENGTH = 120;
export const MAX_DESCRIPTION_LENGTH = 1000;
export const MAX_SEARCH_LENGTH = 100;

/** Digits only: a non-numeric value is a 422, an out-of-range one is silently clamped. */
const integerParam = z
  .string()
  .regex(/^-?\d{1,9}$/)
  .transform(Number);

// ---- Requests ----

/** Query string of `GET /tasks`. Unknown parameters are ignored. */
export const listQuerySchema = z
  .object({
    page: integerParam.optional(),
    pageSize: integerParam.optional(),
    q: z.string().trim().max(MAX_SEARCH_LENGTH).optional(),
    status: z.enum(TASK_STATUS_FILTERS).optional(),
    priority: z.enum(TASK_PRIORITIES).optional(),
  })
  .transform((query): TaskQuery => ({
    page: Math.max(1, query.page ?? 1),
    pageSize: Math.min(MAX_PAGE_SIZE, Math.max(1, query.pageSize ?? DEFAULT_PAGE_SIZE)),
    search: query.q ?? '',
    status: query.status ?? 'all',
    priority: query.priority,
  }));

/** Body of create and update (a full replacement). */
export const taskInputSchema = z
  .strictObject({
    title: z.string().trim().min(1).max(MAX_TITLE_LENGTH),
    description: z.string().max(MAX_DESCRIPTION_LENGTH),
    priority: z.enum(TASK_PRIORITIES),
    isDone: z.boolean(),
    // Any ISO 8601 instant; the Flutter app sends UTC with up to microseconds.
    dueDate: z.iso.datetime({ offset: true }).nullish(),
  })
  .transform((input): TaskDraft => ({
    ...input,
    dueDate: input.dueDate == null ? null : new Date(input.dueDate),
  }));

export const taskIdSchema = z.string().min(1).max(100);

// ---- Responses (shared with the contract tests and the OpenAPI document) ----

export const taskResponseSchema = z.strictObject({
  id: z.string(),
  title: z.string(),
  description: z.string(),
  priority: z.enum(TASK_PRIORITIES),
  isDone: z.boolean(),
  createdAt: z.iso.datetime(),
  dueDate: z.iso.datetime().nullable(),
});

export const taskPageResponseSchema = z.strictObject({
  items: z.array(taskResponseSchema),
  page: z.number().int().min(1),
  pageSize: z.number().int().min(1).max(MAX_PAGE_SIZE),
  total: z.number().int().min(0),
});

export const taskStatsResponseSchema = z.strictObject({
  total: z.number().int().min(0),
  done: z.number().int().min(0),
  overdue: z.number().int().min(0),
  highPriorityPending: z.number().int().min(0),
});
