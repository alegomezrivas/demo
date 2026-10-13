/** Transport-agnostic category of an application error. */
export type ErrorKind =
  'validation' | 'unauthorized' | 'forbidden' | 'not_found' | 'conflict' | 'rate_limited';

/** Field-level problem reported with validation errors; never echoes input values. */
export interface ErrorDetail {
  readonly field: string;
  readonly issue: string;
}

/**
 * Error raised by the domain and application layers.
 *
 * It carries a machine-readable [code] (the only field the Flutter app reads) and a
 * generic [message]. The HTTP status is decided in the presentation layer from [kind].
 */
export class AppError extends Error {
  constructor(
    readonly kind: ErrorKind,
    readonly code: string,
    message: string,
    readonly details?: readonly ErrorDetail[],
  ) {
    super(message);
    this.name = 'AppError';
  }

  static validation(details: readonly ErrorDetail[], code = 'validation_error'): AppError {
    return new AppError('validation', code, 'The request is not valid.', details);
  }

  static unauthorized(code = 'unauthorized'): AppError {
    return new AppError('unauthorized', code, 'Authentication is required or has failed.');
  }

  static forbidden(code = 'forbidden'): AppError {
    return new AppError('forbidden', code, 'You are not allowed to perform this action.');
  }

  static notFound(code = 'not_found'): AppError {
    return new AppError('not_found', code, 'The resource was not found.');
  }

  static rateLimited(code = 'rate_limited'): AppError {
    return new AppError('rate_limited', code, 'Too many requests, please try again later.');
  }

  static conflict(code: string): AppError {
    return new AppError('conflict', code, 'The request conflicts with the current state.');
  }
}
