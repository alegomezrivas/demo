import { pino, type Logger } from 'pino';

export type { Logger } from 'pino';

/** Paths whose values must never reach the logs. */
const REDACTED_PATHS = [
  'password',
  'refreshToken',
  'accessToken',
  '*.password',
  '*.refreshToken',
  '*.accessToken',
  'req.headers.authorization',
  'headers.authorization',
];

/** Creates the application logger with sensitive fields redacted. */
export function createLogger(level: string): Logger {
  return pino({ level, redact: { paths: REDACTED_PATHS, censor: '[redacted]' } });
}
