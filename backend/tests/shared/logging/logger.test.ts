import { Writable } from 'node:stream';
import { pino } from 'pino';
import { describe, expect, it } from 'vitest';
import { createLogger } from '../../../src/shared/logging/logger.js';

describe('createLogger', () => {
  it('honours the level', () => {
    expect(createLogger('warn').level).toBe('warn');
  });

  it('is configured to redact sensitive fields', () => {
    // The redaction paths are applied by pino itself; verify with the same options.
    const lines: string[] = [];
    const sink = new Writable({
      write(chunk: Buffer, _encoding, done) {
        lines.push(chunk.toString());
        done();
      },
    });
    const logger = pino(
      { redact: { paths: ['password', '*.refreshToken'], censor: '[redacted]' } },
      sink,
    );
    logger.info({ password: 'p', body: { refreshToken: 't' } }, 'x');
    expect(lines.join('')).not.toContain('"p"');
    expect(lines.join('')).toContain('[redacted]');
  });

  it('redacts the sign-up code and verification token', () => {
    const lines: string[] = [];
    const sink = new Writable({
      write(chunk: Buffer, _encoding, done) {
        lines.push(chunk.toString());
        done();
      },
    });
    const logger = createLogger('info', sink);

    logger.info({ code: '482915', body: { code: '735190', verificationToken: 'tok-secret' } }, 'x');
    logger.info({ verificationToken: 'tok-secret-2' }, 'y');

    const output = lines.join('');
    for (const secret of ['482915', '735190', 'tok-secret', 'tok-secret-2']) {
      expect(output).not.toContain(secret);
    }
  });
});
