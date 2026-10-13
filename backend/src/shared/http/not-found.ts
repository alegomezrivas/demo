import type { RequestHandler } from 'express';
import { AppError } from '../errors/app-error.js';

/** Fallback for unknown routes; answers with the uniform error body. */
export const notFoundHandler: RequestHandler = (_req, _res, next) => {
  next(AppError.notFound());
};
