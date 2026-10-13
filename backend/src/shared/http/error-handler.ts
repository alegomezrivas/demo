import type { ErrorRequestHandler } from 'express';
import { ZodError } from 'zod';
import { AppError, type ErrorDetail, type ErrorKind } from '../errors/app-error.js';
import type { Logger } from '../logging/logger.js';

const STATUS_BY_KIND: Readonly<Record<ErrorKind, number>> = {
  validation: 422,
  unauthorized: 401,
  forbidden: 403,
  not_found: 404,
  conflict: 409,
};

/** Uniform error body: `code` is what the Flutter app reads; the rest is informative. */
export interface ErrorBody {
  readonly code: string;
  readonly message: string;
  readonly details?: readonly ErrorDetail[];
}

interface HttpFailure {
  readonly status: number;
  readonly body: ErrorBody;
}

/** Maps a Zod error to field-level details without echoing the offending values. */
export function zodDetails(error: ZodError): ErrorDetail[] {
  return error.issues.map((issue) => ({
    field: issue.path.map(String).join('.') || '(root)',
    // Custom refinements carry our own machine-readable key as the message.
    issue: issue.code === 'custom' ? issue.message : issue.code,
  }));
}

function hasProperty<K extends string>(value: unknown, key: K): value is Record<K, unknown> {
  return typeof value === 'object' && value !== null && key in value;
}

function failure(status: number, code: string, message: string): HttpFailure {
  return { status, body: { code, message } };
}

/** Recognizes the errors thrown by Express' body parser. */
function fromBodyParser(error: unknown): HttpFailure | undefined {
  if (!hasProperty(error, 'type') || typeof error.type !== 'string') return undefined;
  switch (error.type) {
    case 'entity.too.large':
      return failure(413, 'payload_too_large', 'The request body is too large.');
    case 'entity.parse.failed':
      return failure(400, 'invalid_json', 'The request body is not valid JSON.');
    case 'charset.unsupported':
    case 'encoding.unsupported':
      return failure(415, 'unsupported_encoding', 'The request encoding is not supported.');
    default:
      return undefined;
  }
}

function toFailure(error: unknown): HttpFailure {
  if (error instanceof AppError) {
    return {
      status: STATUS_BY_KIND[error.kind],
      body: {
        code: error.code,
        message: error.message,
        ...(error.details === undefined ? {} : { details: error.details }),
      },
    };
  }
  if (error instanceof ZodError) {
    return {
      status: 422,
      body: {
        code: 'validation_error',
        message: 'The request is not valid.',
        details: zodDetails(error),
      },
    };
  }
  return fromBodyParser(error) ?? failure(500, 'internal_error', 'An unexpected error occurred.');
}

function errorName(error: unknown): string {
  return error instanceof Error ? error.name : typeof error;
}

/** Last middleware: never leaks stack traces or internal details. */
export function errorHandler(logger: Logger): ErrorRequestHandler {
  return (error: unknown, req, res, next) => {
    if (res.headersSent) {
      next(error);
      return;
    }
    const { status, body } = toFailure(error);
    if (status >= 500) {
      // Only the error name is logged: messages may contain user input.
      logger.error(
        { requestId: res.locals['requestId'] as unknown, path: req.path, name: errorName(error) },
        'unhandled error',
      );
    }
    res.status(status).json(body);
  };
}
