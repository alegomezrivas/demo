import { describe, expect, it } from 'vitest';
import { AppError } from '../../../src/shared/errors/app-error.js';

describe('AppError', () => {
  it.each([
    [AppError.validation([{ field: 'a', issue: 'required' }]), 'validation', 'validation_error'],
    [AppError.unauthorized(), 'unauthorized', 'unauthorized'],
    [AppError.forbidden(), 'forbidden', 'forbidden'],
    [AppError.notFound(), 'not_found', 'not_found'],
    [AppError.conflict('email_taken'), 'conflict', 'email_taken'],
  ])('builds %#', (error, kind, code) => {
    expect(error).toBeInstanceOf(Error);
    expect(error.kind).toBe(kind);
    expect(error.code).toBe(code);
    expect(error.message.length).toBeGreaterThan(0);
  });

  it('keeps custom codes', () => {
    expect(AppError.unauthorized('invalid_credentials').code).toBe('invalid_credentials');
  });
});
